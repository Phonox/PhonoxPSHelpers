$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
#. "$here\$sut"

Remove-Module PhonoxsPSHelpers -Force ; Import-Module .\OneDrive\Development\Powershell\PhonoxsPSHelpers -DisableNameChecking

$num = 20 # 59 is about the maximum
[int](measure-command { 0..$num| % { prompt } } |select -ExpandProperty Milliseconds ) / ($num + 1)
[int](measure-command { 0..$num| % { Update-PersistentData } } |select -ExpandProperty Milliseconds ) / ($num + 1)
[int](measure-command { 0..$num| % { Set-PersistentData kalas "$_"} } |select -ExpandProperty Milliseconds ) / ($num + 1)



$pathBigBagOfShit = "$env:TEMP\bigbagofshit.csv"
Describe "PersistentData" {
    It "BigBagOfShit.csv should exist"{
        $pathBigBagOfShit | should -exist
    }
    $cat = cat $pathBigBagOfShit
    It "Saved variables to disk and imported are counted equal" {
        $BigBagOfData.count |should -Be ($cat.count -1)
    }
    $VariableName = "TestVariable"
    $VariableValue = "awdawdawdawdawd"
    $DataType = "STRING"
    It "Should contain $DataType $VariableName" {
        Set-PersistentData $VariableName $VariableValue
        $pathBigBagOfShit |Should -FileContentMatch $VariableName
        $pathBigBagOfShit |Should -FileContentMatch $VariableValue
        $pathBigBagOfShit |Should -FileContentMatch $DataType
    }
    It "Should NOT change an $DataType at update" {
        [bool]( ( Update-PersistentData -Verbose *>&1 ) -match "Changed`: $VariableName" ) | Should -Be $false
    }
    It "Should not contain $DataType TestVariable" {
        Remove-PersistentData $VariableName
        $pathBigBagOfShit |Should -FileContentMatch "[^($VariableName)]"
        $pathBigBagOfShit |Should -FileContentMatch "[^($VariableName.*$VariableValue)]"
        $pathBigBagOfShit |Should -FileContentMatch "[^($VariableName.*$DataType)]"
    }
    $VariableValue = 12312
    $DataType = "INT"
    It "Should contain INT $VariableName" {
        Set-PersistentData $VariableName $VariableValue
        $pathBigBagOfShit |Should -FileContentMatch $VariableName
        $pathBigBagOfShit |Should -FileContentMatch $VariableValue
        $pathBigBagOfShit |Should -FileContentMatch $DataType
    }
    It "Should NOT change an $DataType at update" {
        [bool]( ( Update-PersistentData -Verbose *>&1 ) -match "Changed`: $VariableName" ) | Should -Be $false
    }
    It "Should not contain INT TestVariable" {
        Remove-PersistentData $VariableName
        $pathBigBagOfShit |Should -FileContentMatch "[^($VariableName)]"
        $pathBigBagOfShit |Should -FileContentMatch "[^($VariableName.*$VariableValue)]"
        $pathBigBagOfShit |Should -FileContentMatch "[^($VariableName.*$DataType)]"
    }
    $VariableValue = Get-Date
    $DataType = "DateTime"
    It "Should contain $DataType $VariableName" {
        Set-PersistentData $VariableName $VariableValue
        $pathBigBagOfShit |Should -FileContentMatch $VariableName
        $pathBigBagOfShit |Should -FileContentMatch $VariableValue
        $pathBigBagOfShit |Should -FileContentMatch $DataType
    }
    It "Should NOT change an $DataType at update" {
        [bool]( ( Update-PersistentData -Verbose *>&1 ) -match "Changed`: $VariableName" ) | Should -Be $false
    }
    It "Should not contain $DataType VariableName" {
        Remove-PersistentData $VariableName
        $pathBigBagOfShit |Should -FileContentMatch "[^($VariableName)]"
        $pathBigBagOfShit |Should -FileContentMatch "[^($VariableName.*$VariableValue)]"
        $pathBigBagOfShit |Should -FileContentMatch "[^($VariableName.*$DataType)]"
    }
    $VariableValue = "TestVariable1","TestVariable2"
    $DataType = 'STRING\[\]'
    It "Should contain $DataType $VariableName" {
        Set-PersistentData $VariableName $VariableValue
        $pathBigBagOfShit |Should -FileContentMatch $VariableName
        $pathBigBagOfShit |Should -FileContentMatch "$VariableName.*$($VariableValue[0])"
        $pathBigBagOfShit |Should -FileContentMatch $DataType
    }
    #WIP
    It "Should NOT change an $DataType at update" {
        [bool]( ( Update-PersistentData -Verbose *>&1 ) -match "Changed`: $VariableName" ) | Should -Be $false
    }
    It "Should not contain $DataType $VariableName" {
        Remove-PersistentData $VariableName
        $pathBigBagOfShit |Should -FileContentMatch "[^($VariableName)]"
        $pathBigBagOfShit |Should -FileContentMatch "[^($VariableName.*$DataType)]"
    }
    #WIP
    $VariableValue = 321321,123123
    $DataType = 'INT\[\]'
    It "Should contain $DataType $VariableName" {
        Set-PersistentData $VariableName $VariableValue
        $pathBigBagOfShit |Should -FileContentMatch $VariableName
        $pathBigBagOfShit |Should -FileContentMatch "$VariableName.*$($VariableValue[0])"
        $pathBigBagOfShit |Should -FileContentMatch $DataType
    }
    #WIP
    It "Should NOT change an $DataType at update" {
        [bool]( ( Update-PersistentData -Verbose *>&1 ) -match "Changed`: $VariableName" ) | Should -Be $false
    }
    It "Should not contain $DataType $VariableName" {
        Remove-PersistentData $VariableName
        $pathBigBagOfShit |Should -FileContentMatch "[^($VariableName)]"
        $pathBigBagOfShit |Should -FileContentMatch "[^($VariableName.*$DataType)]"
    }
}
