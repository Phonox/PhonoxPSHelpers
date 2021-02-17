#region setup
# Right now vault could be the same as path, but might work on these things later
$Encoding = "UTF8"
$PDDefaultVault = 'PDDefault'
if (!$ENV:Appdata) { $ENV:Appdata = ( [Environment]::GetFolderPath('ApplicationData') ) } # quickfix for MacOS
$PDDefaultPath = Join-Path $ENV:Appdata "PDDefault.json"
$PDDefaultRemove = 'PDDefaultRemove'
#$PDDefaultPath = (Join-Path $env:TEMP "PDDefault.json")
#endregion
Function Get-PersistentData {
    <#
.SYNOPSIS
    This is an internal helper for PD, will not be exported
#>
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [string]
        $Path = $PDDefaultPath,

        [string]
        $Vault = $PDDefaultVault
    )
    Begin {
        #$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
        #if ($Verbose) {
        $start = [DateTime]::Now
        #}
        Write-Verbose "Start of Get-PersistentData"
        $First = $null
    }
    Process {
        if ($first -ne $Vault) {
            #$date = ([DateTime]::now).AddMilliseconds(25)
            #until ( (Test-Path $path) -or $Date -lt ([DateTime]::now)) { } # just wait

            if ( !(Test-Path $path) ) { Write-Warning "File Missing! $Path" ; New-PersistentDataFile $Path -Confirm:$true }
            #$List = @( Get-Content $Path -Raw -Encoding $Encoding | ConvertFrom-Json -EA Continue) -as [System.Collections.ArrayList] | 
            $List = @( Get-Content $Path -Raw -Encoding $Encoding -Force | ConvertFrom-Json -EA Continue ) | 
            ForEach-Object {
                if (! ($_.Scope -match "\w") ) { Throw "File is incomparable" }
                elseif ($_.Name -eq $PDDefaultRemove) {
                    # Remove unwanted variables from all powershell instances.
                    $_.Value | Sort-Object -Unique | ForEach-Object { 
                            Remove-Variable -ErrorAction Ignore -scope Global $_
                            Remove-Variable -ErrorAction Ignore -scope Global local
                        }
                }else { $_ }
            } | 
            ForEach-Object {
                if ($_.Type -eq 'DateTime') { $_.Value = ($_.Value -as 'DateTime').ToLocalTime() }
                else {
                    $_.value = $_.value -as $_.Type
                }
                $_
            }
            
            if ( !$list -or !$Script:PDSettings -or $Script:PDSettings.GetType().ToString() -ne "HashTable") {
                $Script:PDSettings = @{}
            }

            if ( !$list -or !$Script:PDSettings["Vault"] -or $Script:PDSettings["Vault"].GetType().ToString() -ne "HashTable") {
                $Script:PDSettings["Vault"] = @{}
            }
            if ( !$list -or !$Script:PDSettings["data"] -or $Script:PDSettings["data"].GetType().ToString() -ne "HashTable") {
                $Script:PDSettings["data"] = @{}
            }

            if ( !$list -or !$Script:PDSettings["Vault"][$vault] -or $Script:PDSettings["Vault"][$vault].GetType().ToString() -ne "HashTable") {
                $Script:PDSettings["Vault"][$vault] = @{}
            }
            $Script:PDSettings["data"][$vault] = @{}
            
            $Script:PDSettings["Vault"][$vault].List = $list
            if ($list) {
                $Props = ( $list | Get-Member -MemberType NoteProperty -ErrorAction Stop ) -as [PSCustomObject] | select-Object -ExpandProperty Name
            }
            $Script:PDSettings["data"][$vault] = @{}
            $first = $Vault
        }
        foreach ( $obj in $list ) {
            $Script:PDSettings["data"][$vault][$obj.Name] = @{}
            foreach ( $prop in ($props -ne "Name") ) {
                $Script:PDSettings["data"][$vault][$obj.Name].$prop = @{}
                $Script:PDSettings["data"][$vault][$obj.Name].$prop = $obj.$prop
            }
            $Script:PDSettings["data"][$vault][$obj.Name].Value = $Script:PDSettings["data"][$vault][$obj.Name].Value -as $Script:PDSettings["data"][$vault][$obj.Name].Type
        }
    }
    End {
        #if ($Verbose) {
        $end = [DateTime]::Now
        Write-Verbose "Get-PersistentData took: $([int]($end - $start).TotalMilliseconds) ms"
        #}
        Write-Verbose "End of Get-PersistentData"
    }
}
Function New-PersistentDataFile {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    Param([String]$Path)
    Begin {
        #$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
        #if ($Verbose) {
        $start = [DateTime]::Now
        #}
        Write-Verbose "Start of New-PersistentDataFile"
    }
    Process {
        if ( $PSCmdlet.ShouldProcess( $Path, "Create new file for PersistentData" ) ) {
            $json = @{Name = "PDVersion"; Value = 1; Type = "INT"; Scope = "Local" }
            $json | ConvertTo-Json | Out-File $Path -Force -Encoding $Encoding -Confirm:$false
        }
    }
    End {
        #if ($Verbose) { 
        $end = [DateTime]::Now
        Write-Verbose "New-PersistentDataFile took: $([int]($end - $start).TotalMilliseconds) ms"
        #}
        Write-Verbose "End of New-PersistentDataFile"
    }
}

