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
        [int]$StagesPerHour
    )
    Process{
        if ($PSBoundParameters.MaxStage)      {$Global:MaxStage      = $MaxStage}
        else { $MaxStage = $Global:MaxStage}
        if ($PSBoundParameters.StagesPerHour) {$Global:StagesPerHour = $StagesPerHour}
        else { $StagesPerHour = $Global:StagesPerHour}
        if ($MaxStage -lt 100 )     {$MaxStage = 700}
        if ($StagesPerHour -lt 100 ) {$StagesPerHour = 300}
        $Hours=($MaxStage-$Now)/$StagesPerHour;
        "Hours left: {0:n2}" -f $Hours;
        "Estimated arrival time $( [DateTime]::Now.AddHours($Hours).ToShortTimeString() )"
    }
}
