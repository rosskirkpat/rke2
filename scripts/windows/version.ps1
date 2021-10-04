#Requires -Version 5.0
$ErrorActionPreference = 'Stop'

Import-Module -WarningAction Ignore -Name "$PSScriptRoot\utils.psm1"

$env:OS = "windows"

$TREE_STATE = "clean"
$COMMIT = $env:DRONE_COMMIT
$GIT_TAG = $env:DRONE_TAG

function Set-Variables() {
    if (-not $GIT_TAG) {
        if (Test-Path -Path $env:DAPPER_SOURCE\.git) {
            Push-Location $env:DAPPER_SOURCE
            if ("$(git status --porcelain --untracked-files=no)") {
                $DIRTY = ".dirty"
                $env:DIRTY = $DIRTY
                $TREE_STATE = ".dirty"
            }
            if (-not $GIT_TAG -and $TREE_STATE -eq "clean") {
                $GIT_TAG = $(git tag -l --contains HEAD | Select-Object -First 1)
            }

            $COMMIT = $(git rev-parse --short HEAD)
            if (-not $COMMIT) {
                $COMMIT = $(git rev-parse --short HEAD)
                Write-Host $COMMIT
                exit 1
            }
        }
        Pop-Location

        if (-not $GIT_TAG) {
            if ($TREE_STATE -eq "clean") {
                $VERSION = $GIT_TAG # We will only accept the tag as our version if the tree state is clean and the tag is in fact defined.
            }
        }
    }
    else {
        $VERSION = $GIT_TAG
        $VERSION = "${KUBERNETES_VERSION}-dev+${COMMIT:0:8}$DIRTY"
    }

    if (-not $VERSION -and -not $COMMIT) {
        # Validate our commit hash to make sure it's actually known, otherwise our version will be off.
        Write-Host "Unknown commit hash. Exiting."
        exit 1
    }
    else {
        # validate the tag format and create our VERSION variable
        if (-not ($GIT_TAG -match '^v[0-9]{1}\.[0-9]{2}\.[0-9]+-*[a-zA-Z0-9]*\+rke2r[0-9]+$')) {
            Write-Host "Tag does not match our expected format. Exiting."
            exit 1
        }
        $VERSION = $GIT_TAG
    }
}

$ARCH = $env:ARCH
if (-not $ARCH) {
    $ARCH = "amd64"
}
$env:ARCH = $ARCH

$GOARCH = (go env GOARCH)
if (-not $GOARCH) {
    $GOARCH = "amd64"
}
$env:GOARCH = $GOARCH

$GOOS = (go env GOOS)
if ($GOOS -ne $env:OS) {
    Log-Fatal "GOOS:$GOOS does not match build OS:$env:OS"
}
if (-not $GOOS) {
    $GOOS = "windows"
}
$env:GOOS = $GOOS

$PROG = $env:PROG
if (-not $PROG) {
    $PROG = "rke2"
}
$env:PROG = $PROG

$REPO = "rancher"
$env:REPO = $REPO
$env:IMAGE = "$env:REPO/${env:PROG}:$env:VERSION"
$REGISTRY = "docker.io"
$env:REGISTRY = $REGISTRY

$PLATFORM = "${env:GOOS}-${env:GOARCH}"
$env:PLATFORM = $PLATFORM
$RELEASE = "${env:PROG}.${env:PLATFORM}"
$env:RELEASE = $RELEASE

$ETCD_VERSION = $env:ETCD_VERSION
if (-not $ETCD_VERSION) {
    $ETCD_VERSION = "v3.4.13-k3s1"
}
$env:ETCD_VERSION = $ETCD_VERSION

$KUBERNETES_VERSION = $env:KUBERNETES_VERSION
if (-not $KUBERNETES_VERSION) {
    $KUBERNETES_VERSION = "v1.21.3"
}
$env:KUBERNETES_VERSION = $KUBERNETES_VERSION

$KUBERNETES_IMAGE_TAG = $env:KUBERNETES_IMAGE_TAG
if (-not $KUBERNETES_IMAGE_TAG) {
    $KUBERNETES_IMAGE_TAG = "v1.21.3-rke2r2-build20210809"
}
$env:KUBERNETES_IMAGE_TAG = $KUBERNETES_IMAGE_TAG

$PAUSE_VERSION = $env:PAUSE_VERSION
if (-not $PAUSE_VERSION) {
    $PAUSE_VERSION = "3.5"
}
$env:PAUSE_VERSION = $PAUSE_VERSION

$CCM_VERSION = $env:CCM_VERSION
if (-not $CCM_VERSION) {
    $CCM_VERSION = "v0.0.1-build20210629"
}
$env:CCM_VERSION = $CCM_VERSION

$IMAGE_BUILD_VERSION = $env:IMAGE_BUILD_VERSION
if (-not $IMAGE_BUILD_VERSION) {
    $IMAGE_BUILD_VERSION = "build20210223"
}
$env:IMAGE_BUILD_VERSION = $IMAGE_BUILD_VERSION

$K3S_PKG = "github.com/rancher/k3s"
$env:K3S_PKG = $K3S_PKG
$RKE2_PKG = "github.com/rancher/rke2"
$env:RKE2_PKG = $RKE2_PKG

Set-Variables
$env:COMMIT = $COMMIT
$VERSION = $VERSION.Replace('+', '-')
$env:VERSION = $VERSION
$DOCKERIZED_VERSION = $VERSION
$env:DOCKERIZED_VERSION = $DOCKERIZED_VERSION

Write-Host "ARCH: $env:ARCH"
Write-Host "IMAGE VERSION: $env:IMAGE"
Write-Host "VERSION: $env:DOCKERIZED_VERSION"
