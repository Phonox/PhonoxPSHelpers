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
        $Script:PPStart = [DateTime]::Now # används nu på flera ställen i scriptet där get-date används
        $Script:NewDay = $false
        Prompt_SessionStart

        Prompt_Provider
        Prompt_ColorizePWD
        Prompt_Seperator
        Prompt_time
        Prompt_Seperator
        Prompt_SessionOnline
        Prompt_Seperator
        Prompt_week

        # New Row
        # Prompt_MotD

        # New Row
        Prompt_NewLine
        Prompt_ADM
        Prompt_DBG
        if ( $Global:OnBreak ) {
            Encapture-Word -word "ONBREAK" -color1 (Prompt_BoolLastCommand Green Red) yellow
        }
        $HistoryCount = (Get-History).count
        Encapture-Word -word "H`:$HistoryCount" -color1 (Prompt_BoolLastCommand Green Red) yellow
        $ErrorCount = $Global:Error.Count
        Encapture-Word -word "E`:$ErrorCount" -color1 (Prompt_BoolLastCommand Green Red) yellow
        # Prompt_Versioning5
        Prompt_NestedLevel (Prompt_BoolLastCommand Cyan Red)
        #$PPend = get-date # EXTRA
        #([int]($PPend - $Script:PPStart).TotalMilliseconds).ToString() # EXTRA
    }
    End {
        return " " # Required to remove last part ' PS>'
    }
}

