Describe 'Testrun of Test-Perf' {
    Context 'SmokeTest Single' {
        It 'Test-Perf should be similar to normal code' {
            $repeat = 100
            $ShouldBe = Measure-Command {
                for($int=1;$int -lt $repeat; $int++) {
                    [void] [System.Collections.ArrayList]@()
                }
            }
            #$moduleTest = Test-Perf -Name "moduleTest" -ScriptBlock { [void] [System.Collections.ArrayList]@() } -Repeat $repeat
            $moduleTest = Test-Perf -Name "moduleTest" -ScriptBlock { [void] [System.Collections.ArrayList]@() } -Repeat $repeat
            $moduletest.time.ticks | Should -BeLessOrEqual ($ShouldBe.Ticks * 2)
        }
        It "Normal" {
            $test = Test-Perf 'woop' { $null = "woopie" ; Start-Sleep -m 10 }
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Name |Should -BeExactly 'woop'
            $test.Time.TotalMilliseconds |should -BeGreaterThan 10
        }
        It 'Should be possible to pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = { $null = "woop" ;Start-sleep -m 10} 
            } |Test-Perf
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Name |Should -BeExactly 'Value'
            $test.Time.TotalMilliseconds |should -BeGreaterThan 10
        }
        It 'Should be possible to Splat' {
            $hash = @{
                Name = "Value"
                E = { $null = "woop" ; Start-sleep -m 10 }
            }
            $test = Test-Perf @hash
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Name |Should -BeExactly 'Value'
            $test.Time.TotalMilliseconds |should -BeGreaterThan 10
        }
    }
    
    Context 'SmokeTest Repeat' {
        It "Normal" {
            $test = Test-Perf 'woop' { $null = "woopie" ; Start-Sleep -m 10 } -Repeat 3
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Name |Should -BeExactly 'woop'
            $test.Time.TotalMilliseconds |should -BeGreaterThan 30
        }
        It 'Should be possible to pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = { $null = "woop";Start-sleep -m 10 }
                Repeat = 3
            } |Test-Perf
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Name |Should -BeExactly 'Value'
            $test.Time.TotalMilliseconds |should -BeGreaterThan 30
        }
        It 'Should be possible to Splat' {
            $hash = @{
                Name = "Value"
                E = {$null = "woop";Start-sleep -m 10 }
                Repeat = 3
            }
            $test = Test-Perf @hash
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Name |Should -BeExactly 'Value'
            $test.Time.TotalMilliseconds |should -BeGreaterThan 30
        }
    }

    Context 'SmokeTest Single Individual' {
        It "Normal" {
            $test = Test-Perf 'woop' { $null = "woopie" ; start-sleep -m 10 } -Individual
            $test.Name |Should -BeExactly 'Ind_woop'
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Time.TotalMilliseconds |should -BeGreaterThan 10
        }
        It 'Pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = { $null = "woop";Start-sleep -m 10}
                Individual = $true
            } |Test-Perf
            $test.Name |Should -BeExactly 'Ind_Value'
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Time.TotalMilliseconds |should -BeGreaterThan 10
        }
        It 'Splat' {
            $hash = @{
                Name = "Value"
                E = { $null = "woop" ; Start-sleep -m 10 }
                Individual = $true
            }
            $test = Test-Perf @hash
            $test.Name |Should -BeExactly 'Ind_Value'
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Time.TotalMilliseconds |should -BeGreaterThan 9
        }
    }

    Context 'SmokeTest Repeat Individual' {
        It "Normal" {
            $test = Test-Perf 'woop' { $null = "woopie" ; start-sleep -m 10 } -Individual -Repeat 3
            $test.Name |Should -BeExactly 'Ind_woop'
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Time.TotalMilliseconds |should -BeGreaterThan 30
        }
        It 'Pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = { $null = "woop";Start-sleep -m 10 }
                Individual = $true
                Repeat = 3
            } |Test-Perf
            $test.Name |Should -BeExactly 'Ind_Value'
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Time.TotalMilliseconds |should -BeGreaterThan 30
        }
        It 'Splat' {
            $hash = @{
                Name = "Value"
                E = { $null = "woop";Start-sleep -m 10 }
                Individual = $true
                Repeat = 3
            }
            $test = Test-Perf @hash
            $test.Name |Should -BeExactly 'Ind_Value'
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Time.TotalMilliseconds |should -BeGreaterThan 30
        }
    }
    
    Context 'SmokeTest Single MultipleTest' { # Sometimes.... This acts like multithreaded..
        It "Normal" {
            $test = Test-Perf 'woop' { $null = "woopie" ; Start-Sleep -m 10 } -MultipleTest 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'woop'
            $test[0].FullName |Should -Match 'woop'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan 10
        }
        It 'Pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = { $null = "woop";Start-sleep -m 10 }
                MultipleTest = $true
            } | Test-Perf 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            $test[0].FullName |Should -Match 'Value'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan 10 # x 7
        }
        It 'Splat' {
            $hash = @{
                Name = "Value"
                E = { $null = "woop"; Start-sleep -m 10 }
                MultipleTest = $true
            }
            $test = Test-Perf @hash 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            $test[0].FullName |Should -Match 'Value'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan 10 # x7
        }
    }
    
    Context 'SmokeTest Repeat MultipleTest' {
        It "Normal" {
            $test = Test-Perf 'woop' { $null = "woopie" ; Start-Sleep -m 10 } -MultipleTest -Repeat 3 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'woop'
            $test[0].FullName |Should -Match 'woop'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan 30 # x 7
        }
        It 'Pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = { $null = "woop";Start-sleep -m 10}
                MultipleTest = $true
                Repeat = 3
            } | Test-Perf 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            $test[0].FullName |Should -Match 'Value'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan 30 # x 7
        }
        It 'Splat' {
            $hash = @{
                Name = "Value"
                E = { $null = "woop";Start-sleep -m 1}
                MultipleTest = $true
                Repeat = 3
            }
            $test = Test-Perf @hash 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            $test[0].FullName |Should -Match 'Value'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan 30 # x 7
        }
    }
    
    Context 'SmokeTest Single individual MultipleTest' {
        It "Normal" {
            $test = Test-Perf 'woop' { $null = "woopie" ; Start-Sleep -m 5 } -MultipleTest -Individual 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'woop'
            # $test[0].Name |Should -NotMatch 'Ind_'
            $test[0].FullName |Should -Match 'Ind_'
            $test[0].FullName |Should -Match 'woop'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan 5 # x 7
        }
        It 'Pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = { $null = "woop";Start-sleep -m 10}
                MultipleTest = $true
                Individual = $true
            } | Test-Perf 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            # $test[0].Name |Should -NotMatch 'Ind_'
            $test[0].FullName |Should -Match 'Value'
            $test[0].FullName |Should -Match 'Ind_'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan 10 # x 7
        }
        It 'Splat' {
            $hash = @{
                Name = "Value"
                E = { $null = "woop";Start-sleep -m 1}
                MultipleTest = $true
                Individual = $true
            }
            $test = Test-Perf @hash 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            # $test[0].Name |Should -NotMatch 'Ind_'
            $test[0].FullName |Should -Match 'Value'
            $test[0].FullName |Should -Match 'Ind_'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan 1 # x 7
        }
    }

    Context 'SmokeTest Repeat individual MultipleTest' {
        It "Normal" {
            $test = Test-Perf 'woop' { $null = "woopie" ; Start-Sleep -m 5 } -MultipleTest -Individual -Repeat 3 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'woop'
            # $test[0].Name |Should -NotMatch 'Ind_'
            $test[0].FullName |Should -Match 'Ind_'
            $test[0].FullName |Should -Match 'woop'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan 15 # 7
        }
        It 'Pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = { $null = "woop"; Start-sleep -m 5 }
                MultipleTest = $true
                Individual = $true
                Repeat = 3
            } | Test-Perf 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            # $test[0].Name |Should -NotMatch 'Ind_'
            $test[0].FullName |Should -Match 'Value'
            $test[0].FullName |Should -Match 'Ind_'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan 15 # 7
        }
        It 'Splat' {
            $hash = @{
                Name = "Value"
                E = { $null = "woop";Start-sleep -m 5}
                MultipleTest = $true
                Individual = $true
                Repeat = 3
            }
            $test = Test-Perf @hash 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            # $test[0].Name |Should -NotMatch 'Ind_'
            $test[0].FullName |Should -Match 'Value'
            $test[0].FullName |Should -Match 'Ind_'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan 15 # 7
        }
    }
    
    Context 'Acceptance' {
        it 'Multiple of individual' {
            $first = ' test '; $last = 'stand'; $repeats = 10 ;
            $tests = (
                @{Name = 'Format'; ScriptBlock = { [string]::Format('Hello{0}{1}.', $first, $last) } },
                @{Name = 'ConcatPS'; ScriptBlock = { "hello" + "$first" + "$last" } },
                @{Name = 'ConcatPSAsLit'; ScriptBlock = { 'hello' + $first + $last } },
                @{Name = 'DynamicString'; ScriptBlock = { "hello$first$last" } },
                @{Name = 'QuickFormat'; ScriptBlock = { 'Hello{0}{1}.' -f $first, $last } },
                @{Name = 'ConcatC#'; ScriptBlock = { [string]::Concat('hello', $first, $last) } },
                @{Name = 'PS-Join'; ScriptBlock = { "Hello", $first, $last -join "" } }
            ).Foreach{ [pscustomobject]$_ } | Test-Perf -MultipleTest -Repeat $repeats -Individual 6>$null
            $tests.Count |Should -Be 49
            ($tests|Sort-Object  Time -Descending |Select-Object -First 1 -expand Time).Ticks |should -BeGreaterThan 100
        }
    }
}