Function Set-PersistentData {
    <#
.SYNOPSIS
    This will save a variable to disk.
.DESCRIPTION
    This feature was created to easily save variables to disk and then import the variables as they last were, and must work over other PS-instances. (if you have 4 instances of powershell, they should all have the same data)
.EXAMPLE
    Set-PersistentData Backlog ([string[]]($Backlog + "Add hotkeys") ) -Verbose
    VERBOSE: Get-PersistentData
    VERBOSE: Start PersistentData
    VERBOSE: Change Variable Backlog
    VERBOSE: Performing the operation "Change Persistant variable Value" on target "Backlog".
    VERBOSE: String[]
    VERBOSE: Remakes to create a joined string
    VERBOSE: Writing to disk...
    VERBOSE: Update-PersistentData
    VERBOSE: Get-PersistentData
    VERBOSE: Change: Backlog
    VERBOSE: No change: StartOfSession
    VERBOSE: END Update-PersistentData
    VERBOSE: Ending Persistentdata
.LINK
    Update-PersistentData
.LINK
    Set-PersistentData
.LINK
    Remove-PersistentData
#>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = "Change")]
    Param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Position = 0, ValueFromPipelineByPropertyName, Mandatory, ParameterSetName = 'Change')]
        [Parameter(Position = 0, ValueFromPipelineByPropertyName, Mandatory, ParameterSetName = 'ChangeADD')]
        [Parameter(Position = 0, ValueFromPipelineByPropertyName, Mandatory, ParameterSetName = 'ChangeSUB')]
        [Parameter(Position = 0, ValueFromPipelineByPropertyName, Mandatory, ParameterSetName = 'Remove')]
        [string]$Name, # Change to dynamic
        
        [ValidateNotNullOrEmpty()]
        [Parameter(Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName, Mandatory, ParameterSetName = 'Change')]
        [Parameter(Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName, Mandatory, ParameterSetName = 'ChangeADD')]
        [Parameter(Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName, Mandatory, ParameterSetName = 'ChangeSUB')]
        $Value,

        [Parameter(Position = 3, ValueFromPipelineByPropertyName, ParameterSetName = 'Change')]
        [Parameter(Position = 3, ValueFromPipelineByPropertyName, ParameterSetName = 'ChangeADD')]
        [Parameter(Position = 3, ValueFromPipelineByPropertyName, ParameterSetName = 'ChangeSUB')]
        [Parameter(Position = 3, ValueFromPipelineByPropertyName, ParameterSetName = 'Remove')]
        [ValidateSet("Global", "Script", "Local", "Private")]
        [string]$Scope = "Global",

        [Parameter(Position = 4, ValueFromPipelineByPropertyName, ParameterSetName = 'Change')]
        [Parameter(Position = 4, ValueFromPipelineByPropertyName, ParameterSetName = 'ChangeADD')]
        [Parameter(Position = 4, ValueFromPipelineByPropertyName, ParameterSetName = 'ChangeSUB')]
        [Parameter(Position = 4, ValueFromPipelineByPropertyName, ParameterSetName = 'Remove')]
        [ValidateNotNullOrEmpty()] # change to Dynamic variable...
        [string]
        $Vault = $PDDefaultVault,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'Watcher')]
        [Parameter(Position = 5, ValueFromPipelineByPropertyName, ParameterSetName = 'Change')]
        [Parameter(Position = 5, ValueFromPipelineByPropertyName, ParameterSetName = 'ChangeADD')]
        [Parameter(Position = 5, ValueFromPipelineByPropertyName, ParameterSetName = 'ChangeSUB')]
        [Parameter(Position = 5, ValueFromPipelineByPropertyName, ParameterSetName = 'Remove')]
        [ValidateNotNullOrEmpty()] # Change to Dynamic variable...
        [string]
        $Path = $PDDefaultPath,

                
        [Parameter(Position = 2, ValueFromPipeline, ParameterSetName = 'ChangeADD')]
        [switch]$Add,
        [Parameter(Position = 2, ValueFromPipeline, ParameterSetName = 'ChangeSUB')]
        [switch]$Subtract,
        
        [Parameter(Position = 1, ValueFromPipelineByPropertyName, Mandatory, ParameterSetName = 'Remove')]
        [switch]$Remove,

        [Parameter(Position = 0, ValueFromPipelineByPropertyName, ParameterSetName = 'Watcher')]
        [switch]$StartWatcher,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName, ParameterSetName = 'Watcher')]
        [switch]$Quiet
    )
    Begin {
        #$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
        #if ($Verbose) {
        $start = [DateTime]::Now
        #}
        Write-Verbose "Start of Set-PersistentData"
        $First = $null
        
    }
    Process {
        if ($First -ne $Vault) {
            Update-PersistentData -Vault $Vault -Path $Path
            $First = $Vault
            $Update = $false
            #Set-PersistentData PIDWrote $PID
        }
        switch ($PsCmdlet.ParameterSetName) {
            "Change" {
                $ThisType = $Value.GetType().Name.ToString()
                if (
                    !$Script:PDSettings["data"][$vault][$name] -or # Variable does not exist
                    $Script:PDSettings["data"][$vault][$name].Scope -ne $Scope -or # Not the same scope
                    $Script:PDSettings["data"][$vault][$name].Type -ne $ThisType -or # Not the same type
                    ($Script:PDSettings["data"][$vault][$name].Value | ConvertTo-Json) -ne ($Value | ConvertTo-Json) # not the save value, takes most time/cpu
                ) {
                    # Procedure to add
                    Write-Verbose "Variable: $Name got new or changed Value"
                    $Script:PDSettings["data"][$vault][$name] = @{
                        Type = $ThisType
                        Value = $Value
                        Scope = $Scope
                    }
                    $update = $true
                    Set-Variable -Name $Name -Value $Script:PDSettings["data"][$vault][$name].Value -Scope $Scope
                }
                else {
                    #Add it
                    Set-Variable -Name $Name -Value $Script:PDSettings["data"][$vault][$name].Value -Scope $Scope
                }
            }
            "Watcher" {
                if (! (Get-EventSubscriber | Where-Object EventName -eq "Changed") ) {
                    #quickfix
                    if ($Quiet) { 
                        Register-Watcher -folder (Split-Path $Path -Parent) -Filter (Split-Path $path -Leaf) -ActionChanged ([scriptblock]::Create("start-sleep -m 15 ; Update-PersistentData")) -Quiet | Out-Null
                    }
                    else {
                        Register-Watcher -folder (Split-Path $Path -Parent) -Filter (Split-Path $path -Leaf) -ActionChanged ([scriptblock]::Create("start-sleep -m 15 ; Update-PersistentData -verbose")) | Out-Null
                    }
                }
            }
            "Remove" {
                $Script:PDSettings["data"][$vault].Remove($Name)
                Remove-Variable -Scope $Scope -Name $Name -ea Ignore
                Write-Verbose "Removed variable: $Name"
                $Update = $true
            }
            "ChangeADD" {
                # Variable does not exist
                if ( !$Script:PDSettings["data"][$vault][$name]) { 
                    Set-PersistentData -Name $Name -Value $Value
                }
                else {
                    # Variable Exist
                    if (!$Script:PDSettings["data"][$vault][$name].Type) {
                        $ThisType = $Value.GetType().Name.ToString()
                    }
                    else {
                        $ThisType = $Script:PDSettings["data"][$vault][$name].Type
                    }
                    Switch ($ThisType) {
                        "Int" { $Script:PDSettings["data"][$vault][$name].Value += $Value }
                        "String" { $ThisType = "$ThisType[]" ; $Script:PDSettings["data"][$vault][$name].Value = ( ( $Script:PDSettings["data"][$vault][$name].Value, $Value ) -as $ThisType ) }
                        #"DateTime" {} # might need to fix this
                        Default { $Script:PDSettings["data"][$vault][$name].Value = ( ( $Script:PDSettings["data"][$vault][$name].Value + $Value ) -as $ThisType ) }
                    }
                    
                    $Script:PDSettings["data"][$vault][$name].Type = $ThisType
                    # if ($ThisType -eq "DateTime") {
                    #     $Script:PDSettings["data"][$vault][$name].Value = $Value.DateTime
                    # }
                    $Script:PDSettings["data"][$vault][$name].Scope = $Scope
                    $update = $true
                    Set-Variable -Name $Name -Value $Script:PDSettings["data"][$vault][$name].Value -Scope $Scope
                }
            }
            "ChangeSUB" {
                # variable does not exist
                if ( !$Script:PDSettings["data"][$vault][$name] ) {
                    Write-Error "Missing variable" -ea Stop
                }
                else {
                    #Variable Exist
                    Switch ($ThisType) {
                        "int" { $Script:PDSettings["data"][$vault][$name].Value -= $Value }
                        Default {
                            if ($Script:PDSettings["data"][$vault][$name].Value | Where-Object { $_ -eq $Value } ) {
                                $Script:PDSettings["data"][$vault][$name].Value = ( ( $Script:PDSettings["data"][$vault][$name].Value | Where-Object { $_ -ne $Value } ) -as $Script:PDSettings["data"][$vault][$name].Type ) 
                            }
                            else { Write-Error "Value is incorrect, watching for equal value to remove." }
                        }
                    }
                    $Script:PDSettings["data"][$vault][$name].Scope = $Scope
                    $update = $true
                    Set-Variable -Name $Name -Value $Script:PDSettings["data"][$vault][$name].Value -Scope $Scope
                }
            }
            Default { $PsCmdlet.ParameterSetName | ConvertTo-Json ; Write-Error "Not correct ParameterSetName" -ErrorAction Stop }
        }
    }
    End {
        if ($Update) {
            Write-PersistentData -Data $Script:PDSettings["data"][$vault] -Path $Path -Vault $vault
        }
        #if ($Verbose) { 
        $end = [DateTime]::Now
        Write-Verbose "Set-PersistentData took: $([int]($end - $start).TotalMilliseconds) ms"
        #}
        Write-Verbose "End of Set-PersistentData"
    }
}

