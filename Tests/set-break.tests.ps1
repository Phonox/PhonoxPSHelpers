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

Describe "Set-Break" -Tags "Set-Break","UT" {
    it 'Should be possible to turn ON Break' {
        Set-Break -Turn:$true
        $oldSession = [DateTime]$Global:StartofSession
        $global:OnBreak | Should -BeTrue
    }
    start-sleep -Milliseconds 300
    it 'Should be possible to turn OFF Break' {
        Set-Break -Turn:$false
        $global:OnBreak | Should -BeFalse
    }
    it 'Should have changed StartOfSession' {
        $Global:StartofSession -ne $OldSession | Should -BeTrue
    }
    it 'Should have changed StartOfSession with atleast 300ms' {
        [math]::Round( ($Global:StartofSession - $OldSession).TotalMilliseconds) |Should -BeGreaterOrEqual 300
    }

}