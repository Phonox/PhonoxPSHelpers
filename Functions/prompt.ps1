#$zxc = { param ($ForegroundColor)  Write-Host "$('>' * ($nestedPromptLevel + 1)) " -ForegroundColor $ForegroundColor }
#$asd = {param($test) $test * 5} ; . $asd -test 5 ; . $asd -test asd


Function Global:prompt {
    <#
    .Synopsis
        Made a cooler prompt
    .DESCRIPTION
        Created a prompt with more features on it, might require some more time..
        Old version:
        PS v. 5.1 Console takes avg. 15ms
        PS v. 5.1 ISE takes avg. 86ms
        PS v. 7.0 Console takes avg. 17ms
        New Version.... unknown, but should take more time as PersistentData is revampt to do more things(but less searching)
        New version has (get-history).Count in the prompt as well
        PS v. 5.1 Console avg time 12ms (but every 5, it took 25ms)
        PS v. 5.1 ISE     avg time 18-25ms
        PS v. 7.0 Console avg time 13ms
    #>
    Begin {
        #if ( !( Get-Command Prompt_BoolLastCommand -ea ignore ) ) {}
    }
    Process {
        Prompt_SetLastRunCommand
        $PPstart = [DateTime]::Now # används nu på flera ställen i scriptet där get-date används
        $Script:NewDay = $false
        Prompt_SessionStart

        Prompt_Provider
        Prompt_ColorizePWD
        Prompt_Seperator
        Prompt_time
        Prompt_Seperator
        Prompt_SessionOnline
        Prompt_NewLine
        Prompt_MotD
        Prompt_DBG
        Prompt_ADM
        Encapture-Word -word (get-history).count -color1 (Prompt_BoolLastCommand Green Red) yellow
        # Prompt_Versioning
        Prompt_NestedLevel "$(Prompt_BoolLastCommand Cyan Red)"
        #$PPend = get-date # EXTRA
        #([int]($PPend - $PPstart).TotalMilliseconds).ToString() # EXTRA
    }
    End {
        return " " # Required to remove last part ' PS>'
    }
}

function Prompt_NewDay{
    Param(
        $day,
        $keep = $WorkDaysToKeep
    )
    if ($Script:NewDay) {
        if(!$keep) { Set-PersistentData WorkDaysToKeep 5}
        if (!$WorkDays) {
            Set-PersistentData WorkDays $day
        }else {
            if ($WorkDays.count -gt $keep) {
                Set-PersistentData -Subtract WorkDays $WorkDays[0]
            }
            Set-PersistentData -Add WorkDays $day
        }
    }
}

