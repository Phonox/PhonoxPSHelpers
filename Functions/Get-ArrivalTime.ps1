Function Get-ArrivalTime {
    <#
    .SYNOPSIS
    Get information of how much time left till you hit max stage, which you should ascend.
    MaxStage and StagesPerHour will be saved as variable in this instance of powershell and only requires to set each time you start a new powershell.
    .EXAMPLE
    Get-ArrivalTime 10
Hours left: 1.98
Estimated arrival time 12:44 PM)
    .EXAMPLE
    Get-ArrivalTime 2068 -MaxStage 3900 -StagesPerHour 730

Hours left: 2.51
Estimated arrival time 1:17 PM)

# If you have entered MaxStage and StagesPerHour once (in that instance), it will remeber it till next time
PS s> Get-ArrivalTime 2068

Hours left: 2.51
Estimated arrival time 1:17 PM)
    #>
    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        # Enter the stage you are at the moment
        [int]$Now,
        # Enter the max stage on which you are going to ascend
        [int]$MaxStage,
        # Take time of how many stages you do in 1h and enter it here.
        [int]$StagesPerHour,
        [ValidateNotNullOrEmpty()]
        [ValidateSet("100LvlSolo","SameLevel")]
        $Strategy = "100LvlSolo",
        $MinutesOfDoubleSpeed
    )
    Process{
        switch ($Strategy) {
            "100LvlSolo" { $switchStrat = 100 ; Break } # The last 100 takes much more time..
            "SameLevel"  { $switchStrat = 0   ; Break }
        }

        if ($PSBoundParameters.MaxStage)      {$Global:MaxStage      = $MaxStage}
        else {                                 $MaxStage = $Global:MaxStage }
        if ($PSBoundParameters.StagesPerHour) {$Global:StagesPerHour = $StagesPerHour}
        else {                                 $StagesPerHour = $Global:StagesPerHour}
        if ($PSBoundParameters.MinutesOfDoubleSpeed) {$Global:MinutesOfDoubleSpeed = $MinutesOfDoubleSpeed}
        else {                                 $MinutesOfDoubleSpeed = $Global:MinutesOfDoubleSpeed}
        
        if ($MaxStage -lt 100 )     {$MaxStage = 700}
        if ($StagesPerHour -lt 100 ) {$StagesPerHour = 300}
        if ($MinutesOfDoubleSpeed -lt 20 ) {$MinutesOfDoubleSpeed = 20}

        if (!$PSBoundParameters.MaxStage)             {"MaxStage`: $MaxStage" }
        if (!$PSBoundParameters.StagesPerHour)        {"StagesPerHour`: $StagesPerHour" }
        if (!$PSBoundParameters.MinutesOfDoubleSpeed) {"MinutesOfDoubleSpeed`: $MinutesOfDoubleSpeed" }


        $Hours=($MaxStage + $switchStrat - $Now)/$StagesPerHour
        $RequiredDouble = [Math]::Ceiling( (60 / $MinutesOfDoubleSpeed ) * $Hours )
        $ExtraHours = $RequiredDouble * 15 / 3600
        $TotalHours = $Hours + $ExtraHours
        $estimatedTime = [DateTime]::Now.AddHours($TotalHours).ToShortTimeString()
        $round = [math]::Round($TotalHours,2)
        "Hours left`: {0}" -f $round;
        "Estimated arrival time {0}" -f $estimatedTime
        "Required 2x speed ads`: {0}" -f $RequiredDouble
    }
}
