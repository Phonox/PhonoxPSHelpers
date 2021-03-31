
Describe 'Testrun of Test-performance' {
    Context 'SmokeTest Single' {
        It "Normal" {
            $test = Test-Performance 'woop' { "woopie" ; Start-Sleep -m 10 }
            $test.count |Should -BeExactly 1
            $test.Name |Should -BeExactly 'woop'
            $test.Time.TotalMilliseconds |should -BeGreaterThan 10
        }
        It 'Should be possible to pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = {"woop";Start-sleep -m 10}
            } |Test-Performance
            $test.count |Should -BeExactly 1
            $test.Name |Should -BeExactly 'Value'
            $test.Time.TotalMilliseconds |should -BeGreaterThan 10
        }
        It 'Should be possible to Splat' {
            $hash = @{
                Name = "Value"
                E = {"woop";Start-sleep -m 10}
            }
            $test = Test-Performance @hash
            $test.count |Should -BeExactly 1
            $test.Name |Should -BeExactly 'Value'
            $test.Time.TotalMilliseconds |should -BeGreaterThan 10
        }
    }

    Context 'SmokeTest MultipleTest' { # Sometimes.... this can go as low as 4 whilst it should be 7..
        It "Normal" {
            $test = Test-Performance 'woop' { "woopie" ; Start-Sleep -m 1 } -MultipleTest 6>$null
            $test.count |Should -BeExactly 7
            $test.Name |Should -Match 'woop'
            # $test.Name |Should -Match 'While'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan 4 # 7
        }
        It 'Pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = {"woop";Start-sleep -m 1}
                MultipleTest = $true
            } | Test-Performance 6>$null
            $test.count |Should -BeExactly 7
            $test.Name |Should -Match 'Value'
            # $test.Name |Should -Match 'While'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan 4 # 7
        }
        It 'Splat' {
            $hash = @{
                Name = "Value"
                E = {"woop";Start-sleep -m 1}
                MultipleTest = $true
            }
            $test = Test-Performance @hash 6>$null
            $test.count |Should -BeExactly 7
            $test.Name |Should -Match 'Value'
            # $test.Name |Should -Match 'While'
            $test[0].Time.TotalMilliseconds |should -BeGreaterThan 4 # 7
        }
    }
    
    Context 'SmokeTest Single Individual' {
        It "Normal" {
            $test = Test-Performance 'woop' { "woopie" ; start-sleep -m 10 } -Individual
            $test.Name |Should -BeExactly 'Ind_woop'
            $test.count |Should -BeExactly 1
            $test.Time.TotalMilliseconds |should -BeGreaterThan 10
        }
        It 'Pipe' {
            $test = [PSCustomObject]@{
                Name = "Value"
                E = {"woop";Start-sleep -m 10}
                Individual = $true
            } |Test-Performance
            $test.Name |Should -BeExactly 'Ind_Value'
            $test.count |Should -BeExactly 1
            $test.Time.TotalMilliseconds |should -BeGreaterThan 10
        }
        It 'Splat' {
            $hash = @{
                Name = "Value"
                E = {"woop";Start-sleep -m 10}
                Individual = $true
            }
            $test = Test-Performance @hash
            $test.Name |Should -BeExactly 'Ind_Value'
            $test.count |Should -BeExactly 1
            $test.Time.TotalMilliseconds |should -BeGreaterThan 10
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
            ).Foreach{ [pscustomobject]$_ } | Test-Performance -MultipleTest -Repeat $repeats -Individual 6>$null
            $tests.Count |Should -Be 49
            ($tests|Sort-Object  Time -Descending |Select-Object -First 1 -expand Time).Ticks |should -BeGreaterThan 100
        }
    }
}