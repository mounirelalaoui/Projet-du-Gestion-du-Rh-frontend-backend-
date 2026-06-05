function Convert-AnalysisToMarkdown {
    param(
        [Parameter(Mandatory = $true)]
        $Analysis
    )

    $lines = New-Object 'System.Collections.Generic.List[string]'
    $highIssues = @($Analysis.Issues | Where-Object { $_.Severity -eq 'High' })
    $mediumIssues = @($Analysis.Issues | Where-Object { $_.Severity -eq 'Medium' })
    $issueCount = [int]$Analysis.Issues.Count
    $criticalFileCount = [int]@($Analysis.CriticalFiles).Count
    $environmentFileCount = [int]@($Analysis.EnvironmentFiles).Count

    $lines.Add('# Project Automation Report')
    $lines.Add('')
    $lines.Add('- Generated at: ' + $Analysis.GeneratedAt)
    $lines.Add('- Source path: `' + $Analysis.SourcePath + '`')
    $lines.Add('- Workspace size: ' + $Analysis.Workspace.HumanSize)
    $lines.Add('- Detected project roots: ' + $Analysis.Workspace.ProjectRoots)
    $lines.Add('- Frameworks: ' + (@($Analysis.Stack.Frameworks) -join ', '))
    $lines.Add('- Languages: ' + (@($Analysis.Stack.Languages) -join ', '))
    $lines.Add('- Package managers: ' + (@($Analysis.Stack.PackageManagers) -join ', '))
    $lines.Add('')
    $lines.Add('## Summary')
    $lines.Add('')
    $lines.Add(('- Total issues: {0}' -f $issueCount))
    $lines.Add(('- High severity issues: {0}' -f ([int]@($highIssues).Count)))
    $lines.Add(('- Medium severity issues: {0}' -f ([int]@($mediumIssues).Count)))
    $lines.Add(('- Critical files tracked: {0}' -f $criticalFileCount))
    $lines.Add(('- Environment files tracked: {0}' -f $environmentFileCount))
    $lines.Add('')

    $frontendProjects = @($Analysis.Projects | Where-Object { $_.Role -in @('Frontend', 'FullStack') })
    $backendProjects = @($Analysis.Projects | Where-Object { $_.Role -in @('Backend', 'FullStack') })

    $lines.Add('## Frontend Analysis')
    $lines.Add('')
    if (@($frontendProjects).Count -eq 0) {
        $lines.Add('- No frontend project detected.')
    }
    else {
        foreach ($project in $frontendProjects) {
            $lines.Add('- `' + $project.RelativeRoot + '` -> ' + (@($project.Frameworks) -join ', '))
            $lines.Add('  - Components: ' + $project.Categories.Components.Count + ', Hooks: ' + $project.Categories.Hooks.Count + ', Services: ' + $project.Categories.Services.Count + ', Routes: ' + $project.Categories.Routes.Count)
            $lines.Add('  - Managers: ' + (@($project.PackageManagers) -join ', '))
        }
    }
    $lines.Add('')

    $lines.Add('## Backend Analysis')
    $lines.Add('')
    if (@($backendProjects).Count -eq 0) {
        $lines.Add('- No backend project detected.')
    }
    else {
        foreach ($project in $backendProjects) {
            $lines.Add('- `' + $project.RelativeRoot + '` -> ' + (@($project.Frameworks) -join ', '))
            $lines.Add('  - Controllers: ' + $project.Categories.Controllers.Count + ', Models: ' + $project.Categories.Models.Count + ', Services: ' + $project.Categories.Services.Count + ', Routes/APIs: ' + $project.Categories.Routes.Count + '/' + $project.Categories.Api.Count)
            $lines.Add('  - Managers: ' + (@($project.PackageManagers) -join ', '))
        }
    }
    $lines.Add('')

    $lines.Add('## Detected Issues')
    $lines.Add('')
    if ($issueCount -eq 0) {
        $lines.Add('- No notable issue detected by the static analysis rules.')
    }
    else {
        foreach ($issue in ($Analysis.Issues | Sort-Object Severity, Code, Path)) {
            $context = if ([string]::IsNullOrWhiteSpace($issue.Path)) { '' } else { ' (`' + $issue.Path + '`)'}
            $lines.Add('- [' + $issue.Severity + '] ' + $issue.Message + $context)
        }
    }
    $lines.Add('')

    $lines.Add('## Dependencies')
    $lines.Add('')
    foreach ($project in $Analysis.Projects) {
        $lines.Add('- `' + $project.RelativeRoot + '`')
        foreach ($bucket in @('JavaScript', 'PHP', 'Python', 'Java')) {
            $deps = @($project.Dependencies.$bucket | Select-Object -First 15)
            if (@($deps).Count -gt 0) {
                $lines.Add('  - ' + $bucket + ': ' + ($deps -join ', '))
            }
        }
    }
    $lines.Add('')

    $lines.Add('## Launch Commands')
    $lines.Add('')
    foreach ($plan in $Analysis.LaunchPlans) {
        $lines.Add('- `' + $plan.Project + '`')
        foreach ($command in $plan.Commands) {
            $lines.Add('  - ' + $command.Step + ': `' + $command.Command + '`')
        }
    }
    $lines.Add('')

    if ($Analysis.Outputs) {
        $lines.Add('## Clean Export')
        $lines.Add('')
        $lines.Add('- Cleaned source: `' + $Analysis.Outputs.CleanedSourcePath + '`')
        if ($Analysis.Outputs.ZipPath) {
            $lines.Add('- ZIP: `' + $Analysis.Outputs.ZipPath + '`')
        }
        $lines.Add('- Cleaned size: ' + $Analysis.Outputs.HumanSize)
        $lines.Add('- Files copied: ' + $Analysis.Outputs.FileCount)
        $lines.Add('')
        $lines.Add('```text')
        foreach ($treeLine in $Analysis.Outputs.Tree) {
            $lines.Add($treeLine)
        }
        $lines.Add('```')
        $lines.Add('')
    }

    $lines -join "`r`n"
}

function Write-ProjectReports {
    param(
        [Parameter(Mandatory = $true)]
        $Analysis
    )

    if (-not (Test-Path -LiteralPath $Analysis.OutputPath)) {
        [void](New-Item -ItemType Directory -Path $Analysis.OutputPath -Force)
    }

    $markdown = Convert-AnalysisToMarkdown -Analysis $Analysis
    Set-Content -LiteralPath $Analysis.Reports.MarkdownPath -Value $markdown -Encoding UTF8

    $json = (ConvertTo-SerializableObject -InputObject $Analysis) | ConvertTo-Json -Depth 10
    Set-Content -LiteralPath $Analysis.Reports.JsonPath -Value $json -Encoding UTF8

    $Analysis.Reports
}
