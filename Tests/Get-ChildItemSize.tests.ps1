#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '4.9.0' }
$ScriptPath = $PSScriptRoot
$File = ( Split-Path $PSCommandPath -Leaf ) -replace '\.tests\.ps1$', '.ps1'
$FilePath = Join-Path (Join-Path $ScriptPath ..) (Join-Path Functions $File)
$ModulePath = Convert-Path (Join-Path $ScriptPath "..")
if ( !(test-path $FilePath ) ) { Write-Error "Failed to find file" }
if ($global:lastImport) {$totalMS = ( [datetime]::now - $global:lastImport).TotalMilliseconds}
if ( !(Get-Module PhonoxsPSHelpers) -or !$global:lastImport -or $totalMS -gt 30000) {
    $global:lastImport = [datetime]::Now
    if ( Get-Module PhonoxsPSHelpers ) { Remove-Module PhonoxsPSHelpers }
    if (-Not (Get-Module PhonoxsPSHelpers ) ) { Import-Module $ModulePath -ea Ignore -Force *>$null }
}

Describe "Get-ChildItemSize" -tags "Get-ChildItemSize"{
    It "Should get the size of a file" {
        ( Get-ChildItemSize ( Join-Path (Join-Path $ScriptPath ..) PhonoxsPSHelpers.psd1) ).Length | should -BeGreaterThan 6062
    }
    It "Should get the size of a folder" {
        ( Get-ChildItemSize ( Join-Path (Join-Path $ScriptPath ..) ps1xml ) ).Length | should -be 25526
    }
}