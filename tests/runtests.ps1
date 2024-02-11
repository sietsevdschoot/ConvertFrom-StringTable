if (!(Get-Module Pester)) {
    
    Import-Module Pester -Force
}

Get-ChildItem $PSScriptRoot\*.tests.ps1 | ForEach-Object { Invoke-Pester $_.FullName }