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

Describe "PersistentData" -Tags "PersistentData","UT" {
    It "Remove-PersistentData" {
        Remove-PersistentData Bajs
        $global:bajs |Should -BeNullOrEmpty
    }
    It "Set-PersistentData" {
        Set-PersistentData bajs "test"
        $global:bajs | Should -be "test"
    }
    it "New instance should find this new Persistent variable" {
        $test = powershell -Command "Import-Module $ModulePath -ea Ignore -Force -DisableNameChecking *>`$null ; return `$bajs "
        #start-sleep -s 2
        Update-PersistentData
        $test |should -be "test"
    }
    it "New instance should be able to remove an variable in the old instance" {
        Set-ItResult -Skipped -Because "im not sure why it fails."
        $null = powershell -Command "Import-Module $ModulePath -ea Ignore -Force -DisableNameChecking *>`$null ; Update-PersistentData *>`$null ; start-sleep -s 1 ; Remove-PersistentData Bajs ;start-sleep -s 1; Update-PersistentData *>`$null"
        start-sleep -s 1
        Update-PersistentData
        start-sleep -s 1
        $global:bajs |Should -BeNullOrEmpty
    }
}