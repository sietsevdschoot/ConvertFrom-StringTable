[CmdletBinding()]
param()

$modulePath = Join-Path $PSScriptRoot "ConvertFrom-StringTable"

if (Test-Path $modulePath) {

    Remove-Item $modulePath -Recurse -Force
}

Copy-Item (Join-Path $PSScriptRoot src) $modulePath -Recurse -Verbose -Force

$apiKey = (Get-Content $PSScriptRoot\..\Credentials\PSGalleryApiKey.txt -Raw).Trim()
Publish-Module -Path $modulePath -NuGetApiKey $apiKey -Repository PSGallery -Verbose