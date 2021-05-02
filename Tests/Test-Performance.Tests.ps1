
Describe 'Testrun of Test-Performance' {
    Context 'SmokeTest Single' {
        It 'Test-Performance should be similar to normal code' {
            $repeat = 100
            $ShouldBe = Measure-Command {
                for($int=1;$int -lt $repeat; $int++) {
                    [void] [System.Collections.ArrayList]@()
                }
            }
            $moduleTest = Test-Performance -Name "moduleTest" -ScriptBlock { [void] [System.Collections.ArrayList]@() } -Repeat $repeat
            $moduletest.time.ticks | Should -BeLessOrEqual ($ShouldBe.Ticks * 2)
        }
    }
}

Describe 'Singlets' {
    BeforeAll {
        $ms = 15
        $repeat = 1
        $AcceptedRangeMulti = 2
        $SB = [scriptblock]::Create( "`$null = 'woopie' ; Start-Sleep -m $ms")
        $ExpectedLessThan = ($ms * $Repeat * $AcceptedRangeMulti )
    }
    Context 'Single tests' {
        It "Normal" {
            $test = Test-Performance 'woop' -ScriptBlock $sb
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Name |Should -BeExactly 'woop'
            $test.Time.TotalMilliseconds |should -BeGreaterThan ($ms * $Repeat)
            $test.Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Should be possible to pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = $sb
            } |Test-Performance
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Name |Should -BeExactly 'Value'
            $test.Time.TotalMilliseconds |should -BeGreaterThan ($ms * $Repeat)
            $test.Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Should be possible to Splat' {
            $hash = @{
                Name = "Value"
                E = $sb
            }
            $test = Test-Performance @hash
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Name |Should -BeExactly 'Value'
            $test.Time.TotalMilliseconds |should -BeGreaterThan ($ms * $Repeat)
            $test.Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
    }

    Context 'SmokeTest Single Individual' {
        It "Normal" {
            $test = Test-Performance 'woop' -ScriptBlock $sb -Individual
            $test.Name |Should -BeExactly 'Ind_woop'
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Time.TotalMilliseconds |should -BeGreaterThan ($ms * $Repeat)
            $test.Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = $sb
                Individual = $true
            } |Test-Performance
            $test.Name |Should -BeExactly 'Ind_Value'
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Time.TotalMilliseconds |should -BeGreaterThan ($ms * $Repeat)
            $test.Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Splat' {
            $hash = @{
                Name = "Value"
                E = $sb
                Individual = $true
            }
            $test = Test-Performance @hash
            $test.Name |Should -BeExactly 'Ind_Value'
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Time.TotalMilliseconds |should -BeGreaterThan ($ms * $Repeat)
            $test.Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
    }
    
    Context 'SmokeTest Single MultipleTest' {
        It "Normal" {
            $test = Test-Performance 'woop' $sb -MultipleTest 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'woop'
            $test[0].FullName |Should -Match 'woop'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan ($ms * $Repeat)
            $test[0].Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = $sb
                MultipleTest = $true
            } | Test-Performance 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            $test[0].FullName |Should -Match 'Value'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan ($ms * $Repeat)
            $test[0].Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Splat' {
            $hash = @{
                Name = "Value"
                E = $SB
                MultipleTest = $true
            }
            $test = Test-Performance @hash 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            $test[0].FullName |Should -Match 'Value'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan ($ms * $Repeat)
            $test[0].Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
    }
    
    Context 'SmokeTest Single individual MultipleTest' {
        It "Normal" {
            $test = Test-Performance 'woop' -ScriptBlock $sb -MultipleTest -Individual 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'woop'
            $test[0].FullName |Should -Match 'Ind_'
            $test[0].FullName |Should -Match 'woop'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan ($ms * $Repeat)
            $test[0].Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = $SB
                MultipleTest = $true
                Individual = $true
            } | Test-Performance 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            $test[0].FullName |Should -Match 'Value'
            $test[0].FullName |Should -Match 'Ind_'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan ($ms * $Repeat)
            $test[0].Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Splat' {
            $hash = @{
                Name = "Value"
                E = $SB
                MultipleTest = $true
                Individual = $true
            }
            $test = Test-Performance @hash 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            $test[0].FullName |Should -Match 'Value'
            $test[0].FullName |Should -Match 'Ind_'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan ($ms * $Repeat)
            $test[0].Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
    }

    
}
Describe 'repeaters' {
    BeforeAll {
        $ms = 15
        $repeat = 3
        $AcceptedRangeMulti = 2
        $SB = [scriptblock]::Create( "`$null = 'woopie' ; Start-Sleep -m $ms")
        $ExpectedLessThan = ($ms * $Repeat * $AcceptedRangeMulti )
        $ExpectedMoreThan = ($ms * $Repeat)
    }
    Context 'SmokeTest Repeat' {
        It "Normal" {
            $test = Test-Performance 'woop' -ScriptBlock $SB -Repeat $repeat
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Name |Should -BeExactly 'woop'
            $test.Time.TotalMilliseconds |should -BeGreaterThan $ExpectedMoreThan
            $test.Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Should be possible to pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = $SB
                Repeat = $Repeat
            } |Test-Performance
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Name |Should -BeExactly 'Value'
            $test.Time.TotalMilliseconds |should -BeGreaterThan $ExpectedMoreThan
            $test.Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Should be possible to Splat' {
            $hash = @{
                Name = "Value"
                E = $SB
                Repeat =  $Repeat
            }
            $test = Test-Performance @hash
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Name |Should -BeExactly 'Value'
            $test.Time.TotalMilliseconds |should -BeGreaterThan $ExpectedMoreThan
            $test.Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
    }

    Context 'SmokeTest Repeat MultipleTest' {
        It "Normal" {
            $test = Test-Performance 'woop' -ScriptBlock $sb -MultipleTest -Repeat $Repeat 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'woop'
            $test[0].FullName |Should -Match 'woop'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan $ExpectedMoreThan
            $test[0].Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = $sb
                MultipleTest = $true
                Repeat = $repeat
            } | Test-Performance 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            $test[0].FullName |Should -Match 'Value'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan $ExpectedMoreThan
            $test[0].Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Splat' {
            $hash = @{
                Name = "Value"
                E = $SB
                MultipleTest = $true
                Repeat = $Repeat
            }
            $test = Test-Performance @hash 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            $test[0].FullName |Should -Match 'Value'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan $ExpectedMoreThan
            $test[0].Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
    }

    Context 'SmokeTest Repeat Individual' {
        It "Normal" {
            $test = Test-Performance 'woop' -ScriptBlock $SB -Individual -Repeat $Repeat
            $test.Name |Should -BeExactly 'Ind_woop'
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Time.TotalMilliseconds |should -BeGreaterThan $ExpectedMoreThan
            $test.Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = $SB
                Individual = $true
                Repeat = $repeat
            } |Test-Performance
            $test.Name |Should -BeExactly 'Ind_Value'
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Time.TotalMilliseconds |should -BeGreaterThan $ExpectedMoreThan
            $test.Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Splat' {
            $hash = @{
                Name = "Value"
                E = $SB
                Individual = $true
                Repeat = $repeat
            }
            $test = Test-Performance @hash
            $test.Name |Should -BeExactly 'Ind_Value'
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Time.TotalMilliseconds |should -BeGreaterThan $ExpectedMoreThan
            $test.Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
    }

    Context 'SmokeTest Repeat individual MultipleTest' {
        It "Normal" {
            $test = Test-Performance 'woop' -ScriptBlock $SB -MultipleTest -Individual -Repeat $repeat 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'woop'
            $test[0].FullName |Should -Match 'Ind_'
            $test[0].FullName |Should -Match 'woop'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan $ExpectedMoreThan
            $test[0].Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = $SB
                MultipleTest = $true
                Individual = $true
                Repeat = $repeat
            } | Test-Performance 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            $test[0].FullName |Should -Match 'Value'
            $test[0].FullName |Should -Match 'Ind_'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan $ExpectedMoreThan
            $test[0].Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Splat' {
            $hash = @{
                Name = "Value"
                E = $SB
                MultipleTest = $true
                Individual = $true
                Repeat = $repeat
            }
            $test = Test-Performance @hash 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            $test[0].FullName |Should -Match 'Value'
            $test[0].FullName |Should -Match 'Ind_'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan $ExpectedMoreThan
            $test[0].Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
    }
}
Describe 'Last test' {
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
            ).Foreach{ [pscustomobject]$_ } | Test-Performance -MultipleTest -Repeat $repeats -Individual 6>$null
            $tests.Count |Should -Be 49
            ($tests|Sort-Object  Time -Descending |Select-Object -First 1 -expand Time).Ticks |should -BeGreaterThan 100
        }
    }
}