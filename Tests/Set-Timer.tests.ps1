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

Describe "Timer features" -Tags "Set-Timer","UT" {
    It 'Should be no timers right now' {
        # incase if this is not a clean environment, this can fail as there are more timers
        Get-timer | should -BeNullOrEmpty
    }
    $SoonDate = [datetime]::now.AddSeconds(0.5)
    It "Should be possible to add timer" {
        { Set-timer -date $SoonDate "test" } | Should -not -Throw
    }
    It 'There should be 1 timers active' {
        (Get-timer ).id.count | should -be 1
    }
    It 'Should be no timers right now' {
        while ( ([datetime]::now.AddSeconds( - 1 ) -lt $SoonDate) ) {}
        (Get-timer | Where-Object Time -eq $SoonDate ).id.count | should -be 0
    }
}

# Describe 'test Get-Timer' {
#     Context 'int pipe' {
#         $d = 22
#         It 'correct type' {
#             #( $d |Get-Timer ).GetType().Name     | Should -Be "int32"
#             $d | get-timer | should -BeOfType [int]
#         }
#         It 'correct value' {
#             $d |Get-Timer | Should -Be $d
#         }
#     }
#     Context 'string int pipe' {
#         $d = "22"
#         It 'correct type' {
#             #( $d |Get-Timer ).GetType().Name   | Should -Be "int32"
#             $d | get-timer | should -BeOfType [int]
#         }
#         It 'correct value' {
#             $d |Get-Timer | Should -Be $d 
#         }
#     }
#     Context 'datetime pipe' {
#         $d = "22:00"
#         It 'correct type' {
#             #( $d |Get-Timer ).GetType().Name| Should -Be "DateTime"
#             $d | get-timer | should -BeOfType [DateTime]
#         }
#         It 'correct value' {
#             $d |Get-Timer | Should -Be (Get-Date $d)
#         }
#     }
#     Context 'function int' {
#         $d = 22
#         It 'correct type' {
#             #( Get-Timer $d ).GetType().Name      | should -Be "int32"
#             get-timer $d | should -BeOfType [int]
#         }
#         #It 'new correct type' {
#         #    get-timer $d | should -BeOfType [int]
#         #}
#         It 'correct value' {
#             $d |Get-Timer | Should -Be $d
#         }
#     }
#     Context 'function datetime' {
        
#         It 'correct type' {
#             #( Get-Timer 22:00 ).GetType().Name   | Should -Be "DateTime"
#             get-timer 22:00 | should -BeOfType [DateTime]
#         }
#         It 'correct value' {
#             Get-Timer 22:00 | Should -Be (Get-Date 22:00)
#         }
#     }
#     Context 'function string DateTime' {
#         $d = "22:00"
#         It 'correct type' {
#             #( Get-Timer $d ).GetType().Name | Should -Be "DateTime"
#             get-timer $d | should -BeOfType [DateTime]
#         }
#         It 'correct value' {
#             $d |Get-Timer | Should -Be (Get-Date $d)
#         }
#     }
# }

#22 |Get-Timer
#"22:00" |Get-Timer
#"22" |Get-Timer
#Get-Timer 22
#Get-Timer 22:00
#Get-Timer "22:00"