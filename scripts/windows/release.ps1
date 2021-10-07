#Requires -Version 5.0

param (
    [parameter(Mandatory = $false)] [string]$PushImageToLibrary = "rancher"
)

$ErrorActionPreference = 'Stop'

Import-Module -WarningAction Ignore -Name "$PSScriptRoot\utils.psm1"

Invoke-Script -File "$PSScriptRoot\ci.ps1"
Invoke-Script -File "$PSScriptRoot\version.ps1"
Invoke-Script -File "$PSScriptRoot\runtime-versions.ps1"

# & "$PSScriptRoot\version.ps1" | Out-Null

# validate the tag format and create our VERSION variable
if (-not ($env:TAG -match '^v[0-9]{1}\.[0-9]{2}\.[0-9]+-*[a-zA-Z0-9]*\+rke2r[0-9]+$')) {
    Write-Host "Tag does not match our expected format. Exiting."
    exit 1   
}
$VERSION = $env:TAG

$baseTag = "rke2:$VERSION"
$currentTag = "rancher/$baseTag"
$pushTag = "$PushImageToLibrary/$baseTag"

$currentReleaseId = (docker images $currentTag --format "{{.ID}}")
$pushedReleaseId = (docker images $pushTag --format "{{.ID}}")
if ($currentReleaseId -ne $pushedReleaseId) {
    docker tag $pushTag "$pushTag-bak" | Out-Null
    docker tag $currentTag $pushTag | Out-Null
}

docker push $pushTag
if ($?) {
    docker rmi "$pushTag-bak" | Out-Null
    docker rmi $currentTag | Out-Null
    Write-Host "$pushTag was PUSHED"
} else {
    docker tag "$pushTag-bak" $pushTag | Out-Null
    docker rmi "$pushTag-bak" | Out-Null
    Write-Host -ForegroundColor Red "$pushTag has something wrong while PUSHING"
}


# else {
#     # validate the tag format and create our VERSION variable
#     if (-not ($TAG -match '^v[0-9]{1}\.[0-9]{2}\.[0-9]+-*[a-zA-Z0-9]*\+rke2r[0-9]+$')) {
#         Write-Host "Tag does not match our expected format. Exiting."
#         exit 1
#     }

#     $VERSION = $TAG
# $VERSION = $VERSION.Replace('+', '-')
