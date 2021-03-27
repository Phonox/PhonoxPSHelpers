Function Test-Performance {
    <#
    .SYNOPSIS
    When you need to test performance for difference things and need to sort them better with name and time
    .EXAMPLE
$tests = @()
$tests += Test-Performance NullNewObject {$null = New-Object System.Collections.ArrayList} -repeat 10000
$tests += Test-Performance VoidNewObject {[void] (New-Object System.Collections.ArrayList)} -repeat 10000
$tests += Test-Performance VoidNewObject {New-Object System.Collections.ArrayList >$null} -repeat 10000
$tests += Test-Performance VoidNewObject {New-Object System.Collections.ArrayList |out-null} -repeat 10000
$tests += Test-Performance NullQuickInstance {$null = [System.Collections.ArrayList]@() }  -repeat 10000
$tests += Test-Performance VoidQuickInstance {[void][System.Collections.ArrayList]@() }  -repeat 10000
$tests += Test-Performance QuickInstanceNull {[System.Collections.ArrayList]@()>$null }  -repeat 10000
$tests += Test-Performance QuickInstanceOutNull {[System.Collections.ArrayList]@()|out-null }  -repeat 10000
$tests += Test-Performance NewObject {$null = New-Object System.Collections.ArrayList} -repeat 10000 -Individual
$tests += Test-Performance QuickInstance {$null = [System.Collections.ArrayList]@() }  -repeat 10000 -Individual
$tests |sort-object time| ft -auto
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
.EXAMPLE
$first= ' test ';$last='stand';$repeats =1000 ;
$tests = (
    @{Name='Format';       ScriptBlock={[string]::Format('Hello{0}{1}.',$first,$last)}},
    @{Name='ConcatPS';     ScriptBlock={"hello" + "$first" + "$last" }},
    @{Name='ConcatPSAsLit';ScriptBlock={'hello' + $first + $last }},
    @{Name='DynamicString';ScriptBlock={"hello$first$last" }},
    @{Name='QuickFormat';  ScriptBlock={'Hello{0}{1}.' -f $first, $last} },
    @{Name='ConcatC#';     ScriptBlock={[string]::Concat('hello',$first,$last) } },
    @{Name='PS-Join';      ScriptBlock={"Hello",$first,$last -join ""} }
).Foreach{[pscustomobject]$_} |Test-Performance -MultipleTest -Repeat $repeats -Individual
$tests |Sort-Object Time |Format-Table -AutoSize
$tests |Sort-Object TotalTime |Format-Table -AutoSize
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    Param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0)]
        [Alias("N")]
        [string]$Name,
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline, Position = 1)]
        [Alias("SB")]
        [Alias("E")]
        [ScriptBlock]$ScriptBlock,
        [Parameter(ValueFromPipelineByPropertyName)]
        [int][ValidateScript({$_ -gt 0})]$Repeat = 1,
        [Parameter(ValueFromPipelineByPropertyName)]
        # Run each test individual and see how it's run multiple times. In short, 1..4|foreach {measure-object $scriptblock}|measure-object
        [switch]$Individual,
        [int]$OutputOfRepeat,
        # Run each test in a bunch of different loops to see the difference. In short, measure-command { 1..4|foreach { $scriptblock } } but different loops
        [switch]$MultipleTest
    )
    Begin{$Start = [datetime]::now}
    Process {
        if ($MultipleTest) {
            $return = [System.Collections.ArrayList]@()
            if ($Individual) {
                $NewSB = [scriptblock]::Create(  "1..$repeat |Foreach-object { Measure-Command {$ScriptBlock} }" )
                $ThisStart = [datetime]::now
                $thisTest = Test-Performance -Individual:$false -Name "|Foreach_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1
                $end = ([datetime]::now) - $ThisStart

                $thisTest  | Add-Member -NotePropertyName TotalTime -NotePropertyValue $end
                [void]$return.Add( $thisTest )

                $NewSB = [scriptblock]::Create(  "Foreach( `$i in 1..$repeat ){ Measure-Command {$ScriptBlock} }" )
                $ThisStart = [datetime]::now
                $thisTest = Test-Performance -Individual:$false -Name "Foreach(){}_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1
                $end = ([datetime]::now) - $ThisStart
                $thisTest  | Add-Member -NotePropertyName TotalTime -NotePropertyValue $end
                [void]$return.Add( $thisTest )

                $NewSB = [scriptblock]::Create(  "(1..$repeat).Foreach{ Measure-Command {$ScriptBlock} }" )
                $start = [datetime]::now
                $thisTest = Test-Performance -Individual:$false -Name ".Foreach{}_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1
                $end = ([datetime]::now) - $ThisStart
                $thisTest  | Add-Member -NotePropertyName TotalTime -NotePropertyValue $end
                [void]$return.Add( $thisTest )

                $NewSB = [scriptblock]::Create(  "for(`$ThisUniqueint=0;`$ThisUniqueint -lt `$repeat; `$ThisUniqueint++){Measure-Command {$ScriptBlock} }" )
                $start = [datetime]::now
                $thisTest =Test-Performance -Individual:$false -Name "For_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1
                $end = ([datetime]::now) - $ThisStart
                $thisTest  | Add-Member -NotePropertyName TotalTime -NotePropertyValue $end
                [void]$return.Add( $thisTest )

                $NewSB = [scriptblock]::Create( ( "`$ThisUniqueint=0;while(`$ThisUniqueint -lt $repeat){ measure-command { $ScriptBlock };`$ThisUniqueint++ }" ) )
                $start = [datetime]::now
                $thisTest =Test-Performance -Individual:$false -Name "While_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1
                $end = ([datetime]::now) - $ThisStart
                $thisTest  | Add-Member -NotePropertyName TotalTime -NotePropertyValue $end
                [void]$return.Add( $thisTest )

                $NewSB = [scriptblock]::Create( ( "`$ThisUniqueint=0;Do{ Measure-Command { $ScriptBlock } ;`$ThisUniqueint++ }while(`$ThisUniqueint -lt $repeat )" ) )
                $start = [datetime]::now
                $thisTest =Test-Performance -Individual:$false -Name "DoWhile_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1
                $end = ([datetime]::now) - $ThisStart
                $thisTest  | Add-Member -NotePropertyName TotalTime -NotePropertyValue $end
                [void]$return.Add( $thisTest )

                $NewSB = [scriptblock]::Create( ( "`$ThisUniqueint=0;Do{Measure-Command { $ScriptBlock } ;`$ThisUniqueint++ }until(`$ThisUniqueint -ge $repeat )") )
                $start = [datetime]::now
                $thisTest =Test-Performance -Individual:$false -Name "DoUntil_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1
                $end = ([datetime]::now) - $ThisStart
                $thisTest  | Add-Member -NotePropertyName TotalTime -NotePropertyValue $end
                [void]$return.Add( $thisTest )
                return $return
            }
            else {
                $NewSB = [scriptblock]::Create(  "Measure-Command { 1..$repeat |Foreach-object { $ScriptBlock } }" )
                [void]$return.Add( ( Test-Performance -Individual:$false -Name "|Foreach_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1 ))

                $NewSB = [scriptblock]::Create(  "Measure-Command { Foreach( `$i in 1..$repeat ){ $ScriptBlock } }" )
                [void]$return.Add( ( Test-Performance -Individual:$false -Name "Foreach(){}_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1 ))

                $NewSB = [scriptblock]::Create(  "Measure-Command { (1..$repeat).Foreach{ $ScriptBlock } }" )
                [void]$return.Add( ( Test-Performance -Individual:$false -Name ".Foreach{}_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1 ))

                $NewSB = [scriptblock]::Create(  "Measure-Command { for(`$ThisUniqueint=0;`$ThisUniqueint -lt `$repeat; `$ThisUniqueint++){$ScriptBlock ; `$ThisUniqueint++} }" )
                [void]$return.Add( ( Test-Performance -Individual:$false -Name "For_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1 ))

                $NewSB = [scriptblock]::Create( ( '$ThisUniqueint=0;while($ThisUniqueint -lt {0} ){ {1} } }' -f $repeat,$ScriptBlock ) )
                $start = [datetime]::now
                $thisTest =Test-Performance -Individual:$false -Name "While_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1
                $end = ([datetime]::now) - $ThisStart
                $thisTest  | Add-Member -NotePropertyName TotalTime -NotePropertyValue $end
                [void]$return.Add( $thisTest )

                $NewSB = [scriptblock]::Create( ( "`$ThisUniqueint=0;Do{ $scriptblock ;`$ThisUniqueint++ }while(`$ThisUniqueint -lt {0} )") )
                $start = [datetime]::now
                $thisTest =Test-Performance -Individual:$false -Name "DoWhile_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1
                $end = ([datetime]::now) - $ThisStart
                $thisTest  | Add-Member -NotePropertyName TotalTime -NotePropertyValue $end
                [void]$return.Add( $thisTest )

                $NewSB = [scriptblock]::Create( ( "`$ThisUniqueint=0;Do{ $scriptblock ;`$ThisUniqueint++ }until(`$ThisUniqueint -ge $repeat )") )
                $start = [datetime]::now
                $thisTest =Test-Performance -Individual:$false -Name "DoUntil_$Name" -OutputOfRepeat $Repeat -SB $NewSB -MultipleTest:$false -repeat 1
                $end = ([datetime]::now) - $ThisStart
                $thisTest  | Add-Member -NotePropertyName TotalTime -NotePropertyValue $end
                [void]$return.Add( $thisTest )
                return $return
            }
        }
        if ($Individual) {
            $ThisStart = [datetime]::Now
            $Times = (1..$repeat | Foreach-object { Measure-Command $ScriptBlock } ) | Measure-Object -Minimum -Maximum -Average -Property TotalMilliseconds
            $name = "Individ_" + $name
            $ThisEnd = [datetime]::Now - $ThisStart
            $test = [TimeSpan]::FromMilliseconds( $times.Average )
        }elseif ($repeat -eq 1) {
            $test = Measure-Command $ScriptBlock
        }
        else {
            $NewSB = [scriptblock]::Create( "for(`$ThisUniqueint=0;`$ThisUniqueint -lt $repeat;`$ThisUniqueint++){$ScriptBlock}")
            $test = Measure-Command $NewSB
        }
        if ($isWindows)   { $OS = "Win" }
        elseif ($IsMacOS) { $OS = "Mac" }
        elseif ($Islinux) { $OS = "Linux" }
        else              { $OS = "Win" }

        $hash = [Ordered]@{
            Name = $Name
            Time = $test
        }
        if ($OutputOfRepeat) {
            $hash.TimesExec = $OutputOfRepeat
        }
        else {
            $hash.TimesExec = $Repeat
        }

        $hash.PSVersion = $PSVersionTable.PSVersion.ToString()
        $hash.OS = $OS
        $hash.CRL = if ($isCoreCLR){"CoreCLR"}elseif($psISE){"ISE"}else{$PSVersionTable.PSEdition.ToString()}
        if ($Individual){ $hash.TotalTime = $ThisEnd}
        if ($Individual) { $hash.Maximum = $times.Maximum ; $hash.Minimum = $times.Minimum }
        return ( [PSCustomObject]$hash )
    }
    End{ if ($MultipleTest){ write-host "Total time" ( ([datetime]::now) -$start).tostring() } }
}
Export-ModuleMember -Function Test-Performance