Function Write-PersistentData {
    <#
.SYNOPSIS
    This is an internal helper for PD, will not be exported
#>
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        $Data,
        [string]$Path = $PDDefaultPath,
        [string]$Vault = $PDDefaultVault
    )
    Begin {
        #$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
        #if ($Verbose) {
        $start = [DateTime]::Now
        #}
        Write-Verbose "Start of Write-PersistentData"
        $first = $null
    }
    Process {
        # Rewrite hash to list
        if ($first -ne $vault) {
            $list = [System.Collections.ArrayList]@()
            $first = $Vault
        }
        foreach ($Key in $data.Keys) {
            $Props = $data.$Key.Keys
            $hash = @{}
            if ($data.$key.Value.GetType().Name -eq "DateTime" -and $data.$key.Type -eq "DateTime") { 
                $data.$key.Value = $data.$key.Value.ToUniversalTime()
            }
            foreach ($Prop in $props) {
                $hash.$prop = $data.$key.$Prop
            }
            $hash.Name = $Key
            $list.add([PSCustomObject]$hash) | Out-Null
        }
        $Script:PDSettings["Vault"][$vault].List = $list

        Out-File -FilePath $path -Encoding $Encoding -Force -InputObject ($list | ConvertTo-Json)
    }
    End {
        #if ($Verbose) { 
        $end = [DateTime]::Now
        Write-Verbose "Write-PersistentData took: $([int]($end - $start).TotalMilliseconds) ms"
        #}
        Write-Verbose "End of Write-PersistentData"
    }
}

