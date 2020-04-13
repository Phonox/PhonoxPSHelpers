#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '4.9.0' }
$modulename = "PhonoxsPSHelpers"
$sut = $PSCommandPath -replace '\.tests\.ps1$', '.psd1'

if ( !(gmo $modulename) ) { 
    Import-Module $PSScriptRoot -Force ; 
    $imported = $true 
}else {
    $imported = $false
    Remove-Module $modulename
    Import-Module $PSScriptRoot
}
Import-LocalizedData -BaseDirectory $PSScriptRoot -FileName "$modulename.psd1" -BindingVariable data

describe 'Testing module manifest $modulename' {
    Context "ModuleManifest" {
        $Manifest = Test-ModuleManifest $sut 
        It "Should have a correct formated manifest" {
            $Manifest | should -BeTrue
        }
        # WIP
        #It "Should have atleast 10 exported functions" {
        #    $Manifest.ExportedFunctions.count | Should -BeGreaterThan 10
        #}
    }
    Context 'All NestedModules exists'{
        # WIP To get performance
        #It "should include a NestedModules" {
        #    $countedFiles = (gci $PSScriptRoot -file -Recurse |? {$_.name -notmatch "$modulename"} ).count
        #    $data.NestedModules.count | Should -BeGreaterThan $countedFiles
        #}
        foreach ( $path in $data.NestedModules ){
            It "Exists: $path" {
                (Join-Path $PSScriptRoot $_) | should -Exist
            }
        }
    }
    Context 'All FileList exists'{
        # WIP To get performance
        #It "should include a FileList" {
        #    $countedFiles = (gci $PSScriptRoot -file -Recurse |? {$_.name -notmatch "$modulename"} ).count
        #    $data.FileList.count | Should -BeGreaterThan $countedFiles
        #}
        foreach ( $path in $data.FileList){
            It "File should exist: $path" {
                (Join-Path $PSScriptRoot $_) | should -Exist
            }
        }
    }
    Context 'All ModuleListexists'{
    
        foreach ( $path in $data.ModuleListexists ){
            It "$path should exist" {
                (Join-Path $PSScriptRoot $_) | should -Exist
            }
        }
    }
    $allCommands = Get-Command -module $modulename -CommandType Function
    Context 'All functions have help'{
        foreach ( $path in $allCommands ){
            It "Helpfile with SYNOPSIS should exist for $path" {
                [bool](get-command $path -ShowCommandInfo |? Definition -match 'SYNOPSIS') |should -be "True"
            }
        }
    }
    Context 'Functions...' {
        It "should exist 11 functions" {
            $allCommands.count |should -Be 12
        }
    }
    Context 'Performance..' {
        $int = 5
        $lessOrEqual= 20
        It "Prompt $int`x times should have an avg. faster than $lessOrEqual`ms" {    
            $TMS = [int]( ( Measure-Command {0..$int | % { prompt *>&1 | Out-Null } } ).Milliseconds / ($int +1) ) 
            Write-Warning "Total avg. ms. $TMS"
            $TMS | Should -BeLessOrEqual $lessOrEqual
        }
    }
}
if ($imported) {Remove-Module $modulename}