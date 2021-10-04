#Requires -Version 5.0
$ErrorActionPreference = "Stop"

Invoke-Expression -Command "$PSScriptRoot\version.ps1"

$DIR_PATH = Split-Path -Parent $MyInvocation.MyCommand.Definition
$SRC_PATH = (Resolve-Path "$DIR_PATH\..\..").Path

# Reference binary in ./bin/rke2.exe
Copy-Item -Force -Path $SRC_PATH\bin\rke2.exe -Destination $SRC_PATH\dist\bundle\bin\ | Out-Null

Set-Location -Path $SRC_PATH\dist\bundle

$TAG = $env:VERSION
$REPO = $env:REPO

if ($env:DIRTY) {
    $TAG = "dev"
}

# Get release id as image tag suffix
$HOST_RELEASE_ID = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\' -ErrorAction Ignore).ReleaseId
if ($HOST_RELEASE_ID -eq "2009") {
    $HOST_RELEASE_ID = "20H2"
}
$IMAGE = ('{0}/wins:{1}-windows-{2}' -f $REPO, $TAG, $HOST_RELEASE_ID)
if (-not $HOST_RELEASE_ID) {
    Log-Fatal "release ID not found"
}

$ARCH = $env:ARCH

docker build `
    --build-arg SERVERCORE_VERSION=$HOST_RELEASE_ID `
    --build-arg ARCH=$ARCH `
    --build-arg VERSION=$TAG `
    -t $IMAGE `
    -f Dockerfile .

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "Built $IMAGE`n"