Function Update-PersistentData {
    <#
    .SYNOPSIS
        This will update variables saved on disk.
    .DESCRIPTION
        For instance in prompt, check if variable exist, then call update-persistentData if not and check variable value again
    .EXAMPLE
        Update-PersistentData -Verbose
        VERBOSE: Update-PersistentData
        VERBOSE: Get-PersistentData
        VERBOSE: Change: Backlog
        VERBOSE: No change: StartOfSession
    .LINK
        Update-PersistentData
    .LINK
        Set-PersistentData
    .LINK
        Remove-PersistentData
    #>
    [CmdletBinding()]
    Param(
        [String]
        $Path = $PDDefaultPath,

        [String]
        $Vault = $PDDefaultVault
    )
    BEGIN {
        #$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
        #if ($Verbose) {
        $start = [DateTime]::Now
        #}
        Write-Verbose "Start of Update-PersistentData"
        $first = $null
    }
    Process {
        #if ($first -ne $Vault) { # Takes avg 4 ms
        Get-PersistentData $Path $Vault
        $first = $Vault
        #}
        # Update all values
        foreach ($Key in $Script:PDSettings["data"][$vault].Keys) {
            $hash = $Script:PDSettings["data"][$vault].$Key
            $ThisVar = Get-Variable -Name $key -Scope $hash.scope -ea ignore
            # Check if the there are a variable, Same dataType, if it is or containts an array or hash of some kind, (NOT ADDED SCOPE CHECK)
            if (
                !$ThisVar -or # if variable exists
                $ThisVar.Gettype().Name.ToString() -ne $hash.Type -or # if the datatype is equal
                # Add scope check
                [bool](diff ($ThisVar | ConvertTo-Json) ($hash.value | ConvertTo-Json) ) # if there are a diff i value
            ) {
                if ($hash.Scope) {
                    Set-Variable -Name $Key -Value $hash.Value -Scope $hash.Scope
                }
                else {
                    Set-Variable -Name $Key -Value $hash.Value -Scope Global
                }
            }
        } # End of update
    }
    END {
        #if ($Verbose) { 
        $end = [DateTime]::Now
        Write-Verbose "Update-PersistentData took: $([int]($end - $start).TotalMilliseconds) ms"
        #}
        Write-Verbose "End of Update-PersistentData"
    }
}

