Function Test-Performance {
    <#
    .SYNOPSIS
    When you need to test performance for difference things and need to sort them better with name and time
    .DESCRIPTION
    Next update will use
    $StopWatch = new-object system.diagnostics.stopwatch
    $StopWatch.Start()
    $StopWatch.Stop()
    .EXAMPLE
$tests = @()
$tests += Test-Performance NullNewObject {$null = New-Object System.Collections.ArrayList} -repeat 10000
$tests += Test-Performance VoidNewObject {[void] (New-Object System.Collections.ArrayList)} -repeat 10000
$tests += Test-Performance NewObjectToNull {New-Object System.Collections.ArrayList >$null} -repeat 10000
$tests += Test-Performance NewObjectOutNull {New-Object System.Collections.ArrayList |out-null} -repeat 10000
$tests += Test-Performance NullQuickInstance {$null = [System.Collections.ArrayList]@() }  -repeat 10000
$tests += Test-Performance VoidQuickInstance {[void][System.Collections.ArrayList]@() }  -repeat 10000
$tests += Test-Performance QuickInstanceToNull {[System.Collections.ArrayList]@()>$null }  -repeat 10000
$tests += Test-Performance QuickInstanceOutNull {[System.Collections.ArrayList]@()|out-null }  -repeat 10000
tests|sort-object Time

Time             TimesExec PSVersion OS    CLR       Name
----             --------- --------- --    ---       ----
00:00:00.0182133 10000     7.1.2     Mac   CoreCLR   NullQuickInstance
00:00:00.0223108 10000     7.1.2     Mac   CoreCLR   VoidQuickInstance
00:00:00.0233962 10000     7.1.2     Mac   CoreCLR   QuickInstanceToNull
00:00:00.1373704 10000     7.1.2     Mac   CoreCLR   QuickInstanceOutNull
00:00:01.4301883 10000     7.1.2     Mac   CoreCLR   NewObjectToNull
00:00:01.5437808 10000     7.1.2     Mac   CoreCLR   NullNewObject
00:00:01.5835206 10000     7.1.2     Mac   CoreCLR   VoidNewObject
00:00:02.3174948 10000     7.1.2     Mac   CoreCLR   NewObjectOutNull
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
$tests |sort-Object Time

Time             TimesExec PSVersion OS    CLR       Name
----             --------- --------- --    ---       ----
00:00:00.3652091 1         7.1.2     Mac   CoreCLR   ForEach(){}
00:00:00.4320338 1         7.1.2     Mac   CoreCLR   For(){}
00:00:00.6659127 1         7.1.2     Mac   CoreCLR   Do{}While()
00:00:00.6707612 1         7.1.2     Mac   CoreCLR   Do{}Until()
00:00:00.7027150 1         7.1.2     Mac   CoreCLR   While(){}
00:00:00.8048381 1         7.1.2     Mac   CoreCLR   .ForEach({})
00:00:00.8819230 1         7.1.2     Mac   CoreCLR   .Where({})
00:00:00.8847392 1         7.1.2     Mac   CoreCLR   .Where{}
00:00:02.0740560 1         7.1.2     Mac   CoreCLR   |ForEach-Object
00:00:03.9906460 1         7.1.2     Mac   CoreCLR   |Where prop -gt a
00:00:05.2068952 1         7.1.2     Mac   CoreCLR   |Where {}
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
Total time 00:00:10.5552250
$tests|sort-object Time |select -First 5

Time             TimesExec PSVersion OS    CLR       Min              Max              Avg              Name
----             --------- --------- --    ---       ---              ---              ---              ----
00:00:00.0169476 1000      7.1.2     Mac   CoreCLR   00:00:00.0000154 00:00:00.0001668 00:00:00.0000169 .Foreach{}_DynamicString
00:00:00.0177663 1000      7.1.2     Mac   CoreCLR   00:00:00.0000157 00:00:00.0001684 00:00:00.0000177 .Foreach{}_ConcatPSAsLit
00:00:00.0177968 1000      7.1.2     Mac   CoreCLR   00:00:00.0000159 00:00:00.0001694 00:00:00.0000177 For_QuickFormat
00:00:00.0179939 1000      7.1.2     Mac   CoreCLR   00:00:00.0000160 00:00:00.0001708 00:00:00.0000179 Foreach(){}_DynamicString
00:00:00.0180146 1000      7.1.2     Mac   CoreCLR   00:00:00.0000162 00:00:00.0001660 00:00:00.0000180 DoWhile_DynamicString

$tests|sort-object Time |select -Last 2 

Time             TimesExec PSVersion OS    CLR       Min              Max              Avg              Name
----             --------- --------- --    ---       ---              ---              ---              ----
00:00:00.0463787 1000      7.1.2     Mac   CoreCLR   00:00:00.0000160 00:00:00.0057914 00:00:00.0000463 While_QuickFormat
00:00:00.2277168 1000      7.1.2     Mac   CoreCLR   00:00:00.0000266 00:00:00.1231455 00:00:00.0002277 While_PS-Join

....and much MUCH MORE! (total of 49 rows)
    #>
    [CmdletBinding()]
    #[OutputType([TestResultsIndividual],[TestResultsNormal])]
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
        [Alias("Expression")]
        # ScriptBlock or Expression to run
        [ScriptBlock]$ScriptBlock,
        [Parameter(ValueFromPipelineByPropertyName)]
        [int][ValidateScript({$_ -ge 1})]$Repeat = 1,
        [Parameter(ValueFromPipelineByPropertyName)]
        # Run each test individual and see how it's run multiple times. In short, 1..4|foreach {measure-object $scriptblock}|measure-object
        [switch]$Individual,
        # Run each test in a bunch of different loops to see the difference. In short, measure-command { 1..4|foreach { $scriptblock } } but different loops
        [switch]$MultipleTest,
        # If you have Measure-Command inside a command, it is possible to use this. But mainly internal use
        [switch]$HasLoopsAndMeasureCommand
    )
    Begin{
        $Start = [datetime]::now
        if (!(Get-FormatData -TypeName TestResultsNormal)) {
            $FormatXml = "$PSScriptRoot\..\ps1xml\TestResults.ps1xml"
            Update-FormatData -PrependPath $FormatXml
        }
    }
    Process {
        if($HasLoopsAndMeasureCommand -and $Individual){
            if ( $ScriptBlock.ToString() -notmatch 'Measure-Command') {Throw 'ScriptBlock REQUIRES a "Measure-Command" to work properly'}
            $times = Invoke-Command $ScriptBlock | Measure-Object -Minimum -Maximum -Average -Sum -Property TotalMilliseconds
            if (!$times) {Throw "Incorrect parameter '-HasLoopsAndMeasureCommand'"}
        }elseif ($MultipleTest) {
            $return = [System.Collections.ArrayList]@()
            if ($Individual) {
                # $NewSB = [scriptblock]::Create(  "1..$repeat |Foreach-object { Measure-Command {$ScriptBlock} }" )
                $return = [PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create(  "1..$repeat |Foreach-object { Measure-Command {$ScriptBlock} }" )
                    Name = "|Foreach_$Name"
                },[PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create(  "Foreach( `$i in 1..$repeat ){ Measure-Command {$ScriptBlock} }" )
                    Name = "Foreach(){}_$Name"
                },[PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create(  "(1..$repeat).Foreach{ Measure-Command {$ScriptBlock} }" )
                    Name = ".Foreach{}_$Name"
                },[PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create(  "for(`$ThisUniqueint=0;`$ThisUniqueint -lt $repeat; `$ThisUniqueint++){Measure-Command {$ScriptBlock} }" )
                    Name = "For_$Name"
                },[PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create( ( "`$ThisUniqueint=0;while(`$ThisUniqueint -lt $repeat){ measure-command { $ScriptBlock };`$ThisUniqueint++ }" ) )
                    Name = "While_$Name"
                },[PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create( ( "`$ThisUniqueint=0;Do{ Measure-Command { $ScriptBlock } ;`$ThisUniqueint++ }while(`$ThisUniqueint -lt $repeat )" ) )
                    Name = "DoWhile_$Name"
                },[PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create( ( "`$ThisUniqueint=0;Do{ Measure-Command { $ScriptBlock } ;`$ThisUniqueint++ }until(`$ThisUniqueint -ge $repeat )") )
                    Name = "DoUntil_$Name"
                } |Test-Performance -Individual -Repeat $Repeat -HasLoopsAndMeasureCommand
                return $return
            }
            else {
                $return = [PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create(  "1..$repeat |Foreach-object { $ScriptBlock } " )
                    Name = "|Foreach_$Name"
                },[PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create(  "Foreach( `$i in 1..$repeat ){ $ScriptBlock } " )
                    Name = "Foreach(){}_$Name"
                },[PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create(  " (1..$repeat).Foreach{ $ScriptBlock }" )
                    Name = ".Foreach{}_$Name"
                },[PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create(  "for(`$ThisUniqueint=0;`$ThisUniqueint -le $repeat; `$ThisUniqueint++){$ScriptBlock ; `$ThisUniqueint++} " )
                    Name = "For_$Name"
                },[PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create( "`$ThisUniqueint=0;while(`$ThisUniqueint -lt $repeat ){ $ScriptBlock ; `$ThisUniqueint++ }" )
                    Name = "While_$Name"
                },[PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create( ( "`$ThisUniqueint=0;Do{ $scriptblock ;`$ThisUniqueint++ }while(`$ThisUniqueint -lt $repeat )") )
                    Name = "DoWhile_$Name"
                },[PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create( ( "`$ThisUniqueint=0;Do{ $scriptblock ;`$ThisUniqueint++ }until(`$ThisUniqueint -ge $repeat )") )
                    Name = "DoUntil_$Name"
                } |Test-Performance -Individual:$false -Repeat 1 |ForEach-Object {$_.TimesExec = $repeat ; $_}
                return $return
            }
        }
        elseif ($repeat -eq 1) {
            $test = Measure-Command $ScriptBlock
        }elseif ($Individual) {
            $ThisStart = [datetime]::Now
            $Times = (1..$repeat | Foreach-object { Measure-Command $ScriptBlock } ) | Measure-Object -Minimum -Maximum -Average -Sum -Property TotalMilliseconds
            $name = "Individ_" + $name
            $test = [datetime]::Now - $ThisStart
        }else {
            $NewSB = [scriptblock]::Create( "for(`$ThisUniqueint=0;`$ThisUniqueint -lt $repeat;`$ThisUniqueint++){$ScriptBlock}")
            $test = Measure-Command $NewSB
        }
        if ($isWindows)   { $OS = "Win" }
        elseif ($IsMacOS) { $OS = "Mac" }
        elseif ($Islinux) { $OS = "Linux" }
        else              { $OS = "Win" }

        if($Individual){$TypeName = "TestResultsIndividual"}else{$TypeName = "TestResultsNormal"}
        $hash = [Ordered]@{
            PSTypeName = $TypeName
            Name = $Name
            Time = $test
        }
        $hash.TimesExec = $Repeat

        $hash.PSVersion = $PSVersionTable.PSVersion.ToString()
        $hash.OS = $OS
        $hash.CLR = if ($isCoreCLR){"CoreCLR"}elseif($psISE){"ISE"}else{$PSVersionTable.PSEdition.ToString()}
        if ($Individual) { 
            $hash.Max = [TimeSpan]::FromMilliseconds( $times.Maximum )
            $hash.Min = [TimeSpan]::FromMilliseconds( $times.Minimum )
            $hash.Avg = [TimeSpan]::FromMilliseconds( $Times.Average )
            $hash.Time= [TimeSpan]::FromMilliseconds( $Times.Sum )
        }
        return ( [PSCustomObject]$hash )
    }
    End{ if ($MultipleTest){ write-host "Total time" ( ([datetime]::now) -$start).tostring() } }
}
Export-ModuleMember -Function Test-Performance