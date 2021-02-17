Function Set-Break {
    <#
    .SYNOPSIS
    This is a function to help the amount of time you have worked
    #>
    Param(
        [Parameter(Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Switch]$Turn
    )
    Process {
        if ($PSboundParameters.Turn.IsPresent -ne $null) {
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

                    $RemoveTicks = ( [DateTime]::Now ) - $global:OnBreak
                    $newvalue = ( $Global:StartofSession.AddTicks( $RemoveTicks.Ticks ) )
                    Remove-Variable OnBreak -errorAction Ignore -scope Global
                     $splat1 = @{
                         Name = "StartOfSession"
                         Value = $newvalue
                     }
                     $splat2 = @{
                         Name = "OnBreak"
                         Remove = $true
                     }
                     Set-PersistentData @splat1
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