function Prompt_BoolLastCommand {
    Param(
        $Good = "blue",
        [ConsoleColor]$Bad = "Red"
)
    if ( $Script:LastRunCommand -eq 'True' ) { $Good } else { $Bad }
}
function Prompt_SetLastRunCommand {$Script:LastRunCommand = $? ; $Script:addSeperator = $false}
function Prompt_ColorizePWD {
    Param (
        [ConsoleColor]$Color1 = "Green",
        [ConsoleColor]$Color2 = "white"
    )
    ($pwd -split '\\').foreach{
            Write-Host -ForegroundColor $Color1 $_ -NoNewline
            Write-Host -ForegroundColor $Color2 "\" -NoNewline
        }
    $Script:addSeperator = $true
}
function Prompt_NestedLevel {
    param ([ConsoleColor]$ForegroundColor = "Cyan",[switch]$NewLine)
    $data = @{}
    $data.Object = "$('>' * ($nestedPromptLevel + 1))"
    $data.NoNewline = (!$NewLine)
    if ($ForegroundColor) {$data.ForegroundColor = $ForegroundColor}
    Write-Host @data
}
function Prompt_DBG {
    param ([ConsoleColor]$color1 = "Gray",[ConsoleColor]$color2 = "Red")
    if ($PsDebugContext ) {
        Encapture-Word -word DBG -color1 $color1 -color2 $color2
    }
}
function Prompt_Provider {
    param ([ConsoleColor]$color1 = "Gray",[ConsoleColor]$color2 = "Red")
    Encapture-Word -word ($PWD.Provider.Name -replace "FileSystem","FS" -replace "Registry","Reg" -replace "Certificate","Cert") -color1 $color1 -color2 $color2
}
function Prompt_ADM {
    param ([ConsoleColor]$color1 = "Gray",[ConsoleColor]$color2 = "Red")
    #if ( [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544") )
    If ( ( [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") )
    {
        Encapture-Word -word ADM -color1 $color1 -color2 $color2
    }
}
function Prompt_Seperator {
    Param( [string]$Delimiter=" | ", [ConsoleColor]$ForegroundColor = 'white' )
    if ($Script:addSeperator){
        Write-Host $Delimiter -ForegroundColor $ForegroundColor -NoNewline
        $Script:addSeperator = $false
    }
}

function Prompt_NewLine {
    Write-Host ""
    $Script:addSeperator = $false
}

Function Prompt_SessionStart {
    if ( !$global:StartOfSession -or $PPstart -gt ( get-date -Hour 4 -date $global:StartOfSession.Date.AddDays(1) ) ) {
        Try {
            Update-PersistentData -ErrorAction Stop
            if ( !$global:StartOfSession -or $PPstart -gt ( get-date -Hour 4 -date $global:StartOfSession.Date.AddDays(1) ) ) {
                if ($Script:SessionOnline) { # start av en instans bör ej ha detta och kan då inte göra detta...
                    $Script:NewDay = $true
                    $Script:LatestDay = "{0:yyyy}-{0:MM}-{0:dd} {0:dddd} {1}" -f $global:StartOfSession,$Script:SessionOnline
                }
                Set-PersistentData StartOfSession $PPstart -ea Stop
            }
        } Catch {
            #Write-Warning "Failed session start"
        }
    }
}

function Prompt_SessionOnline {
    Param(
        [ConsoleColor]$ForegroundColor = "Gray",
        [ValidateSet("TimeSinceStart","SessionStart")][string]$outputType = "TimeSinceStart"
    )
    #if (!$Global:StartOfSession) {return ""}
    if ( $outputType -eq "TimeSinceStart" ) {
        if ($global:StartOfSession.GetType().name -ne 'DateTime' ) {
            $total = ($PPstart - (Get-date $global:StartOfSession ) ) 
        }else{ $total = ($PPstart - $global:StartOfSession )
        }
        $Script:SessionOnline = "{0:hh}:{0:mm}" -f $total
        Write-Host "S$Script:SessionOnline" -NoNewline -ForegroundColor $ForegroundColor
    } elseif ($outputType -eq "SessionStart" ) {
        write-host "S$( $global:StartOfSession.ToShortTimeString() )" -NoNewline -ForegroundColor $ForegroundColor
    }
    $Script:addSeperator = $true
}
Function Encapture-Word {
    Param ( $word , [ConsoleColor]$color1,[ConsoleColor]$color2)
    Write-Host -NoNewline -ForegroundColor $color1 "["
    Write-Host -NoNewline -ForegroundColor $color2 $word
    Write-Host -NoNewline -ForegroundColor $color1 "]"
}
function Prompt_Versioning {
    Param ( $word , [ConsoleColor]$color1="Yellow",[ConsoleColor]$color2="Green")
    if ( (ls -Directory -Force |select -ExpandProperty name) -in ".git") {
        Encapture-Word -word GIT -color1 $color1 -color2 $color2
    }elseif ( (ls -Directory -Force |select -ExpandProperty name) -in ".svn") {
        Encapture-Word -word SVN -color1 $color1 -color2 $color2
    }
}
Function Prompt_time {
    Param([ConsoleColor]$Color = "Cyan")
    Write-Host -NoNewline $PPstart.ToShortTimeString() -ForegroundColor $Color
    $Script:addSeperator = $true
}
Function Prompt_MotD {
    if ($Script:NewDay){
        Prompt_NewDay $latestDay
        if (    $global:StartOfSession.Hour -le 11) { Write-Host "Good morning" $env:USERNAME }
        elseif ($global:StartOfSession.Hour -le 16) { Write-Host "Good day" $env:USERNAME }
        else { Write-Host "Good evening" $env:USERNAME }
    }
}