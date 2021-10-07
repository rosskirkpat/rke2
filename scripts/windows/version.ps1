#Requires -Version 5.0

[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $KUBERNETES_VERSION,
    [Parameter()]
    [String]
    $COMMIT,
    [Parameter()]
    [String]
    $TAG,
    [Parameter()]
    [String]
    $VERSION,
    [Parameter()]
    [String]
    $ETCD_VERSION,
    [Parameter()]
    [String]
    $KUBERNETES_IMAGE_TAG,
    [Parameter()]
    [String]
    $PAUSE_VERSION,
    [Parameter()]
    [String]
    $CCM_VERSION,
    [Parameter()]
    [String]
    $IMAGE_BUILD_VERSION
)

$ErrorActionPreference = 'Stop'
Import-Module -WarningAction Ignore -Name "$PSScriptRoot\utils.psm1"

$env:OS = "windows"
$env:TREE_STATE = "clean"

function Get-Args {
    if ($KUBERNETES_VERSION) {
        $env:KUBERNETES_VERSION = $KUBERNETES_VERSION
    }

    if ($env:DRONE_COMMIT) {
        $COMMIT = $env:DRONE_COMMIT
        $env:COMMIT = $COMMIT
    }
    else {
        $env:COMMIT = $COMMIT
        $COMMIT = $env:COMMIT
    }

    if ($VERSION) {
        $env:VERSION = $VERSION
    }

    if ($env:DRONE_TAG) {
        $TAG = $env:DRONE_TAG
        $env:TAG = $TAG
    }
    else {
        $TAG = $env:VERSION
        $env:TAG = $TAG
    }

    if ($ETCD_VERSION) {
        $env:ETCD_VERSION = $ETCD_VERSION
    }

    if ($KUBERNETES_IMAGE_TAG) {
        $env:KUBERNETES_IMAGE_TAG = $KUBERNETES_IMAGE_TAG
    }

    if ($PAUSE_VERSION) {
        $env:PAUSE_VERSION = $PAUSE_VERSION
    }

    if ($CCM_VERSION) {
        $env:CCM_VERSION = $CCM_VERSION
    }

    if ($IMAGE_BUILD_VERSION) {
        $env:IMAGE_BUILD_VERSION = $IMAGE_BUILD_VERSION
    }
}

function Set-Environment {
    if (-Not $env:KUBERNETES_VERSION) {
        $env:KUBERNETES_VERSION = "v1.21.3"
    }

    if ("$(git status --porcelain --untracked-files=no)") {
        $env:DIRTY = ".dirty"
        $env:TREE_STATE = "dirty"
    }

    if (-Not $env:ETCD_VERSION) {
        $env:ETCD_VERSION = "v3.4.13-k3s1"
    }

    if (-Not $env:KUBERNETES_IMAGE_TAG) {
        $env:KUBERNETES_IMAGE_TAG = "v1.21.3-rke2r2-build20210809"
    }

    if (-Not $env:PAUSE_VERSION) {
        $env:PAUSE_VERSION = "3.5"
    }

    if (-Not $env:CCM_VERSION) {
        $env:CCM_VERSION = "v0.0.1-build20210629"
    }

    if (-Not $env:IMAGE_BUILD_VERSION) {
        $env:IMAGE_BUILD_VERSION = "build20210223"
    }
}

