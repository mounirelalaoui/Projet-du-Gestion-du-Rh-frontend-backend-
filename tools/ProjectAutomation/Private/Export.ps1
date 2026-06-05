function Copy-FilteredFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceFile,
        [Parameter(Mandatory = $true)]
        [string]$DestinationFile
    )

    $destinationDirectory = Split-Path -Parent $DestinationFile
    if (-not (Test-Path -LiteralPath $destinationDirectory)) {
        [void](New-Item -ItemType Directory -Path $destinationDirectory -Force)
    }

    Copy-Item -LiteralPath $SourceFile -Destination $DestinationFile -Force
}

function Copy-FilteredDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceDirectory,
        [Parameter(Mandatory = $true)]
        [string]$DestinationDirectory,
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )

    if (-not (Test-Path -LiteralPath $SourceDirectory)) {
        return
    }

    if (-not (Test-Path -LiteralPath $DestinationDirectory)) {
        [void](New-Item -ItemType Directory -Path $DestinationDirectory -Force)
    }

    $stack = New-Object 'System.Collections.Generic.Stack[object]'
    $stack.Push([pscustomobject]@{
        Source      = $SourceDirectory
        Destination = $DestinationDirectory
    })

    while ($stack.Count -gt 0) {
        $current = $stack.Pop()
        $children = Get-ChildItem -LiteralPath $current.Source -Force -ErrorAction SilentlyContinue

        foreach ($child in $children) {
            if ($child.PSIsContainer) {
                if ((Test-DirectoryNameInSet -Name $child.Name -Set $Config.GeneratedDirectories) -or (Test-DirectoryNameInSet -Name $child.Name -Set $Config.WorkspaceClutterDirectories)) {
                    continue
                }

                $destinationPath = Join-Path -Path $current.Destination -ChildPath $child.Name
                if (-not (Test-Path -LiteralPath $destinationPath)) {
                    [void](New-Item -ItemType Directory -Path $destinationPath -Force)
                }

                $stack.Push([pscustomobject]@{
                    Source      = $child.FullName
                    Destination = $destinationPath
                })
                continue
            }

            if (Test-ShouldSkipFile -File $child -Config $Config) {
                continue
            }

            $destinationFile = Join-Path -Path $current.Destination -ChildPath $child.Name
            Copy-Item -LiteralPath $child.FullName -Destination $destinationFile -Force
        }
    }
}

function Convert-EnvironmentFileToExample {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceEnvPath,
        [Parameter(Mandatory = $true)]
        [string]$DestinationEnvExamplePath,
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )

    $lines = Get-Content -LiteralPath $SourceEnvPath -ErrorAction SilentlyContinue
    $sanitized = New-Object 'System.Collections.Generic.List[string]'

    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#')) {
            $sanitized.Add($line)
            continue
        }

        if ($line -notmatch '=') {
            $sanitized.Add($line)
            continue
        }

        $key, $value = $line -split '=', 2
        $trimmedKey = $key.Trim()
        $shouldBlank = $false

        foreach ($pattern in $Config.SensitiveEnvironmentKeyPatterns) {
            if ($trimmedKey -like ('*' + $pattern + '*')) {
                $shouldBlank = $true
                break
            }
        }

        if ($shouldBlank) {
            $sanitized.Add($trimmedKey + '=')
        }
        else {
            $sanitized.Add($trimmedKey + '=' + $value)
        }
    }

    $destinationDirectory = Split-Path -Parent $DestinationEnvExamplePath
    if (-not (Test-Path -LiteralPath $destinationDirectory)) {
        [void](New-Item -ItemType Directory -Path $destinationDirectory -Force)
    }

    Set-Content -LiteralPath $DestinationEnvExamplePath -Value $sanitized -Encoding UTF8
}

