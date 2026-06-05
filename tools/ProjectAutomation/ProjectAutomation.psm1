$privateScripts = @(
    'Private\Common.ps1',
    'Private\Analysis.ps1',
    'Private\Export.ps1',
    'Private\Report.ps1'
)

foreach ($script in $privateScripts) {
    . (Join-Path -Path $PSScriptRoot -ChildPath $script)
}

function Start-ProjectAutomation {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [string]$OutputPath,
        [string]$ZipName = 'cleaned_project_source.zip',
        [switch]$SkipExport,
        [switch]$SkipZip,
        [switch]$EnableInPlaceCleanup,
        [switch]$PassThru
    )

    $resolvedSource = Resolve-AbsolutePath -Path $SourcePath

    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $OutputPath = Join-Path -Path $resolvedSource -ChildPath ('artifacts\project-automation\' + $timestamp)
    }

    $resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
    if (-not (Test-Path -LiteralPath $resolvedOutput)) {
        [void](New-Item -ItemType Directory -Path $resolvedOutput -Force)
    }

    $config = Get-ProjectAutomationConfig -ModuleRoot $PSScriptRoot
    $analysis = New-ProjectAnalysis -SourcePath $resolvedSource -OutputPath $resolvedOutput -Config $config
    $analysis.OutputPath = $resolvedOutput
    $analysis.Reports = [pscustomobject]@{
        MarkdownPath = Join-Path -Path $resolvedOutput -ChildPath 'project-report.md'
        JsonPath     = Join-Path -Path $resolvedOutput -ChildPath 'project-report.json'
    }

    if (-not $SkipExport) {
        $analysis.Outputs = Export-CleanProjectWorkspace -Analysis $analysis -Config $config -OutputPath $resolvedOutput -ZipName $ZipName -SkipZip:$SkipZip
    }

    if ($EnableInPlaceCleanup) {
        if ($PSCmdlet.ShouldProcess($resolvedSource, 'Remove generated artifacts in place')) {
            $cleanup = Remove-GeneratedArtifactsInPlace -Analysis $analysis -Confirm:$false
            $analysis | Add-Member -NotePropertyName Cleanup -NotePropertyValue $cleanup -Force
        }
    }

    [void](Write-ProjectReports -Analysis $analysis)

    if ($PassThru) {
        return $analysis
    }

    [pscustomobject]@{
        SourcePath         = $analysis.SourcePath
        OutputPath         = $analysis.OutputPath
        ReportMarkdownPath = $analysis.Reports.MarkdownPath
        ReportJsonPath     = $analysis.Reports.JsonPath
        CleanedSourcePath  = if ($analysis.Outputs) { $analysis.Outputs.CleanedSourcePath } else { $null }
        ZipPath            = if ($analysis.Outputs) { $analysis.Outputs.ZipPath } else { $null }
        Frameworks         = $analysis.Stack.Frameworks
        PackageManagers    = $analysis.Stack.PackageManagers
        ProjectRoots       = $analysis.Workspace.ProjectRoots
        TotalIssues        = @($analysis.Issues).Count
        HighSeverityIssues = @($analysis.Issues | Where-Object { $_.Severity -eq 'High' }).Count
    }
}

Export-ModuleMember -Function Start-ProjectAutomation
