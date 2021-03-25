Function Test-Performance {
    <#
    .SYNOPSIS
    When you need to test performance for difference things and need to sort them better with name and time
    .EXAMPLE
$tests = @()
$tests += Test-Performance NewObject {$null = New-Object System.Collections.ArrayList} -repeat 10000
$tests += Test-Performance QuickInstance {$null = [System.Collections.ArrayList]@() }  -repeat 10000
$tests += Test-Performance NewObject {$null = New-Object System.Collections.ArrayList} -repeat 10000 -Individual
$tests += Test-Performance QuickInstance {$null = [System.Collections.ArrayList]@() }  -repeat 10000 -Individual
$tests |sort-object time| ft -auto name,time
#old result
Name           : QuickInstance
Time           : 00:00:00.0236146
PSVersionTable : 7.1.2
OS             : Mac
IsCoreCLR      : True

Name           : NewObject
Time           : 00:00:00.2914788
PSVersionTable : 7.1.2
OS             : Mac
IsCoreCLR      : True
#New result
Name                  Time
----                  ----
Individ_QuickInstance 00:00:00.0000137
Individ_NewObject     00:00:00.0002060
QuickInstance         00:00:00.1542165
NewObject             00:00:03.4727676
.EXAMPLE
$FC = 100000
$all = Get-ChildItem / -Recurse -ea SilentlyContinue | Select-Object -first $FC

$date = [datetime]::now.AddDays(-30)
$obj = @()
$obj += [pscustomobject]@{ Name = '|ForEach-Object' ; OutputOfRepeat = $FC ; SB =  {$all | ForEach-Object { If ($_.CreationTime -gt $date) {$_} } } }
$obj += [pscustomobject]@{ Name = 'ForEach(){}' ; OutputOfRepeat = $FC ; SB = {foreach ($f in $all) { If ($f.CreationTime -gt $date) {$f} } } }
$obj += [pscustomobject]@{ Name = '.ForEach({})'; OutputOfRepeat = $FC ; SB = {$all.ForEach({ If ($_.CreationTime -gt $date) {$_} } ) } }
$obj += [pscustomobject]@{ Name = '|Where {}'   ; OutputOfRepeat = $FC ; SB = {$all | Where-Object { $_.CreationTime -gt $date } } }
$obj += [pscustomobject]@{ Name = '|Where prop -gt a' ; OutputOfRepeat = $FC ; SB = {$all | Where-Object CreationTime -gt $date } }
$obj += [pscustomobject]@{ Name = '.Where({})'  ; OutputOfRepeat = $FC ; SB = {$all.where({ $_.CreationTime -gt $date } ) } }
$obj += [pscustomobject]@{ Name = '.Where{}'    ; OutputOfRepeat = $FC ; SB = {$all.where{ $_.CreationTime -gt $date } } }
$obj += [pscustomobject]@{ Name = 'For(){}'     ; OutputOfRepeat = $FC ; SB = { for($int=0;$int -lt ($all.count - 1 );$int++ ) { If ($_.CreationTime -gt $date) {$_} } } }
$obj += [pscustomobject]@{ Name = 'While(){}'   ; OutputOfRepeat = $FC ; SB = { $int=0 ; while( $int -lt ($FC -1) ) { If ($all[$int].CreationTime -gt $date) { $all[$int] } ; $int++ } } }
$obj += [pscustomobject]@{ Name = 'Do{}While()' ; OutputOfRepeat = $FC ; SB = { $int=0 ; Do{ If ($all[$int].CreationTime -gt $date) { $all[$int] } ; $int++ }while ( $int -lt ($FC -1) ) } }
$obj += [pscustomobject]@{ Name = 'Do{}Until()' ; OutputOfRepeat = $FC ; SB = { $int=0 ; Do{ If ($all[$int].CreationTime -gt $date) { $all[$int] } ; $int++ }Until ( $int -ge ($FC -1) ) } }
$tests = $obj| Test-Performance
$tests |sort-object time| ft -auto
Name              Time             TimesExec PSVersionTable OS  IsCoreCLR
----              ----             --------- -------------- --  ---------
ForEach(){}       00:00:00.3978124         1 7.1.2          Mac      True
For(){}           00:00:00.5766949         1 7.1.2          Mac      True
While(){}         00:00:00.7870029         1 7.1.2          Mac      True
Do{}Until()       00:00:00.8515368         1 7.1.2          Mac      True
Do{}While()       00:00:00.8762461         1 7.1.2          Mac      True
.Where({})        00:00:01.0015900         1 7.1.2          Mac      True
.Where{}          00:00:01.0218861         1 7.1.2          Mac      True
.ForEach({})      00:00:01.1318803         1 7.1.2          Mac      True
|ForEach-Object   00:00:02.3790807         1 7.1.2          Mac      True
|Where prop -gt a 00:00:03.8548739         1 7.1.2          Mac      True
|Where {}         00:00:04.5049549         1 7.1.2          Mac      True
    #>
    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0)]
        [string]$Name,
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline, Position = 1)]
        [ScriptBlock]$SB,
        [Parameter(ValueFromPipelineByPropertyName)]
        [int]$Repeat = 1,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$Individual,
        [int]$OutputOfRepeat,
        [switch]$MultipleTest
    )
    Process {
        if ($MultipleTest) {
            $return = @()
            if ($Individual) {
                $NewSB = [scriptblock]::Create(  "1..$repeat |Foreach-object { Measure-Command {$sb} }" )
                $return += Test-Performance -Individual:$false -Name "|Foreach_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1

                $NewSB = [scriptblock]::Create(  "Foreach( `$i in 1..$repeat ){ Measure-Command {$sb} }" )
                $return += Test-Performance -Individual:$false -Name "Foreach(){}_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1

                $NewSB = [scriptblock]::Create(  "(1..$repeat).Foreach{ Measure-Command {$sb} }" )
                $return += Test-Performance -Individual:$false -Name ".Foreach{}_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1

                $NewSB = [scriptblock]::Create(  "for(`$int=0;`$int -lt `$repeat; `$int++){Measure-Command {$sb} }" )
                $return += Test-Performance -Individual:$false -Name "For_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1
                return $return
            }
            else {
                $NewSB = [scriptblock]::Create(  "Measure-Command { 1..$repeat |Foreach-object { $sb } }" )
                $return += Test-Performance -Individual:$false -Name "|Foreach_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1

                $NewSB = [scriptblock]::Create(  "Measure-Command { Foreach( `$i in 1..$repeat ){ $sb } }" )
                $return += Test-Performance -Individual:$false -Name "Foreach(){}_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1

                $NewSB = [scriptblock]::Create(  "Measure-Command { (1..$repeat).Foreach{ $sb } }" )
                $return += Test-Performance -Individual:$false -Name ".Foreach{}_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1

                $NewSB = [scriptblock]::Create(  "Measure-Command { for(`$int=0;`$int -lt `$repeat; `$int++){$sb} }" )
                $return += Test-Performance -Individual:$false -Name "For_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1
                return $return
            }
        }
        if ($Individual) {

            $Times = (1..$repeat | Foreach-object { Measure-Command $sb } ) | Measure-Object -Minimum -Maximum -Average -Property TotalMilliseconds
            $name = "Individ_" + $name

            $test = [TimeSpan]::FromMilliseconds( $times.Average )
        }
        else {
            $NewSB = [scriptblock]::Create( "1..$repeat|foreach-object {$sb}")
            $test = Measure-Command $NewSB
        }
        if ($isWindows) { $OS = "Win" }
        elseif ($IsMacOS) { $OS = "Mac" }
        elseif ($Islinux) { $OS = "Linux" }
        else { $OS = "Win" }

        $hash = [Ordered]@{
            Name = $Name
            Time = $test
        }
        if ($Individual) { $hash.Maximum = $times.Maximum ; $hash.Minimum = $times.Minimum }
        if ($OutputOfRepeat) {
            $hash.TimesExec = $OutputOfRepeat
        }
        else {
            $hash.TimesExec = $Repeat
        }

        $hash.PSVersionTable = $PSVersionTable.PSVersion.ToString()
        $hash.OS = $OS
        $hash.IsCoreCLR = [bool]$IsCoreCLR
        return ( [PSCustomObject]$hash )
    }
}
# Export-ModuleMember -Function Test-Performance