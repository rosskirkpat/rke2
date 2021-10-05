#Requires -Version 5.0
$ErrorActionPreference = "Stop"

Invoke-Expression -Command "$PSScriptRoot\version.ps1"
Invoke-Script -File "$PSScriptRoot\runtime-versions.ps1"


$TAG = $env:VERSION
$REPO = $env:REPO
$ARCH = $env:ARCH

if ($env:DIRTY) {
    $TAG = "dev"
}

# Get release id as image tag suffix
$HOST_RELEASE_ID = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\' -ErrorAction Ignore).ReleaseId
if ($HOST_RELEASE_ID -eq "2009") {
    $HOST_RELEASE_ID = "20H2"
}
if (-not $HOST_RELEASE_ID) {
    Log-Fatal "release ID not found"
}
$IMAGE = ("{0}/rke2-runtime:{1}-windows-{2}-{3}" -f $REPO, $TAG, $HOST_RELEASE_ID, $ARCH)

Set-Location $SRC_PATH

$DOCKERFILE = "scripts/windows/rke2-runtime-windows.dockerfile"

docker image build `
    --build-arg SERVERCORE_VERSION=$HOST_RELEASE_ID `
    --build-arg ARCH=$ARCH `
    --build-arg VERSION=$TAG `
    --build-arg RUNTIME_PATH=$env:RUNTIME_PATH `
    --build-arg CRICTL_VERSION=$env:CRICTL_VERSION `
    --build-arg CONTAINERD_VERSION=$env:CONTAINERD_VERSION `
    --build-arg CALICO_VERSION=$env:CALICO_VERSION `
    --build-arg CNI_PLUGIN_VERSION=$env:CNI_PLUGIN_VERSION `
    --build-arg KUBERNETES_VERSION=$env:KUBERNETES_VERSION `
    --build-arg WINS_VERSION=$env:WINS_VERSION `
    -t $env:IMAGE `
    -f $DOCKERFILE .

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
Write-Host "Built $IMAGE"