function Ensure-LaravelSkeleton {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExportRoot
    )

    $directories = @(
        'bootstrap\cache',
        'storage\app',
        'storage\app\private',
        'storage\app\public',
        'storage\framework',
        'storage\framework\cache',
        'storage\framework\cache\data',
        'storage\framework\sessions',
        'storage\framework\testing',
        'storage\framework\views',
        'storage\logs'
    )

    foreach ($directory in $directories) {
        $fullPath = Join-Path -Path $ExportRoot -ChildPath $directory
        if (-not (Test-Path -LiteralPath $fullPath)) {
            [void](New-Item -ItemType Directory -Path $fullPath -Force)
        }
    }

    $gitIgnores = @{
        'bootstrap\cache\.gitignore'              = "*`n!.gitignore"
        'storage\app\.gitignore'                  = "*`n!.gitignore"
        'storage\app\private\.gitignore'          = "*`n!.gitignore"
        'storage\app\public\.gitignore'           = "*`n!.gitignore"
        'storage\framework\.gitignore'            = "*`n!.gitignore"
        'storage\framework\cache\.gitignore'      = "*`n!.gitignore"
        'storage\framework\cache\data\.gitignore' = "*`n!.gitignore"
        'storage\framework\sessions\.gitignore'   = "*`n!.gitignore"
        'storage\framework\testing\.gitignore'    = "*`n!.gitignore"
        'storage\framework\views\.gitignore'      = "*`n!.gitignore"
        'storage\logs\.gitignore'                 = "*`n!.gitignore"
    }

    foreach ($entry in $gitIgnores.GetEnumerator()) {
        $target = Join-Path -Path $ExportRoot -ChildPath $entry.Key
        if (-not (Test-Path -LiteralPath $target)) {
            Set-Content -LiteralPath $target -Value $entry.Value -Encoding UTF8
        }
    }
}

function New-ZipFromDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceDirectory,
        [Parameter(Mandatory = $true)]
        [string]$ZipPath
    )

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    if (Test-Path -LiteralPath $ZipPath) {
        Remove-Item -LiteralPath $ZipPath -Force
    }

    $root = Resolve-AbsolutePath -Path $SourceDirectory
    $files = Get-ChildItem -LiteralPath $root -Recurse -Force -File -ErrorAction SilentlyContinue
    $fileStream = [System.IO.File]::Open($ZipPath, [System.IO.FileMode]::CreateNew)

    try {
        $archive = New-Object System.IO.Compression.ZipArchive($fileStream, [System.IO.Compression.ZipArchiveMode]::Create, $false)
        try {
            foreach ($file in $files) {
                $relative = Get-RelativePath -BasePath (Split-Path -Parent $root) -TargetPath $file.FullName
                $entryName = $relative.Replace('\', '/')
                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $entryName, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
            }
        }
        finally {
            $archive.Dispose()
        }
    }
    finally {
        $fileStream.Dispose()
    }
}