function Set-Variables() {
    if (-Not $env:TAG) {
        if (Test-Path -Path $env:DAPPER_SOURCE\.git) {
            Push-Location $env:DAPPER_SOURCE
            if (-not $env:TAG -and $env:TREE_STATE -eq "clean") {
                $env:TAG = $(git tag -l --contains HEAD | Select-Object -First 1)
            }
            if (-not $env:COMMIT) {
                $env:COMMIT = $(git rev-parse --short HEAD)
                $COMMIT = $env:COMMIT
                Write-Host $COMMIT
                exit 1
            }
            else {
                if (-Not $env:COMMIT -and -Not $env:DRONE_COMMIT) {
                    $env:COMMIT = $(git rev-parse --short HEAD)
                }
            }
            Pop-Location
            if ($env:TREE_STATE -eq "clean") {
                $env:VERSION = $env:TAG # We will only accept the tag as our version if the tree state is clean and the tag is in fact defined.
            }
            else {
                $env:TAG = $env:VERSION
            }
        }
        else {
            if (-Not $env:VERSION -and $env:DIRTY) {
                if (-not $env:COMMIT) {
                    $env:COMMIT = $(git rev-parse --short HEAD)
                    $COMMIT = $env:COMMIT
                    Write-Host "Using commit: $COMMIT"
                }
                $env:VERSION = "${env:KUBERNETES_VERSION}-dev+${env:COMMIT}$env:DIRTY"
                $VERSION = $env:VERSION
            }
    
            if (-Not $env:TAG) {
                $env:TAG = $env:VERSION
            }
        }

        if (-Not $env:VERSION -and -Not $env:COMMIT) {
            # Validate our commit hash to make sure it's actually known, otherwise our version will be off.
            Write-Host "Unknown commit hash. Exiting."
            exit 1
        }
        else {
            # validate the tag format and create our VERSION variable
            # if ($TREE_STATE -eq "dirty") {
            #     if (-not ($env:TAG -match '^v([0-9]+)\.([0-9]+)(\.[0-9]+)?([-+].*)?$')) {
            #         Write-Host "Tag does not match our expected development format. Exiting."
            #         exit 1
            # }
            if ($env:TREE_STATE -eq "clean") {
                if (-not ($env:TAG -match '^v[0-9]{1}\.[0-9]{2}\.[0-9]+-*[a-zA-Z0-9]*\+rke2r[0-9]+$')) {
                    Write-Host "Tag does not match our expected publish format. Exiting."
                    exit 1
                }
            }
            $env:VERSION = $env:TAG
        }
    }
}

$ARCH = $env:ARCH
if (-Not $ARCH) {
    $ARCH = "amd64"
}
$env:ARCH = $ARCH

$GOARCH = (go env GOARCH)
if (-Not $GOARCH) {
    $GOARCH = "amd64"
}
$env:GOARCH = $GOARCH

$GOOS = (go env GOOS)
if ($GOOS -ne $env:OS) {
    Log-Fatal "GOOS:$GOOS does not match build OS:$env:OS"
}
if (-Not $GOOS) {
    $GOOS = "windows"
}
$env:GOOS = $GOOS

$PROG = $env:PROG
if (-not $PROG) {
    $PROG = "rke2"
}
$env:PROG = $PROG

$REPO = $env:REPO
if (-not $REPO) {
    $REPO = "rancher"
}
$env:REPO = $REPO

$REGISTRY = "docker.io"
$env:REGISTRY = $REGISTRY

$PLATFORM = "${env:GOOS}-${env:GOARCH}"
$env:PLATFORM = $PLATFORM
$RELEASE = "${env:PROG}.${env:PLATFORM}"
$env:RELEASE = $RELEASE

$K3S_PKG = "github.com/rancher/k3s"
$env:K3S_PKG = $K3S_PKG
$RKE2_PKG = "github.com/rancher/rke2"
$env:RKE2_PKG = $RKE2_PKG

Get-Args
Set-Environment
Set-Variables

$env:COMMIT = $COMMIT
$VERSION = $env:VERSION.Replace('+', '-')
$env:VERSION = $VERSION
$DOCKERIZED_VERSION = $VERSION
$env:DOCKERIZED_VERSION = $DOCKERIZED_VERSION
$env:TAG = $env:DOCKERIZED_VERSION
$env:IMAGE = "$env:REPO/${env:PROG}:$env:DOCKERIZED_VERSION"

Write-Host "ARCH: $env:ARCH"
Write-Host "IMAGE VERSION: $env:IMAGE"
Write-Host "VERSION: $env:DOCKERIZED_VERSION"
