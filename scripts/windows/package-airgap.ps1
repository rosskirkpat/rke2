#Requires -Version 5.0
$ErrorActionPreference = "Stop"

Invoke-Expression -Command "$PSScriptRoot\version.ps1"
Invoke-Script -File "$PSScriptRoot\runtime-versions.ps1"