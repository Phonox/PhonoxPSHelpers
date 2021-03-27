Function Set-Break {
<#
.SYNOPSIS
This is a function to help you to keep track how much you work each day. When going for a long break, type set-break :)
#>
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        # This will turn on and off, normally, just type Set-Break, for tests i'd recommend Set-Break -Turn:$false and similar
        [Switch]$Turn
    )
    Process {
        if ($null -ne $PSboundParameters.Turn.IsPresent) {
            if (!$Turn) {
                $switchOn = $false
            }
            Elseif ($turn) {
                $switchOn = $true
            }
        }
        Else {
            if ($global:OnBreak) {
                $switchOn = $false
            }
            else {
                $switchOn = $true
            }
        }
        switch ($SwitchOn) {
            $false {
                if ($global:OnBreak) {
                    if ($Global:StartofSession.GetType().ToString() -ne "System.DateTime" -or $global:OnBreak.GetType().ToString() -ne "System.DateTime") {
                        Write-Warning "StartOfSession is incorrect"
                        Set-PersistentData StartOfSession (get-date 09:15)
                        Remove-PersistentData OnBreak
                        break
                    }
                    if ($Global:StartofSession.ToShortDateString() -gt $global:OnBreak.ToShortDateString() ) {}
                    else{
                        $RemoveTicks = ( [DateTime]::Now ) - $global:OnBreak
                        $newvalue = ( $Global:StartofSession.AddTicks( $RemoveTicks.Ticks ) )
                        $splat1 = @{
                            Name = "StartOfSession"
                            Value = $newvalue
                        }
                        Set-PersistentData @splat1
                    }
                    Remove-Variable OnBreak -errorAction Ignore -scope Global
                     
                     $splat2 = @{
                         Name = "OnBreak"
                         Remove = $true
                     }
                     
                     Set-PersistentData @splat2
                }
            }
            $true {
                Set-PersistentData OnBreak ( [DateTime]::now )
            }
        }
    } # end Process
}
Export-moduleMember -function Set-Break