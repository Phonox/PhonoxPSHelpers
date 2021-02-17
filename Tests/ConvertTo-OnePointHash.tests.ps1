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

$first100 = 1..100 |ForEach-Object {
    [PSCustomObject]@{
        id = "$_"
        random = Get-Random 
    }
}

Describe -Tags "ConvertTo-OnePointHash","UnitTest" "ConvertTo-OnePointHash" {
    It 'Should handle pipeline input' {
        $test = $first100 |ConvertTo-OnePointHash -id id -SkipCheck
        $test."5".random |Should -BeGreaterThan 1
    }
    It 'Should an array of objects' {
        $test = ConvertTo-OnePointHash -array $first100 -id id -SkipCheck
        $test."5".random |Should -BeGreaterThan 1
    }
    $first100 |ForEach-Object {$_.id = "4"}
    It "Should throw error when encountering same ID" {
        { $null = ConvertTo-OnePointHash -array $first100 -id id } | Should -Throw 'UniqueID Is not Unique! Tried to overwrite 4, Add -OverWrite as parameter to continue'
    }
    It "Overwrite will not throw errors when encountered same ID" {
        $test = ConvertTo-OnePointHash -array $first100 -id id -OverWrite
        $test.keys.count |Should -be 1
    }
}
Describe -Tags 'Performance',"PT","ConvertTo-OnePointHash" 'Performance ConvertTo-OnePointHash' {
    $data = 1..3000 |ForEach-Object {
        [PSCustomObject]@{
            id = "$_"
            random = Get-Random 
        }
    }

    Context "-SkipCheck is faster, sample $($data.count)" {
        It "-SkipCheck in pipeline" {
            $Original = measure-command { $data | ConvertTo-OnePointHash -UniqueID ID -OverWrite }
            $Skipped  = measure-command { $data | ConvertTo-OnePointHash -UniqueID ID -SkipCheck }
            $OT = $Original.TotalMilliseconds
            $ST = $Skipped.TotalMilliseconds
            $proc = [math]::Round( ($Original.TotalMilliseconds / $Skipped.TotalMilliseconds),2) * 100 - 100
            Write-Host "$proc % faster versus if it didn't made sure it did not exist, $ot`ms vs $st`ms"
            $Skipped.TotalMilliseconds -lt $Original.TotalMilliseconds |should -BeTrue
        }
        It "-SkipCheck, as array input" {
            $Original = measure-command { ConvertTo-OnePointHash -UniqueID ID -Array $data -OverWrite }
            $Skipped  = measure-command { ConvertTo-OnePointHash -UniqueID ID -Array $data -SkipCheck }
            $OT = $Original.TotalMilliseconds
            $ST = $Skipped.TotalMilliseconds
            $proc = [math]::Round( ($Original.TotalMilliseconds / $Skipped.TotalMilliseconds),2) * 100 - 100
            Write-Host "$proc % faster versus if it didn't made sure it did not exist, $ot`ms vs $st`ms"
            $Skipped.TotalMilliseconds -lt $Original.TotalMilliseconds |should -BeTrue
        }
    }
}