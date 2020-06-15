#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '4.9.0' }
$ScriptPath = $PSScriptRoot
$File = ( Split-Path $PSCommandPath -Leaf ) -replace '\.tests\.ps1$','.ps1'
$FilePath = Join-Path (Join-Path $ScriptPath ..) (Join-Path Functions $File)
$ModulePath = Convert-Path (Join-Path $ScriptPath "..")
if ( !(test-path $FilePath ) ) { Write-Error "Failed to find file"}
if ( Get-Module PhonoxsPSHelpers ) { Remove-Module PhonoxsPSHelpers }
if (-Not (Get-Module PhonoxsPSHelpers ) ) { Import-Module $ModulePath -ea Ignore }


Context "Write-FancyMessage" {
    It "Should output 3 rows with 1 input" {
        $test2 = Write-FancyMessage "test test" *>&1
        $test2 | Should -HaveCount 3
    }
    It "Should output 4 rows with 2 inputs" {
        $test2 = Write-FancyMessage "test","test" *>&1
        $test2 | Should -HaveCount 4
    }
    It "Should have a normal delimiter as *" {
        $test2 = Write-FancyMessage "testtest" *>&1
        $test2.Messagedata.Message[0].ToString()[0] | Should -Be "*"
    }
    It "Should be possible to change delimiter" {
        $test2 = Write-FancyMessage "testtest" -BorderChar "#" *>&1
        $test2.Messagedata.Message[0].ToString()[0] | Should -Be "#"
    }
    It "Should allow piping" {
        $test2 = "test","test2" |Write-FancyMessage *>&1
        $test2 | Should -HaveCount 4
    }
}