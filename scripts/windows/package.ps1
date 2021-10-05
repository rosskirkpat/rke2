#Requires -Version 5.0
$ErrorActionPreference = "Stop"

Invoke-Expression -Command "$PSScriptRoot\version.ps1"
Invoke-Script -File "$PSScriptRoot\runtime-versions.ps1"

$SRC_PATH = (Resolve-Path "$PSScriptRoot\..\..").Path

# Reference binary in ./bin/rke2.exe
New-Item -ItemType Directory -Path $SRC_PATH\dist\bundle\bin\ -Force | Out-Null
Copy-Item -Force -Path $SRC_PATH\bin\rke2.exe -Destination $SRC_PATH\dist\bundle\bin\ | Out-Null

# Set-Location -Path $SRC_PATH\dist\bundle
