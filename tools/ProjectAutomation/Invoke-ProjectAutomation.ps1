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

$modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'ProjectAutomation.psm1'
Import-Module -Name $modulePath -Force

Start-ProjectAutomation -SourcePath $SourcePath -OutputPath $OutputPath -ZipName $ZipName -SkipExport:$SkipExport -SkipZip:$SkipZip -EnableInPlaceCleanup:$EnableInPlaceCleanup -PassThru:$PassThru -WhatIf:$WhatIfPreference -Confirm:$false
