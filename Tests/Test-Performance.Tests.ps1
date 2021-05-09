
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
        $Samples = 2
        $AcceptedRangeMulti = 2
        $SB = [scriptblock]::Create( "`$null = 'woopie' ; Start-Sleep -m $ms")
        $ExpectedLessThan = ($ms * $Repeat * $AcceptedRangeMulti )
        $SamplesExpectedLessThan = ($ms * $Repeat * $AcceptedRangeMulti *  $Samples )
        $ExpectedGreaterOrEqual = ($ms * $repeat * 0.9)
        $SamplesExpectedMoreThan = ($ms * $repeat * 0.9 * $Samples)
    }
    Context 'Single tests' {
        It "Normal" {
            $test = Test-Performance 'woop' -ScriptBlock $sb
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Name |Should -BeExactly 'woop'
            $test.Time.TotalMilliseconds |should -BeGreaterOrEqual $ExpectedGreaterOrEqual
            $test.Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Should be possible to pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = $sb
            } |Test-Performance
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Name |Should -BeExactly 'Value'
            $test.Time.TotalMilliseconds |should -BeGreaterOrEqual $ExpectedGreaterOrEqual
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
            $test.Time.TotalMilliseconds |should -BeGreaterOrEqual $ExpectedGreaterOrEqual
            $test.Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
    }

    Context 'SmokeTest Single Samples' {
        It "Normal" {
            $test = Test-Performance 'woop' -ScriptBlock $sb -Samples $Samples
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Time.TotalMilliseconds |should -BeGreaterOrEqual $SamplesExpectedMoreThan
            $test.Time.TotalMilliseconds |should -BeLessThan $SamplesExpectedLessThan
        }
        It 'Pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = $sb
                Samples = $Samples
            } |Test-Performance
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Time.TotalMilliseconds |should -BeGreaterOrEqual $SamplesExpectedMoreThan
            $test.Time.TotalMilliseconds |should -BeLessThan $SamplesExpectedLessThan
        }
        It 'Splat' {
            $hash = @{
                Name = "Value"
                E = $sb
                Samples = $Samples
            }
            $test = Test-Performance @hash
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Time.TotalMilliseconds |should -BeGreaterOrEqual $SamplesExpectedMoreThan
            $test.Time.TotalMilliseconds |should -BeLessThan $SamplesExpectedLessThan
        }
    }
    
    Context 'SmokeTest Single RunInDifferentLoops' {
        It "Normal" {
            $test = Test-Performance 'woop' $sb -RunInDifferentLoops 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'woop'
            $test[0].FullName |Should -Match 'woop'
            $test[0].Time.TotalMilliseconds |should -BeGreaterOrEqual $ExpectedGreaterOrEqual
            $test[0].Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = $sb
                RunInDifferentLoops = $true
            } | Test-Performance 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            $test[0].FullName |Should -Match 'Value'
            $test[0].Time.TotalMilliseconds |should -BeGreaterOrEqual $ExpectedGreaterOrEqual
            $test[0].Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Splat' {
            $hash = @{
                Name = "Value"
                E = $SB
                RunInDifferentLoops = $true
            }
            $test = Test-Performance @hash 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            $test[0].FullName |Should -Match 'Value'
            $test[0].Time.TotalMilliseconds |should -BeGreaterOrEqual $ExpectedGreaterOrEqual
            $test[0].Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
    }
    
    Context 'SmokeTest Single Samples RunInDifferentLoops' {
        It "Normal" {
            $test = Test-Performance 'woop' -ScriptBlock $sb -RunInDifferentLoops -Samples $Samples 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'woop'
            $test[0].FullName |Should -Match 'woop'
            $test[0].Time.TotalMilliseconds |should -BeGreaterOrEqual $SamplesExpectedMoreThan
            $test[0].Time.TotalMilliseconds |should -BeLessThan $SamplesExpectedLessThan
        }
        It 'Pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = $SB
                RunInDifferentLoops = $true
                Samples = $Samples
            } | Test-Performance 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            $test[0].FullName |Should -Match 'Value'
            $test[0].Time.TotalMilliseconds |should -BeGreaterOrEqual $SamplesExpectedMoreThan
            $test[0].Time.TotalMilliseconds |should -BeLessThan $SamplesExpectedLessThan
        }
        It 'Splat' {
            $hash = @{
                Name = "Value"
                E = $SB
                RunInDifferentLoops = $true
                Samples = $Samples
            }
            $test = Test-Performance @hash 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            $test[0].FullName |Should -Match 'Value'
            $test[0].Time.TotalMilliseconds |should -BeGreaterOrEqual $SamplesExpectedMoreThan
            $test[0].Time.TotalMilliseconds |should -BeLessThan $SamplesExpectedLessThan
        }
    }
}
Describe 'repeaters' {
    BeforeAll {
        $ms = 15
        $repeat = 3
        $Samples = 2
        $AcceptedRangeMulti = 2
        $SB = [scriptblock]::Create( "`$null = 'woopie' ; Start-Sleep -m $ms")
        $ExpectedLessThan = ($ms * $Repeat * $Samples * $AcceptedRangeMulti)
        $ExpectedMoreThan = ($ms * $Repeat)
        $SamplesExpectedMoreThan = ($ms * $Repeat * $Samples)
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

    Context 'SmokeTest Repeat RunInDifferentLoops' {
        It "Normal" {
            $test = Test-Performance 'woop' -ScriptBlock $sb -RunInDifferentLoops -Repeat $Repeat 6>$null
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
                RunInDifferentLoops = $true
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
                RunInDifferentLoops = $true
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

    Context 'SmokeTest Repeat Samples' {
        It "Normal" {
            $test = Test-Performance 'woop' -ScriptBlock $SB -Samples $Samples -Repeat $Repeat
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Time.TotalMilliseconds |should -BeGreaterThan $SamplesExpectedMoreThan
            $test.Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = $SB
                Samples = $Samples
                Repeat = $repeat
            } |Test-Performance
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Time.TotalMilliseconds |should -BeGreaterThan $SamplesExpectedMoreThan
            $test.Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Splat' {
            $hash = @{
                Name = "Value"
                E = $SB
                Samples = $Samples
                Repeat = $repeat
            }
            $test = Test-Performance @hash
            ($test | Measure-Object).count |Should -BeExactly 1
            $test.Time.TotalMilliseconds |should -BeGreaterThan $SamplesExpectedMoreThan
            $test.Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
    }

    Context 'SmokeTest Repeat Samples RunInDifferentLoops' {
        It "Normal" {
            $test = Test-Performance 'woop' -ScriptBlock $SB -RunInDifferentLoops -Samples $Samples -Repeat $repeat 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'woop'
            $test[0].FullName |Should -Match 'woop'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan $SamplesExpectedMoreThan
            $test[0].Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = $SB
                RunInDifferentLoops = $true
                Samples = $Samples
                Repeat = $repeat
            } | Test-Performance 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            $test[0].FullName |Should -Match 'Value'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan $SamplesExpectedMoreThan
            $test[0].Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
        It 'Splat' {
            $hash = @{
                Name = "Value"
                E = $SB
                RunInDifferentLoops = $true
                Samples = $Samples
                Repeat = $repeat
            }
            $test = Test-Performance @hash 6>$null
            ($test | Measure-Object).count |Should -BeExactly 7
            $test[0].Name |Should -BeExactly 'Value'
            $test[0].FullName |Should -Match 'Value'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan $SamplesExpectedMoreThan
            $test[0].Time.TotalMilliseconds |should -BeLessThan $ExpectedLessThan
        }
    }
}
Describe 'Last test' {
    Context 'Acceptance' {
        it 'Multiple of Samples' {
            $first = ' test '; $last = 'stand'; $repeats = 10 ;
            $tests = (
                @{Name = 'Format'; ScriptBlock = { [string]::Format('Hello{0}{1}.', $first, $last) } },
                @{Name = 'ConcatPS'; ScriptBlock = { "hello" + "$first" + "$last" } },
                @{Name = 'ConcatPSAsLit'; ScriptBlock = { 'hello' + $first + $last } },
                @{Name = 'DynamicString'; ScriptBlock = { "hello$first$last" } },
                @{Name = 'QuickFormat'; ScriptBlock = { 'Hello{0}{1}.' -f $first, $last } },
                @{Name = 'ConcatC#'; ScriptBlock = { [string]::Concat('hello', $first, $last) } },
                @{Name = 'PS-Join'; ScriptBlock = { "Hello", $first, $last -join "" } }
            ).Foreach{ [pscustomobject]$_ } | Test-Performance -RunInDifferentLoops -Repeat $repeats -Samples 2 6>$null
            $tests.Count |Should -Be 49
            ($tests|Sort-Object  Time -Descending |Select-Object -First 1 -expand Time).Ticks |should -BeGreaterThan 100
        }
    }
}