function Export-CleanProjectWorkspace {
    param(
        [Parameter(Mandatory = $true)]
        $Analysis,
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        [string]$ZipName = 'cleaned_project_source.zip',
        [switch]$SkipZip
    )

    $resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
    if (-not (Test-Path -LiteralPath $resolvedOutput)) {
        [void](New-Item -ItemType Directory -Path $resolvedOutput -Force)
    }

    $exportRoot = Join-Path -Path $resolvedOutput -ChildPath 'cleaned_project_source'
    if (Test-Path -LiteralPath $exportRoot) {
        try {
            Remove-Item -LiteralPath $exportRoot -Recurse -Force -ErrorAction Stop
        }
        catch {
            $exportRoot = Join-Path -Path $resolvedOutput -ChildPath ('cleaned_project_source_' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
        }
    }
    [void](New-Item -ItemType Directory -Path $exportRoot -Force)

    $copiedDestinations = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($project in $Analysis.Projects) {
        $relativeRoot = if ($project.RelativeRoot -eq '.') { '' } else { $project.RelativeRoot }
        $exportProjectRoot = if ([string]::IsNullOrWhiteSpace($relativeRoot)) {
            $exportRoot
        }
        else {
            Join-Path -Path $exportRoot -ChildPath $relativeRoot
        }

        if (-not (Test-Path -LiteralPath $exportProjectRoot)) {
            [void](New-Item -ItemType Directory -Path $exportProjectRoot -Force)
        }

        foreach ($file in $project.KeepFiles | Sort-Object -Unique) {
            $sourceFile = Join-Path -Path $project.RootPath -ChildPath $file
            if (-not (Test-Path -LiteralPath $sourceFile)) {
                continue
            }

            $destinationFile = Join-Path -Path $exportProjectRoot -ChildPath $file
            if ($copiedDestinations.Add($destinationFile)) {
                Copy-FilteredFile -SourceFile $sourceFile -DestinationFile $destinationFile
            }
        }

        foreach ($directory in $project.KeepDirectories | Sort-Object -Unique) {
            $sourceDirectory = Join-Path -Path $project.RootPath -ChildPath $directory
            $destinationDirectory = Join-Path -Path $exportProjectRoot -ChildPath $directory
            Copy-FilteredDirectory -SourceDirectory $sourceDirectory -DestinationDirectory $destinationDirectory -Config $Config
        }

        $sourceEnv = Join-Path -Path $project.RootPath -ChildPath '.env'
        $exportEnvExample = Join-Path -Path $exportProjectRoot -ChildPath '.env.example'
        if (-not (Test-Path -LiteralPath $exportEnvExample) -and (Test-Path -LiteralPath $sourceEnv)) {
            Convert-EnvironmentFileToExample -SourceEnvPath $sourceEnv -DestinationEnvExamplePath $exportEnvExample -Config $Config
        }

        if ($project.Frameworks -contains 'Laravel') {
            Ensure-LaravelSkeleton -ExportRoot $exportProjectRoot
        }
    }

    $cleanFiles = Get-ChildItem -LiteralPath $exportRoot -Recurse -Force -File -ErrorAction SilentlyContinue
    $cleanBytes = @($cleanFiles | Measure-Object -Property Length -Sum).Sum
    $zipPath = $null

    if (-not $SkipZip) {
        $zipPath = Join-Path -Path $resolvedOutput -ChildPath $ZipName
        New-ZipFromDirectory -SourceDirectory $exportRoot -ZipPath $zipPath
    }

    [pscustomobject]@{
        CleanedSourcePath = $exportRoot
        ZipPath           = $zipPath
        FileCount         = @($cleanFiles).Count
        TotalBytes        = $cleanBytes
        HumanSize         = Get-HumanSize -Bytes $cleanBytes
        Tree              = Get-DirectoryTreeLines -Path $exportRoot -MaxDepth 3
    }
}

function Remove-GeneratedArtifactsInPlace {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        $Analysis
    )

    $removed = New-Object 'System.Collections.Generic.List[string]'

    foreach ($directory in $Analysis.GeneratedArtifacts.Directories) {
        if (-not (Test-Path -LiteralPath $directory.FullPath)) {
            continue
        }

        if (-not (Test-StartsWithPath -Path $directory.FullPath -Root $Analysis.SourcePath)) {
            continue
        }

        if ($PSCmdlet.ShouldProcess($directory.FullPath, 'Remove generated directory')) {
            Remove-Item -LiteralPath $directory.FullPath -Recurse -Force
            $removed.Add($directory.RelativePath)
        }
    }

    foreach ($file in $Analysis.GeneratedArtifacts.Files) {
        if (-not (Test-Path -LiteralPath $file.FullPath)) {
            continue
        }

        if (-not (Test-StartsWithPath -Path $file.FullPath -Root $Analysis.SourcePath)) {
            continue
        }

        if ($PSCmdlet.ShouldProcess($file.FullPath, 'Remove generated file')) {
            Remove-Item -LiteralPath $file.FullPath -Force
            $removed.Add($file.RelativePath)
        }
    }

    [pscustomobject]@{
        RemovedCount = @($removed).Count
        RemovedItems = $removed
    }
}
