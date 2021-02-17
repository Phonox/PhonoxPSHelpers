#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '4.9.0' }
$ScriptPath = $PSScriptRoot
$ModuleName = ( Split-Path $PSCommandPath -Leaf ) -replace '\.tests\.ps1$'
$File = "$ModuleName.psd1"
$FilePath = Convert-Path (Join-Path $ScriptPath $File)
if ( !(test-path $FilePath ) ) { Write-Error "Failed to find file" }
$TestFolderPath = Join-Path $ScriptPath "Tests"


Describe "Importing module" -Tags "Module" {
    Context "It should be no errors importing" {
        It "Importing should not result with any issues" {
            if ( !(Get-Module $modulename) ) { 
                { Import-Module $ScriptPath -Force -ea stop -DisableNameChecking 4>$null 3>$null } | Should -Not -Throw
                #$imported = $true 
            }
            else {
                #$imported = $false
                Remove-Module $modulename -Force
                { Import-Module $ScriptPath -Force -ea stop -DisableNameChecking 4>$null 3>$null } | Should -Not -Throw
            }
        }
        It "No errors should occour" {
            $Error.Clear()
            if ( !(Get-Module $modulename) ) { 
                Import-Module $ScriptPath -Force -DisableNameChecking 4>$null 3>$null
            }
            else {
                Remove-Module $modulename -Force
                Import-Module $ScriptPath -Force -ea stop -DisableNameChecking 4>$null 3>$null
            }
            prompt *>$null
            Start-Sleep -m 50
            Write-Warning "$($Error.Count)"
            $Error.Count | Should -Be 0
        }
    }
    # import required

    $allCommands = Get-Command -module $modulename -CommandType Function
    Context 'All functions have help' {
        foreach ( $path in $allCommands ) {
            It "SYNOPSIS should exist for $path" {
                [bool](get-command $path -ShowCommandInfo | Where-Object Definition -match 'SYNOPSIS') | should -be "True"
            }
        }
    }
    Context 'All functions should have a test file each' {
        $AllFiles = Get-ChildItem -File ( Join-Path $ScriptPath "Functions" ) | Select-Object -expand Name | ForEach-Object { $_ -replace '\.ps1', '.tests.ps1' }
        foreach ( $path in $AllFiles ) {
            $testFile = Join-Path $TestFolderPath $Path
            $testFileExists = Test-Path $testFile
            if ($testFileExists) {
                It "Testfile exists for: $path" {    
                    $testFileExists | Should -BeTrue
                }
                It "All tests should have Describe: $path" {
                    $testFile |should -FileContentMatch "Describe"
                }
                It "All tests should have tags: $path" {
                    $testFile |should -FileContentMatch "-Tags"
                }
            }else {
                It "Testfile exists for: $path" {    
                    Set-ItResult -Skipped -Because "they haven't been created yet"
                }
            }
        }
    }
    Context 'Functions...' {
        It "should exist atleast 18 functions" {
            ($allCommands.count) | should -BeGreaterOrEqual 18
        }
    }
    
}
Import-LocalizedData -BaseDirectory $ScriptPath -FileName "$modulename.psd1" -BindingVariable data

describe "Testing module manifest $ModuleName" {
    Context "ModuleManifest" {
        It "Should have a correct formated manifest" {
            #$Manifest = (Test-ModuleManifest $FilePath)
            #write-host -ForegroundColor Magenta $FilePath
            #write-host -ForegroundColor Magenta $ModuleName
            (Test-ModuleManifest $FilePath).Name | should -Be $ModuleName
        }
        It "Manifest should exist" {
            $FilePath | Should -Exist 
        }
        # WIP
        It "Should have atleast 10 exported functions" {
            Set-ItResult -Skipped -Because "feature has not been created"
            $Manifest.ExportedFunctions.count | Should -BeGreaterThan 10
        }
    }
    Context 'All NestedModules exists' {
        # WIP To get performance
        It "should include a NestedModules" {
            Set-ItResult -Skipped -Because "feature has not been created"
            #$countedFiles = (gci $PSScriptRoot -file -Recurse |? {$_.name -notmatch "$modulename"} ).count
            #$data.NestedModules.count | Should -BeGreaterThan $countedFiles
        }
        foreach ( $path in $data.NestedModules ) {
            It "Exists: $path" {
                (Join-Path $PSScriptRoot $_) | should -Exist
            }
        }
    }
    Context 'All FileList exists'{
        # WIP To get performance
        It "should include a FileList" {
            Set-ItResult -Skipped -Because "feature has not been created"
            #$countedFiles = (Get-ChildItem $PSScriptRoot -file -Recurse |Where-Object {$_.name -notmatch "$modulename"} ).count
            #$data.FileList.count | Should -BeGreaterThan $countedFiles
        }
        foreach ( $path in $data.FileList){
            It "File should exist: $path" {
                Set-ItResult -Skipped -Because "feature has not been created"
                #(Join-Path $PSScriptRoot $_) | should -Exist
            }
        }
    }
    Context 'All ModuleListexists' {
        foreach ( $path in $data.ModuleListexists ) {
            It "$path should exist" {
                (Join-Path $PSScriptRoot $_) | should -Exist
            }
        }
    }
}