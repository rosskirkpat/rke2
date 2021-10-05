#Requires -Version 5.0

$ErrorActionPreference = 'Stop'

Import-Module -WarningAction Ignore -Name "$PSScriptRoot\utils.psm1"

Invoke-Script -File "$PSScriptRoot\build-binary.ps1"
# Invoke-Script -File "$PSScriptRoot\build-runtime.ps1"
Invoke-Script -File "$PSScriptRoot\package.ps1"