function Prompt_NewDay {
    Param(
        $day,
        $keep = $WorkDaysToKeep
    )
    if (!$keep) { Set-PersistentData WorkDaysToKeep 5 }
    if (!$WorkDays) {
        Set-PersistentData WorkDays $day
    }
    else {
        if ($WorkDays.count -ge $keep) {
            Set-PersistentData WorkDays ( $Workdays[1..$keep] + $day )
        }else{
            Set-PersistentData -Special Add WorkDays $day
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

function Prompt_SetLastRunCommand { $Script:LastRunCommand = $? ; $Script:addSeperator = $false }

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
    param ([ConsoleColor]$ForegroundColor = "Cyan", [switch]$NewLine)
    $data = @{}
    $data.Object = "$('>' * ($nestedPromptLevel + 1))"
    $data.NoNewline = (!$NewLine)
    if ($ForegroundColor) { $data.ForegroundColor = $ForegroundColor }
    Write-Host @data
}

function Prompt_DBG {
    param ([ConsoleColor]$color1 = "Gray", [ConsoleColor]$color2 = "Red")
    if ($PsDebugContext ) {
        Encapture-Word -word DBG -color1 $color1 -color2 $color2
    }
}

function Prompt_Provider {
    param ([ConsoleColor]$color1 = "Gray", [ConsoleColor]$color2 = "Red")
    Encapture-Word -word ($PWD.Provider.Name -replace "FileSystem", "FS" -replace "Registry", "Reg" -replace "Certificate", "Cert") -color1 $color1 -color2 $color2
}

function Prompt_ADM {
    param ([ConsoleColor]$color1 = "Gray", [ConsoleColor]$color2 = "Red")
    if ( $IsWindows -or [bool]( get-command Get-WindowsEdition -ea ignore )) {
        If ( ( [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") ) {
            Encapture-Word -word ADM -color1 $color1 -color2 $color2
        }
    }
}

function Prompt_Seperator {
    Param( [string]$Delimiter = " | ", [ConsoleColor]$ForegroundColor = 'white' )
    if ($Script:addSeperator) {
        Write-Host $Delimiter -ForegroundColor $ForegroundColor -NoNewline
        $Script:addSeperator = $false
    }
}

function Prompt_NewLine {
    Write-Host ""
    $Script:addSeperator = $false
}

Function Prompt_SessionStart {
    Try {
        $ea = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        if ( !$global:StartOfSession -or !$global:EndOfSession -or $Script:PPStart -gt $global:EndOfSession ) {
            Update-PersistentData -ErrorAction SilentlyContinue
            if ( !$global:StartOfSession -or !$global:EndOfSession -or $Script:PPStart -gt $global:EndOfSession ) {
                if ( $global:SessionOnline -and $global:StartOfSession ) {
                    $Script:LastDay = "{0:yyyy}-{0:MM}-{0:dd} {0:dddd} {1}" -f $global:StartOfSession, $global:SessionOnline
                }
                else { } # Requires sessions to be live 24/7 :(
                $Script:NewDay = $true
                $null = [PSCustomObject]@{
                        Name  = "StartOfSession"
                        Value = $Script:PPStart
                    }, [PSCustomObject]@{
                        Name  = "EndOfSession"
                        Value = ( [datetime]($Script:PPStart.AddDays(1).ToString('yyyy-MM-dd 04:00:00 ') + "AM")  )
                    } |Set-PersistentData
                prompt_newday $Script:LastDay
                Prompt_MotD #$LastDay
                # Set-PersistentData StartOfSession $Script:PPStart
                # Set-PersistentData EndOfSession ( get-date -Hour 4 -date $Script:PPStart.Date.AddDays(1) )
            }
        }
    }
    Catch { Write-Warning $_ ; Write-Error $_}
    Finally { $ErrorActionPreference = $ea }
}

function Prompt_SessionOnline {
    Param(
        [ConsoleColor]$ForegroundColor = "Gray"#,
        #[ValidateSet("TimeSinceStart","SessionStart")][string]$outputType = "TimeSinceStart"
    )
    #if (!$Global:StartOfSession) {return ""}
    #if ( $outputType -eq "TimeSinceStart" ) {
    if ($global:StartOfSession.GetType().name -ne 'DateTime' ) {
        $total = ($Script:PPStart - ([dateTime]$global:StartOfSession ) )
    }
    else {
        if ($Global:OnBreak) {
            $total = ($Global:OnBreak - $global:StartOfSession )
        }else{
            $total = ($Script:PPStart - $global:StartOfSession )
        }
    }
    $global:SessionOnline = "{0:hh}:{0:mm}" -f $total
    Write-Host "S$global:SessionOnline" -NoNewline -ForegroundColor $ForegroundColor
    Set-PersistentData SessionOnline $global:SessionOnline
    #} elseif ($outputType -eq "SessionStart" ) {
    #    write-host "S$( $global:StartOfSession.ToShortTimeString() )" -NoNewline -ForegroundColor $ForegroundColor
    #}
    $Script:addSeperator = $true
}

Function Encapture-Word {
    Param ( [string]$word , [ConsoleColor]$color1, [ConsoleColor]$color2)
    Write-Host -NoNewline -ForegroundColor $color1 "["
    Write-Host -NoNewline -ForegroundColor $color2 $word
    Write-Host -NoNewline -ForegroundColor $color1 "]"
}

function Prompt_Versioning {
    Param ( $word , [ConsoleColor]$color1 = "Yellow", [ConsoleColor]$color2 = "Green")
    if ( (Get-ChildItem -Directory -Force | Select-Object -ExpandProperty name) -in ".git") {
        Encapture-Word -word GIT -color1 $color1 -color2 $color2
    }
    elseif ( (Get-ChildItem -Directory -Force | Select-Object -ExpandProperty name) -in ".svn") {
        Encapture-Word -word SVN -color1 $color1 -color2 $color2
    }
}

Function Prompt_time {
    Param([ConsoleColor]$Color = "Cyan")
    Write-Host -NoNewline $Script:PPStart.ToShortTimeString() -ForegroundColor $Color
    $Script:addSeperator = $true
}

Function Prompt_week {
    $week = Get-Date -UFormat %V
    Write-Host "W$week" -NoNewline
}
Function Prompt_MotD {
    Prompt_NewLine
    if (    $global:StartOfSession.Hour -le 11) { Write-Host "Good morning" $env:USERNAME }
    elseif ($global:StartOfSession.Hour -le 16) { Write-Host "Good day" $env:USERNAME }
    else { Write-Host "Good evening" $env:USERNAME }
}