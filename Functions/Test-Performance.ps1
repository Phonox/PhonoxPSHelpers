Function Test-Performance {
    <#
    .SYNOPSIS
    When you need to test performance for difference things and need to sort them better with name and time
    .DESCRIPTION
    Difference between measure-command and this, is that you will have more data represented to make it easier to analyse difference of psversions or other stuff
    .EXAMPLE
$tests = @( # Difference of nullify output and Instanting arraylist
    @{Name='NullArrayList'   ; ScriptBlock= { $null = [system.collections.ArrayList]::New()   } } ,
    @{Name='VoidArrayList'   ; ScriptBlock= { [void] [system.collections.ArrayList]::New()    } } ,
    @{Name='ArrayListNull'   ; ScriptBlock= { [system.collections.ArrayList]::New() >$null    } } ,
    @{Name='ArrayListOutNull'; ScriptBlock= { [system.collections.ArrayList]::New() |Out-Null } } ,

    @{Name='NullNewObject';    ScriptBlock= { $null = New-Object System.Collections.ArrayList } } ,
    @{Name='VoidNewObject';    ScriptBlock= { [void] (New-Object System.Collections.ArrayList) } } ,
    @{Name='NewObjectToNull';  ScriptBlock= { New-Object System.Collections.ArrayList >$null }  } ,
    @{Name='NewObjectOutNull'; ScriptBlock= { New-Object System.Collections.ArrayList |out-null } } ,
    
    @{Name='NullQuickInstance';    ScriptBlock= { $null = [System.Collections.ArrayList]@() }  } ,
    @{Name='VoidQuickInstance';    ScriptBlock= { [void][System.Collections.ArrayList]@() }  } ,
    @{Name='QuickInstanceToNull';  ScriptBlock= { [System.Collections.ArrayList]@() >$null } } ,
    @{Name='QuickInstanceOutNull'; ScriptBlock= { [System.Collections.ArrayList]@()|out-null }  } ,

    @{Name='NullQuickInstanceNEW';     ScriptBlock= { $null = [System.Collections.ArrayList]::new() } } ,
    @{Name='VoidQuickInstanceNEW';     ScriptBlock= { [void][System.Collections.ArrayList]::new() } } ,
    @{Name='QuickInstanceNEWToNull';   ScriptBlock= { [System.Collections.ArrayList]::new() >$null }  } ,
    @{Name='QuickInstanceNEWOutNull' ; ScriptBlock= { [System.Collections.ArrayList]::new()|out-null } }
).Foreach{ Test-Performance -repeat 10000 @_ } #|Test-Performance -repeat 10000
$tests|sort-object Time

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
.EXAMPLE
$repeats = 1000 # HashTables
# https://ridicurious.com/2019/10/04/11-ways-to-create-hashtable-in-powershell/
$tests = (
    @{Name='NewObjectHash'; ScriptBlock={ $hash = New-Object Hashtable @{} } },
    @{Name='QuickInstance'; ScriptBlock={ $hash = @{} } },
    @{Name='hashTableNEW';  ScriptBlock={ $hash = [hashtable]::new() } },
    @{Name='DictStrStr';    ScriptBlock={ $Dictionary = New-Object 'System.Collections.Generic.Dictionary[String,String]' } },
    @{Name='DictStrInt';    ScriptBlock={ $Dictionary = [System.Collections.Generic.Dictionary[string,int]]::new() } },
    @{Name='NewObject';     ScriptBlock={ $hash = New-Object System.Collections.Hashtable } },
    @{Name='NEWHash';       ScriptBlock={ $Hashtable = [System.Collections.Specialized.OrderedDictionary]::new() } },
    @{Name='HereHash';      ScriptBlock={ $HereHash = @"
name='test'
"@|ConvertFrom-StringData } }
).Foreach{[pscustomobject]$_} |Test-Performance -MultipleTest -Individual -Repeat $repeats |Sort-Object Time
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
        [Alias("Expression")]
        # ScriptBlock or Expression to run
        [ScriptBlock]$ScriptBlock,
        [Parameter(ValueFromPipelineByPropertyName)]
        [int][ValidateScript({$_ -ge 1})]$Repeat = 1,
        [Parameter(ValueFromPipelineByPropertyName)]
        # Run each test individual and see how it's run multiple times. In short, 1..4|foreach {measure-object $scriptblock}|measure-object
        [switch]$Individual,
        # Run each test in a bunch of different loops to see the difference. In short, measure-command { 1..4|foreach { $scriptblock } } but different loops
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$MultipleTest,
        # If you have Measure-Command inside a command, it is possible to use this. But mainly internal use
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$HasLoopsAndMeasureCommand
    )
    Begin{
        $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
        if (!(Get-FormatData -TypeName TestResultsNormal)) {
            $FormatXml = "$PSScriptRoot\..\ps1xml\TestResults.ps1xml"
            Update-FormatData -PrependPath $FormatXml
        }
    }
    Process {
        [system.gc]::Collect()
        $WorkingSetStartOfProcess = (Get-Process -id $PID ).WorkingSet64
        
        if($HasLoopsAndMeasureCommand -and $Individual){
            if ( $ScriptBlock.ToString() -notmatch 'Measure-Command|StopWatch') {Throw 'ScriptBlock REQUIRES a "Measure-Command" to work properly'}
            $times = $ScriptBlock.Invoke()| Measure-Object -Minimum -Maximum -Average -Sum -Property Ticks
            if (!$times) {Throw "Incorrect parameter '-HasLoopsAndMeasureCommand'"}
        }elseif ($MultipleTest) {
            $return = [System.Collections.ArrayList]@()
            if ($Individual) {
                $return = [PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create(  "1..$repeat |Foreach-object { Measure-Command { $ScriptBlock } }" )
                    Name = "|Foreach_$Name"
                },[PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create(  "Foreach( `$i in 1..$repeat ){ Measure-Command { $ScriptBlock } }" )
                    Name = "Foreach(){}_$Name"
                },[PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create(  "(1..$repeat).Foreach{ Measure-Command { $ScriptBlock } }" )
                    Name = ".Foreach{}_$Name"
                },[PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create(  "for(`$ThisUniqueint=0;`$ThisUniqueint -lt $repeat;`$ThisUniqueint++){ Measure-Command { $ScriptBlock } }" )
                    Name = "For_$Name"
                },[PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create( ( "`$ThisUniqueint=0;while(`$ThisUniqueint -lt $repeat){  Measure-Command { $ScriptBlock } ;`$ThisUniqueint++ }" ) )
                    Name = "While_$Name"
                },[PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create( ( "`$ThisUniqueint=0;Do{ Measure-Command { $ScriptBlock } ;`$ThisUniqueint++ }while(`$ThisUniqueint -lt $repeat )" ) )
                    Name = "DoWhile_$Name"
                },[PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create( ( "`$ThisUniqueint=0;Do{ Measure-Command { $ScriptBlock } ;`$ThisUniqueint++ }until(`$ThisUniqueint -ge $repeat )") )
                    Name = "DoUntil_$Name"
                } |Test-Performance -Individual -Repeat $Repeat -HasLoopsAndMeasureCommand

                # $return = (@{
                #     ScriptBlock = [scriptblock]::Create(  "1..$repeat |Foreach-object { Measure-Command { `$InsideWatch = [System.Diagnostics.Stopwatch]::StartNew() ; (& {$ScriptBlock} ) *>`$null ; `$InsideWatch.Stop() ; `$InsideWatch.Elapsed } }" )
                #     Name = "|Foreach_$Name"
                # },@{
                #     ScriptBlock = [scriptblock]::Create(  "Foreach( `$i in 1..$repeat ){ `$InsideWatch = [System.Diagnostics.Stopwatch]::StartNew() ; (& {$ScriptBlock} ) *>`$null ; `$InsideWatch.Stop() ; `$InsideWatch.Elapsed }" )
                #     Name = "Foreach(){}_$Name"
                # },@{
                #     ScriptBlock = [scriptblock]::Create(  "(1..$repeat).Foreach{ `$InsideWatch = [System.Diagnostics.Stopwatch]::StartNew() ; (& {$ScriptBlock} ) *>`$null ; `$InsideWatch.Stop() ; `$InsideWatch.Elapsed }" )
                #     Name = ".Foreach{}_$Name"
                # },@{
                #     ScriptBlock = [scriptblock]::Create(  "for(`$ThisUniqueint=0;`$ThisUniqueint -lt $repeat; `$ThisUniqueint++){ `$InsideWatch = [System.Diagnostics.Stopwatch]::StartNew() ; (& {$ScriptBlock} ) *>`$null ; `$InsideWatch.Stop() ; `$InsideWatch.Elapsed }" )
                #     Name = "For_$Name"
                # },@{
                #     ScriptBlock = [scriptblock]::Create( ( "`$ThisUniqueint=0;while(`$ThisUniqueint -lt $repeat){  `$InsideWatch = [System.Diagnostics.Stopwatch]::StartNew() ; (& {$ScriptBlock} ) *>`$null ; `$InsideWatch.Stop() ; `$InsideWatch.Elapsed;`$ThisUniqueint++ }" ) )
                #     Name = "While_$Name"
                # },@{
                #     ScriptBlock = [scriptblock]::Create( ( "`$ThisUniqueint=0;Do{ `$InsideWatch = [System.Diagnostics.Stopwatch]::StartNew() ; (& {$ScriptBlock} ) *>`$null ; `$InsideWatch.Stop() ; `$InsideWatch.Elapsed ;`$ThisUniqueint++ }while(`$ThisUniqueint -lt $repeat )" ) )
                #     Name = "DoWhile_$Name"
                # },@{
                #     ScriptBlock = [scriptblock]::Create( ( "`$ThisUniqueint=0;Do{ `$InsideWatch = [System.Diagnostics.Stopwatch]::StartNew() ; (& {$ScriptBlock} ) *>`$null ; `$InsideWatch.Stop() ; `$InsideWatch.Elapsed ;`$ThisUniqueint++ }until(`$ThisUniqueint -ge $repeat )") )
                #     Name = "DoUntil_$Name"
                # } ).Foreach{ Test-Performance @_ -Individual -Repeat $Repeat -HasLoopsAndMeasureCommand } |Sort-Object Time 
                return $return
            }else {
                $return = @([PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create(  "1..$repeat |Foreach-object { $ScriptBlock } " )
                    Name = "|Foreach_$Name"
                },[PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create(  "Foreach( `$i in 1..$repeat ){ $ScriptBlock } " )
                    Name = "Foreach(){}_$Name"
                },[PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create(  " (1..$repeat).Foreach{ $ScriptBlock }" )
                    Name = ".Foreach{}_$Name"
                },[PSCustomObject]@{
                    ScriptBlock = [scriptblock]::Create(  "for(`$ThisUniqueint=0;`$ThisUniqueint -le $repeat; `$ThisUniqueint++){ $ScriptBlock ; `$ThisUniqueint++} " )
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
                } |Test-Performance -Individual:$false -Repeat 1 |ForEach-Object {
                    #$_ |Add-Member -NotePropertyName TimesExec -NotePropertyValue $repeat -force -PassThru
                    $_.TimesExec = $repeat ; $_ } )
                #}
                # $return = ( ( @{
                #     ScriptBlock = [scriptblock]::Create( "1..$repeat |Foreach-object { $ScriptBlock } " )
                #     Name = "|Foreach_$Name"
                # },@{
                #     ScriptBlock = [scriptblock]::Create( "Foreach( `$i in 1..$repeat ){ $ScriptBlock } " )
                #     Name = "Foreach(){}_$Name"
                # },@{
                #     ScriptBlock = [scriptblock]::Create( " (1..$repeat).Foreach{ $ScriptBlock }" )
                #     Name = ".Foreach{}_$Name"
                # },@{
                #     ScriptBlock = [scriptblock]::Create( "for(`$ThisUniqueint=0;`$ThisUniqueint -lt $repeat ; `$ThisUniqueint++){ $ScriptBlock } " )
                #     Name = "For_$Name"
                # },@{
                #     ScriptBlock = [scriptblock]::Create( "`$ThisUniqueint=0;while(`$ThisUniqueint -lt $repeat ){ $ScriptBlock ; `$ThisUniqueint++ }" )
                #     Name = "While_$Name"
                # },@{
                #     ScriptBlock = [scriptblock]::Create( "`$ThisUniqueint=0;Do{ $Scriptblock ;`$ThisUniqueint++ }while(`$ThisUniqueint -lt $repeat )" )
                #     Name = "DoWhile_$Name"
                # },@{
                #     ScriptBlock = [scriptblock]::Create( "`$ThisUniqueint=0;Do{ $Scriptblock ;`$ThisUniqueint++ }until(`$ThisUniqueint -ge $repeat )" )
                #     Name = "DoUntil_$Name"
                # } ).ForEach{ Test-Performance @_ -Individual:$false -Repeat 1} ).ForEach{ $_.TimesExec = $repeat ; $_ } |Sort-Object Time
                return $return
            }
        }elseif ($Individual) {
            $FullTest = [System.Diagnostics.Stopwatch]::StartNew()
            $Times = (1..$repeat).ForEach{
                #$NewWatch = [System.Diagnostics.Stopwatch]::StartNew()
                Measure-Command  -expression $ScriptBlock
                #$NewWatch.Stop()
                #$NewWatch.Elapsed
            } | Measure-Object -Minimum -Maximum -Average -Sum -Property Ticks

            # $NewSB = for($ThisUniqueint=0;$ThisUniqueint -lt $repeat;$ThisUniqueint++){ Measure-Command { $ScriptBlock } } | Measure-Object -Minimum -Maximum -Average -Sum -Property Ticks
            # $test = Measure-Command -Expression $NewSB

            #$NewWatch.Stop()
            $FullTest = $FullTest.Stop()
            $name = "Ind_" + $name
            $test = $FullTest.Elapsed
        }elseif ($repeat -eq 1) {
            #$NewWatch = [System.Diagnostics.Stopwatch]::StartNew()
            #$ScriptBlock.Invoke()
            $test = Measure-Command -Expression $ScriptBlock
            #$NewWatch.Stop()
            #$test = $NewWatch.Elapsed
        }else {
            #$NewSB = [scriptblock]::Create( "for(`$ThisUniqueint=0;`$ThisUniqueint -lt $repeat;`$ThisUniqueint++){ (& {$ScriptBlock} ) *>`$null }")
            #$NewWatch = [System.Diagnostics.Stopwatch]::StartNew()
            #[void] (& $NewSB)
            $NewSB = [ScriptBlock]::Create( "for(`$ThisUniqueint=0;`$ThisUniqueint -lt $repeat;`$ThisUniqueint++){ $ScriptBlock }")
            $test = Measure-Command $NewSB
            #foreach ($item in 1..$repeat) { $ScriptBlock.Invoke() }
            #$NewWatch.Stop()
            #$test = $NewWatch.Elapsed
        }
        if ($isWindows)   { $OS = "Win" }
        elseif ($IsMacOS) { $OS = "Mac" }
        elseif ($Islinux) { $OS = "Linux" }
        else              { $OS = "Win" }
        
        $FullName = $Name
        if ( $Name -match '(?<ind>Ind)?_?(?<loop>\|Foreach|Foreach\(\)\{\}|\.Foreach\{\}|for|while|DoWhile|DoUntil)_(?<orgName>.*)' ) {
            $loop = $Matches.loop
            $Name = $matches.orgName
            if ($Individual) {
                $FullName = "Ind_$FullName"
                $TypeName = "TestResultsIndividualMultiTest"
            }else {
                $TypeName = 'TestResultsMultipleTest'
            }
        }elseif($Individual -and -not $MultipleTest){
            $TypeName = "TestResultsIndividual"
        }else{$TypeName = "TestResultsNormal"}
        
        $hash = [Ordered]@{
            PSTypeName = $TypeName
            FullName = $FullName
            Name = $Name
            Time = $test
        }
        $hash.TimesExec = $Repeat
        if ($loop) {$hash.Loop = $loop}
        $hash.PSVersion = $PSVersionTable.PSVersion.ToString()
        $hash.OS = $OS
        $hash.CLR = if ($isCoreCLR){"CoreCLR"}elseif($psISE){"ISE"}else{$PSVersionTable.PSEdition.ToString() }
        if ($Individual) {
            $hash.Max = [TimeSpan]::FromTicks( $times.Maximum )
            $hash.Min = [TimeSpan]::FromTicks( $times.Minimum )
            $hash.Avg = [TimeSpan]::FromTicks( $Times.Average )
            $hash.Time= [TimeSpan]::FromTicks( $Times.Sum )
        }
        
        $Hash.WorkSet = ( ( Get-Process -id $PID ).WorkingSet64 - $WorkingSetStartOfProcess )
        return ( [PSCustomObject]$hash )
    }
    End{ 
        $StopWatch.Stop()
        if ($MultipleTest){
            Write-Information "Total time $( $StopWatch.Elapsed )" -InformationAction Continue
        }else{
            Write-Information "Total time $( $StopWatch.Elapsed )"
        }
        # GC Collect is required on MacOS For now
        [system.gc]::Collect()
    }
}
Export-ModuleMember -Function Test-Performance