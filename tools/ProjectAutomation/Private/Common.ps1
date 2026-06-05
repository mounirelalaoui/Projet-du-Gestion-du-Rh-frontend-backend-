function Get-ProjectAutomationConfig {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleRoot
    )

    $configPath = Join-Path -Path $ModuleRoot -ChildPath 'Config\ProjectAutomation.Config.psd1'
    Import-PowerShellDataFile -Path $configPath
}

function Resolve-AbsolutePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $resolved = Resolve-Path -LiteralPath $Path -ErrorAction Stop
    $resolved.Path
}

function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,
        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    $baseUri = New-Object System.Uri(((Resolve-AbsolutePath -Path $BasePath).TrimEnd('\') + '\'))
    $targetUri = New-Object System.Uri((Resolve-AbsolutePath -Path $TargetPath))
    $relativeUri = $baseUri.MakeRelativeUri($targetUri)
    [System.Uri]::UnescapeDataString($relativeUri.ToString()).Replace('/', '\')
}

function Test-StartsWithPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    $normalizedPath = [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
    $normalizedRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')

    if ($normalizedPath.Equals($normalizedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    $normalizedPath.StartsWith($normalizedRoot + '\', [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-PathInRoots {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string[]]$Roots = @()
    )

    foreach ($root in $Roots) {
        if ([string]::IsNullOrWhiteSpace($root)) {
            continue
        }

        if (Test-StartsWithPath -Path $Path -Root $root) {
            return $true
        }
    }

    $false
}

function Test-DirectoryNameInSet {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string[]]$Set = @()
    )

    foreach ($item in $Set) {
        if ($Name.Equals($item, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }

    $false
}

function Test-ShouldSkipDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.DirectoryInfo]$Directory,
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,
        [string[]]$AdditionalSkipRoots = @(),
        [switch]$IncludeWorkspaceClutter
    )

    if (Test-PathInRoots -Path $Directory.FullName -Roots $AdditionalSkipRoots) {
        return $true
    }

    if (Test-DirectoryNameInSet -Name $Directory.Name -Set $Config.GeneratedDirectories) {
        return $true
    }

    if (-not $IncludeWorkspaceClutter -and (Test-DirectoryNameInSet -Name $Directory.Name -Set $Config.WorkspaceClutterDirectories)) {
        return $true
    }

    $false
}

function Test-ShouldSkipFile {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File,
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )

    if (Test-DirectoryNameInSet -Name $File.Name -Set $Config.GeneratedFileNames) {
        return $true
    }

    foreach ($pattern in $Config.ExcludedFilePatterns) {
        if ($File.Name -like $pattern) {
            return $true
        }
    }

    $false
}

function Get-ProjectTreeItems {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,
        [ValidateSet('File', 'Directory', 'All')]
        [string]$ItemType = 'File',
        [string[]]$AdditionalSkipRoots = @(),
        [switch]$IncludeWorkspaceClutter
    )

    $root = Resolve-AbsolutePath -Path $Path
    $stack = New-Object 'System.Collections.Generic.Stack[string]'
    $stack.Push($root)
    $results = New-Object 'System.Collections.Generic.List[object]'

    while ($stack.Count -gt 0) {
        $current = $stack.Pop()
        $children = Get-ChildItem -LiteralPath $current -Force -ErrorAction SilentlyContinue

        foreach ($child in $children) {
            if ($child.PSIsContainer) {
                if (Test-ShouldSkipDirectory -Directory $child -Config $Config -AdditionalSkipRoots $AdditionalSkipRoots -IncludeWorkspaceClutter:$IncludeWorkspaceClutter) {
                    continue
                }

                if ($ItemType -in @('Directory', 'All')) {
                    $results.Add($child)
                }

                $stack.Push($child.FullName)
                continue
            }

            if (Test-ShouldSkipFile -File $child -Config $Config) {
                continue
            }

            if ($ItemType -in @('File', 'All')) {
                $results.Add($child)
            }
        }
    }

    $results
}

function New-IssueRecord {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Severity,
        [Parameter(Mandatory = $true)]
        [string]$Code,
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [string]$Path = '',
        [string]$Project = ''
    )

    [pscustomobject]@{
        Severity = $Severity
        Code = $Code
        Message = $Message
        Path = $Path
        Project = $Project
    }
}

function Get-HumanSize {
    param(
        [Parameter(Mandatory = $true)]
        [double]$Bytes
    )

    if ($Bytes -lt 1KB) { return ('{0:N0} B' -f $Bytes) }
    if ($Bytes -lt 1MB) { return ('{0:N2} KB' -f ($Bytes / 1KB)) }
    if ($Bytes -lt 1GB) { return ('{0:N2} MB' -f ($Bytes / 1MB)) }
    ('{0:N2} GB' -f ($Bytes / 1GB))
}

function Get-DirectoryTreeLines {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [int]$MaxDepth = 3,
        [string[]]$ExcludeRelativePatterns = @()
    )

    $root = Resolve-AbsolutePath -Path $Path
    $lines = New-Object 'System.Collections.Generic.List[string]'

    function Add-TreeLevel {
        param(
            [string]$CurrentPath,
            [int]$Depth,
            [string]$Prefix
        )

        if ($Depth -gt $MaxDepth) {
            return
        }

        $items = Get-ChildItem -LiteralPath $CurrentPath -Force -ErrorAction SilentlyContinue |
            Sort-Object @{ Expression = { $_.PSIsContainer }; Descending = $true }, Name

        foreach ($item in $items) {
            $relative = Get-RelativePath -BasePath $root -TargetPath $item.FullName
            $skip = $false

            foreach ($pattern in $ExcludeRelativePatterns) {
                if ($relative -match $pattern) {
                    $skip = $true
                    break
                }
            }

            if ($skip) {
                continue
            }

            $suffix = if ($item.PSIsContainer) { '/' } else { '' }
            $lines.Add($Prefix + $item.Name + $suffix)

            if ($item.PSIsContainer) {
                Add-TreeLevel -CurrentPath $item.FullName -Depth ($Depth + 1) -Prefix ($Prefix + '  ')
            }
        }
    }

    Add-TreeLevel -CurrentPath $root -Depth 0 -Prefix ''
    $lines
}

function ConvertTo-SerializableObject {
    param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [string] -or $InputObject -is [ValueType]) {
        return $InputObject
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $dictionary = [ordered]@{}
        foreach ($key in $InputObject.Keys) {
            $dictionary[[string]$key] = ConvertTo-SerializableObject -InputObject $InputObject[$key]
        }
        return [pscustomobject]$dictionary
    }

    if (($InputObject -is [System.Collections.IEnumerable]) -and -not ($InputObject -is [string])) {
        $items = New-Object 'System.Collections.Generic.List[object]'
        foreach ($item in $InputObject) {
            $items.Add((ConvertTo-SerializableObject -InputObject $item))
        }
        return $items.ToArray()
    }

    $properties = [ordered]@{}
    foreach ($property in $InputObject.PSObject.Properties) {
        $properties[$property.Name] = ConvertTo-SerializableObject -InputObject $property.Value
    }

    [pscustomobject]$properties
}