Function Show-PersistentData {
    <#
    .SYNOPSIS
    Display all saved variables in PersistentData
    .EXAMPLE
    Show-PersistentData

    WARNING: Containing inside of PDDefault

    Value                                                                                                         Name           Scope  Type
    -----                                                                                                         ----           -----  ----
    2020-06-13 04:00:00                                                                                           EndOfSession   Global DateTime
    {2020-05-20 onsdag 01:46, 2020-05-21 torsdag 07:01, 2020-05-25 måndag 00:00, 2020-06-10 onsdag 09:04}         WorkDays       Global String[]
    {D:\A Bethesda\Launcher\games, D:\#SteamPowered\steamapps\common, D:\A Blizzard\Game, D:\A GOG\Galaxy\Games…} ListOfGames    Global String[]
    07:08                                                                                                         SessionOnline  Global String
    5                                                                                                             WorkDaysToKeep Global Int32
    1                                                                                                             PDVersion      Local  INT
    2020-06-12 07:53:57                                                                                           StartOfSession Global DateTime
    #>
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Vault = $PDDefaultVault,
        [switch]
        $AllLists,
        [switch]
        $AllListsAndAllData
    )
    Begin {
        #$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
        #if ($Verbose) {
        $start = [DateTime]::Now
        #}
        Write-Verbose "Start of Show-PersistentData"
    }
    Process {
        if ($AllLists) { $Script:PDSettings["Vault"].Keys }
        elseif ($AllListsAndAllData) {
            Show-PersistentData -AllLists | Show-PersistentData
        }
        else {
            Write-Warning "Containing inside of $vault"
            $Script:PDSettings["Vault"][$vault].List
        }
    }
    End {
        #if ($Verbose) { 
        $end = [DateTime]::Now
        Write-Verbose "Show-PersistentData took: $([int]($end - $start).TotalMilliseconds) ms"
        #}
        Write-Verbose "End of Show-PersistentData"
    }
}


