# Requires -Version 5.0

$ErrorActionPreference = 'Stop'

Import-Module -WarningAction Ignore -Name "$PSScriptRoot\utils.psm1"

# param (
#     [Parameter()]
#     [String]
#     $Version,
#     [Parameter()]
#     [String]
#     $Commit,
#     [Parameter()]
#     [String]
#     $Output
# )

function Build-RKE2 {

    # [CmdletBinding()]
    # param (
    #     [Parameter()]
    #     [String]
    #     $Version,
    #     [Parameter()]
    #     [String]
    #     $Commit,
    #     [Parameter()]
    #     [String]
    #     $Output
    # )
    if ($null -ne $GODEBUG -and $env:GODEBUG) { 
        $env:EXTRA_LDFLAGS="$env:EXTRA_LDFLAGS -s -w"
        $env:DEBUG_GO_GCFLAGS=""
        $env:DEBUG_TAGS=""
        else {
        $env:DEBUG_GO_GCFLAGS='-gcflags=all=-N -l'
        }
    }

    $env:REVISION="$(git rev-parse HEAD)if($null -ne $(git diff --no-ext-diff --quiet --exit-code)){Write-Output .dirty}"
    $env:RELEASE="$env:PROG-windows.amd64"

    $env:BUILDTAGS="netgo osusergo no_stage static_build sqlite_omit_load_extension"
    $env:GO_BUILDTAGS="$env:GO_BUILDTAGS $env:BUILDTAGS $env:DEBUG_TAGS"

    $VERSION_FLAGS="
    -X $env:K3S_PKG/pkg/version.GitCommit=$env:REVISION
    -X $env:K3S_PKG/pkg/version.Program=$env:PROG
    -X $env:K3S_PKG/pkg/version.Version=$env:VERSION
    -X $env:RKE2_PKG/pkg/images.DefaultRegistry=$env:REGISTRY
    -X $env:RKE2_PKG/pkg/images.DefaultEtcdImage=rancher/hardened-etcd:$env:ETCD_VERSION-$env:IMAGE_BUILD_VERSION
    -X $env:RKE2_PKG/pkg/images.DefaultKubernetesImage=${REPO}/hardened-kubernetes:$env:KUBERNETES_IMAGE_TAG
    -X $env:RKE2_PKG/pkg/images.DefaultPauseImage=rancher/pause:$env:PAUSE_VERSION
    -X $env:RKE2_PKG/pkg/images.DefaultRuntimeImage=$env:REPO/$env:PROG-runtime:$env:DOCKERIZED_VERSION
    "

    $env:GO_LDFLAGS="$env:STATIC_FLAGS $env:EXTRA_LDFLAGS"
    Write-Output $env:DEBUG_GO_GCFLAGS
    # $CGO_ENABLED=1 $CXX="x86_64-w64-mingw32-g++" $CC="x86_64-w64-mingw32-gcc" 
    $env:GOOS="windows"; $env:GOARCH="amd64"; go build `
    -tags "$env:GO_BUILDTAGS $env:GO_GCFLAGS $env:GO_BUILD_FLAGS" `
    -o "bin/$env:PROG.exe" `
    -ldflags "$env:GO_LDFLAGS $env:VERSION_FLAGS ${GO_TAGS}"
    if (-not $?) {
        Log-Fatal "go build failed!"
    }
}

Invoke-Script -File "$PSScriptRoot\version.ps1"

$SRC_PATH = (Resolve-Path "$PSScriptRoot\..\..").Path
Push-Location $SRC_PATH

Remove-Item -Path "$SRC_PATH\bin\*" -Force -ErrorAction Ignore
$null = New-Item -Type Directory -Path bin -ErrorAction Ignore
# New-Build -Version $env:VERSION -Commit $env:COMMIT -Output "bin\rke2.exe"
Build-RKE2
Pop-Location
