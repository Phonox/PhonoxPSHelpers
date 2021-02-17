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

Describe "Prompt" -Tags "Prompt","UT" {

}
Describe 'Performance of PROMPT' -Tags "Prompt","PT" {
    $int = 5
    $lessOrEqual = 20
    It "Prompt $int`x times should have an avg. faster than $lessOrEqual`ms" {    
        $TMS = [int]( ( Measure-Command { 1..$int | Foreach-object { prompt *>&1 | Out-Null } } ).Milliseconds / ($int ) ) 
        Write-Warning "Total avg. ms. $TMS"
        $TMS | Should -BeLessOrEqual $lessOrEqual
    }
}
