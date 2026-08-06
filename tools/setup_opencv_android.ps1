param(
    [string]$Destination = (Join-Path $PSScriptRoot '..\.tooling\opencv-4.13.0')
)

$ErrorActionPreference = 'Stop'

$version = '4.13.0'
$expectedSha256 = 'edfda20fdf65d0bd45391d168ec5261dd30b600b00279c4d910d7f1c3e020f0f'
$downloadUrl = "https://github.com/opencv/opencv/releases/download/$version/opencv-$version-android-sdk.zip"
$resolvedDestination = [System.IO.Path]::GetFullPath($Destination)
$sdkMarker = Join-Path $resolvedDestination 'OpenCV-android-sdk\sdk\native\jni\OpenCVConfig.cmake'

if (Test-Path -LiteralPath $sdkMarker) {
    Write-Host "OpenCV $version Android SDK is already available at $resolvedDestination"
    Write-Output (Join-Path $resolvedDestination 'OpenCV-android-sdk')
    exit 0
}

$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) "shooting-companion-opencv-$version"
$archivePath = Join-Path $temporaryRoot "opencv-$version-android-sdk.zip"
$extractPath = Join-Path $temporaryRoot 'extract'

try {
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
    Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath

    $actualSha256 = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualSha256 -ne $expectedSha256) {
        throw "OpenCV checksum mismatch. Expected $expectedSha256, received $actualSha256."
    }

    Expand-Archive -LiteralPath $archivePath -DestinationPath $extractPath
    $extractedSdk = Join-Path $extractPath 'OpenCV-android-sdk'
    if (-not (Test-Path -LiteralPath (Join-Path $extractedSdk 'sdk\native\jni\OpenCVConfig.cmake'))) {
        throw 'The official OpenCV archive does not contain the expected Android SDK layout.'
    }

    $destinationParent = Split-Path -Parent $resolvedDestination
    New-Item -ItemType Directory -Path $destinationParent -Force | Out-Null
    if (Test-Path -LiteralPath $resolvedDestination) {
        Remove-Item -LiteralPath $resolvedDestination -Recurse -Force
    }
    Move-Item -LiteralPath $extractPath -Destination $resolvedDestination

    $sdkPath = Join-Path $resolvedDestination 'OpenCV-android-sdk'
    Write-Host "Verified OpenCV $version Android SDK at $sdkPath"
    Write-Output $sdkPath
} finally {
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}