Function Remove-PersistentData {
    <#
    .SYNOPSIS
        This is a proxy for Set-PersistentData -remove $variable
    .DESCRIPTION
        Remove existing variable, either on disk or not.
    .EXAMPLE
        Remove-PersistentData loremIpsum -Verbose
        VERBOSE: Get-PersistentData
        VERBOSE: Start PersistentData
        VERBOSE: Removed: loremIpsum
        VERBOSE: Writing to disk...
        VERBOSE: Update-PersistentData
        VERBOSE: Get-PersistentData
        VERBOSE: Change: Backlog
        VERBOSE: No change: StartOfSession
        VERBOSE: END Update-PersistentData
        VERBOSE: Ending Persistentdata
    .LINK
        Update-PersistentData
    .LINK
        Set-PersistentData
    .LINK
        Remove-PersistentData
    #>
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [ValidateNotNullOrEmpty()]
        [string[]]$Name
    )
    Begin {
        #$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
        #if ($Verbose) {
        $start = [DateTime]::Now
        Write-Verbose "Start of Remove-PersistentData"
        #}
    }
    Process {
        Foreach ($Nam in $name) {
            Set-PersistentData -Remove -Name $Nam
        }
    }
    End {
        #if ($Verbose) {
        $end = [DateTime]::Now
        Write-Verbose "Remove-PersistentData took: $([int]($end - $start).TotalMilliseconds) ms"
        #}
        Write-Verbose "End of Remove-PersistentData"
    }
}
<#
Function Test-FileLock {
Param(
[String]$Path
)
Begin{}
Process{
	if ( !(Test-Path $Path) ) {
		return 2
	}
	$oFile = New-Object System.IO.FileInfo $Path
	Try{
		$oStream = $oFile.Open([System.IO.FileMode]::Open,[System.IO.FileAccess]::ReadWrite,[System.IO.FileSHare]::None)
		
		If ($oStrea) {
			$oStream.Close()
		}
		return 0
	} Catch {
		#locked by other process
		return 1
	}
}
End{}
}
#>
# Update all variables

Function Start-PersistentDataJobs {
    <#
    .SYNOPSIS
    This is to help you to insert startup background jobs on every PS instance
    .EXAMPLE
    Start-PersistentDataJobs -StartWatcher
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = "Woop")]
    Param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'Addjob')]                   $Addjob,
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'StartWatcher')]     [switch]$StartWatcher,
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'StartWatcherQuiet')][switch]$StartWatcherQuiet
    )
    #Param($AddJob,[switch]$StartWatcher,[switch]$StartWatcherQuiet)
    Begin {}
    Process {
        switch ($PsCmdlet.ParameterSetName) {
            "Woop" {
                Foreach ( $job in $Global:PersistentDataJobs ) {
                    Try {
                        $ea = $ErrorActionPreference
                        $ErrorActionPreference = "Stop"
                        . ( [ScriptBlock]::Create( $job ) )
                    }
                    Catch {
                        Write-Warning "Failed to Start-PersistentDataJobs on:"
                        $job
                        Write-Error -ErrorAction Continue $_
                    }
                    Finally {
                        $ErrorActionPreference = $ea
                    }
                        
                }
            }
            "StartWatcher" { Set-PersistentData -Add PersistentDataJobs "Set-PersistentData -StartWatcher -Path $PDDefaultPath" }
            "StartWatcherQuiet" { Set-PersistentData -Add PersistentDataJobs "Set-PersistentData -StartWatcher -Quiet -Path $PDDefaultPath" }
            "Addjob" { Set-PersistentData -Add PersistentDataJobs $AddJob }
        }
    }
    End {}
}

Update-PersistentData -Verbose
Start-PersistentDataJobs

Export-ModuleMember -Function Set-PersistentData, Update-PersistentData, Remove-PersistentData, Show-PersistentData, Start-PersistentDataJobs -ErrorAction Ignore