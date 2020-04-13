#region setup
# Right now vault could be the same as path, but might work on these things later
$Encoding  = "UTF8"
$PDDefaultVault = 'PDDefault'
$PDDefaultPath = (Join-Path $env:APPDATA "PDDefault.json")
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
        Write-Verbose "Start of Get-PersistentData"
        $First = $null
    }
    Process{
        if ($first -ne $Vault) {
            if ( !(Test-Path $path) ) {Write-Warning "File Missing! $Path" ; New-PersistentDataFile $Path -Confirm:$true }
            $List = @( Get-Content $Path -Raw -Encoding $Encoding | ConvertFrom-Json -EA Continue) -as [System.Collections.ArrayList] | %{ if ($_.Scope -match "\w") { $_ } else {Throw "File is incomparable" } }
            if ( !($List |gm -MemberType NoteProperty).count -gt 1 ) {
                Write-Error -ErrorAction Stop "Failed to import $Path"
            }
            
            if (!$Script:PDSettings -or $Script:PDSettings.GetType().ToString() -ne "HashTable") {
                $Script:PDSettings = @{}
            }

            if (!$Script:PDSettings.Vault -or $Script:PDSettings.Vault.GetType().ToString() -ne "HashTable") {
                $Script:PDSettings.Vault = @{}
            }
            if (!$Script:PDSettings.Data -or $Script:PDSettings.Data.GetType().ToString() -ne "HashTable") {
                $Script:PDSettings.Data = @{}
            }

            if (!$Script:PDSettings.Vault.$Vault -or $Script:PDSettings.Vault.$Vault.GetType().ToString() -ne "HashTable") {
                $Script:PDSettings.Vault.$Vault = @{}
            }
            $Script:PDSettings.Data.$Vault = @{}
            $Script:PDSettings.Vault.$Vault.List = $list
            $Props = ( $list |gm -MemberType NoteProperty -ErrorAction Stop ) -as [PSCustomObject] |select -expand Name
            $Script:PDSettings.Data.$Vault = @{}
            $first = $Vault
        } 
        foreach ( $obj in $list ) {
            $Script:PDSettings.Data.$Vault.($obj.Name) = @{}
            foreach ( $prop in ($props -ne "Name") ) {
                $Script:PDSettings.Data.$Vault.($obj.Name).$prop = @{}
                $Script:PDSettings.Data.$Vault.($obj.Name).$prop = $obj.$prop
            }
            if ($Script:PDSettings.Data.$Vault.($obj.Name).value -and $Script:PDSettings.Data.$Vault.($obj.Name).Type ) {
                $Script:PDSettings.Data.$Vault.($obj.Name).Value = $Script:PDSettings.Data.$Vault.($obj.Name).Value -as $Script:PDSettings.Data.$Vault.($obj.Name).Type
            }
        }
    }
    End {
        Write-Verbose "End of Get-PersistentData"
    }
}
Function New-PersistentDataFile {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]
    Param([String]$Path)
    Begin{}
    Process{
        if ( $PSCmdlet.ShouldProcess( $Path,"Create new file for PersistentData" ) ){
            $json = @{Name="PDVersion";Value=1;Type="INT";Scope="Local"}
            $json | ConvertTo-Json | Out-File $Path -Force -Encoding $Encoding -Confirm:$false
        }
    }
    End{}
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
    [CmdletBinding(SupportsShouldProcess,DefaultParameterSetName="Change")]
    Param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Position=0,ValueFromPipelineByPropertyName,Mandatory,ParameterSetName='Change')]
        [Parameter(Position=0,ValueFromPipelineByPropertyName,Mandatory,ParameterSetName='ChangeADD')]
        [Parameter(Position=0,ValueFromPipelineByPropertyName,Mandatory,ParameterSetName='ChangeSUB')]
        [Parameter(Position=0,ValueFromPipelineByPropertyName,Mandatory,ParameterSetName='Remove')]
        [string]$Name, # Change to dynamic
        
        [ValidateNotNullOrEmpty()]
        [Parameter(Position=1,ValueFromPipeline,Mandatory,ParameterSetName='Change')]
        [Parameter(Position=1,ValueFromPipeline,Mandatory,ParameterSetName='ChangeADD')]
        [Parameter(Position=1,ValueFromPipeline,Mandatory,ParameterSetName='ChangeSUB')]
        $Value,

        [Parameter(Position=3,ValueFromPipelineByPropertyName,ParameterSetName='Change')]
        [Parameter(Position=3,ValueFromPipelineByPropertyName,ParameterSetName='ChangeADD')]
        [Parameter(Position=3,ValueFromPipelineByPropertyName,ParameterSetName='ChangeSUB')]
        [Parameter(Position=3,ValueFromPipelineByPropertyName,ParameterSetName='Remove')]
        [ValidateSet("Global","Script","Local","Private")]
        [string]$Scope = "Global",

        [Parameter(Position=4,ValueFromPipelineByPropertyName,ParameterSetName='Change')]
        [Parameter(Position=4,ValueFromPipelineByPropertyName,ParameterSetName='ChangeADD')]
        [Parameter(Position=4,ValueFromPipelineByPropertyName,ParameterSetName='ChangeSUB')]
        [Parameter(Position=4,ValueFromPipelineByPropertyName,ParameterSetName='Remove')]
        [ValidateNotNullOrEmpty()] # change to Dynamic variable...
        [string]
        $Vault = $PDDefaultVault,

        [Parameter(ValueFromPipelineByPropertyName,ParameterSetName='Watcher')]
        [Parameter(Position=5,ValueFromPipelineByPropertyName,ParameterSetName='Change')]
        [Parameter(Position=5,ValueFromPipelineByPropertyName,ParameterSetName='ChangeADD')]
        [Parameter(Position=5,ValueFromPipelineByPropertyName,ParameterSetName='ChangeSUB')]
        [Parameter(Position=5,ValueFromPipelineByPropertyName,ParameterSetName='Remove')]
        [ValidateNotNullOrEmpty()] # Change to Dynamic variable...
        [string]
        $Path = $PDDefaultPath,

                
        [Parameter(Position=2,ValueFromPipeline,ParameterSetName='ChangeADD')]
        [switch]$Add,
        [Parameter(Position=2,ValueFromPipeline,ParameterSetName='ChangeSUB')]
        [switch]$Subtract,
        
        [Parameter(Position=1,ValueFromPipelineByPropertyName,Mandatory,ParameterSetName='Remove')]
        [switch]$Remove,

        [Parameter(Position=0,ValueFromPipelineByPropertyName,ParameterSetName='Watcher')]
        [switch]$StartWatcher,
        [Parameter(Position=1,ValueFromPipelineByPropertyName,ParameterSetName='Watcher')]
        [switch]$Quiet
    )
    Begin {
        Write-Verbose "Start of Set-PersistentData"
        $First = $null
    }
    Process{
        if ($First -ne $Vault) {
            Update-PersistentData -Vault $Vault -Path $Path
            $First = $Vault
            $Update = $false
        }
        switch ($PsCmdlet.ParameterSetName) {
            "Change"    {
                $ThisType = $Value.GetType().Name.ToString()
                if (
                    !$Script:PDSettings.Data.$Vault.$Name -or # variable does not exist
                    $Script:PDSettings.Data.$Vault.$Name.Scope -ne $Scope -or #Not the same scope
                    $Script:PDSettings.Data.$Vault.$Name.Type -ne $ThisType -or #not the same type
                    ($Script:PDSettings.Data.$Vault.$Name.Value|ConvertTo-Json) -ne ($Value|ConvertTo-Json) # not the save value, takes most time/cpu
                ) {
                    # Procedure to add
                    Write-Verbose "Variable: $Name got new or changed Value"
                    $Script:PDSettings.Data.$Vault.$Name = @{}
                    $Script:PDSettings.Data.$Vault.$Name.Type = $ThisType
                    if ($ThisType -eq "DateTime") {
                        $Script:PDSettings.Data.$Vault.$Name.Value = $Value.DateTime
                    } else {
                        $Script:PDSettings.Data.$Vault.$Name.Value = $Value
                    }
                    $Script:PDSettings.Data.$Vault.$Name.Scope = $Scope
                    $update = $true
                }else{
                    #Add it
                }
            }
            "Watcher"   {
                if (! (Get-EventSubscriber | ? EventName -eq "Changed") ) { #quickfix
                    if (!$Quiet) { 
                        Register-Watcher -folder (Split-Path $Path -Parent) -Filter (Split-Path $path -Leaf) -ActionChanged ([scriptblock]::Create("Update-PersistentData")) -Quiet |out-null }
                    else {
                        Register-Watcher -folder (Split-Path $Path -Parent) -Filter (Split-Path $path -Leaf) -ActionChanged ([scriptblock]::Create("Update-PersistentData -verbose")) | Out-Null
                    }
                }
            }
            "Remove"    {
                $Script:PDSettings.Data.$Vault.Remove($Name)
                Remove-Variable -Scope $Scope -Name $Name -ea Ignore
                Write-Verbose "Removed variable: $Name"
                $Update = $true
            }
            "ChangeADD" {
                if (
                    !$Script:PDSettings.Data.$Vault.$Name # variable does not exist
                ) { Write-Error "Missing variable" -ea Stop }else {
                    if (!$Script:PDSettings.Data.$Vault.$Name.Type) {
                        $ThisType = $Value.GetType().Name.ToString()
                    } else {
                        $ThisType = $Script:PDSettings.Data.$Vault.$Name.Type
                    }
                    Switch ($ThisType) {
                        "Int"    {$Script:PDSettings.Data.$Vault.$Name.Value += $Value}
                        "String" { $ThisType = "$ThisType[]" ; $Script:PDSettings.Data.$Vault.$Name.Value = ( ( $Script:PDSettings.Data.$Vault.$Name.Value,$Value ) -as $ThisType ) }
                        #"DateTime" {} # might need to fix this
                        Default { $Script:PDSettings.Data.$Vault.$Name.Value = ( ( $Script:PDSettings.Data.$Vault.$Name.Value + $Value ) -as $ThisType ) }
                    }
                    
                    $Script:PDSettings.Data.$Vault.$Name.Type = $ThisType
                    if ($ThisType -eq "DateTime") {
                        $Script:PDSettings.Data.$Vault.$Name.Value = $Value.DateTime
                    }
                    $Script:PDSettings.Data.$Vault.$Name.Scope = $Scope
                    $update = $true
                    Set-Variable -Name $Name -Value $Script:PDSettings.Data.$Vault.$Name.Value -Scope $Scope
                }
            }
            "ChangeSUB" {
                if (
                    !$Script:PDSettings.Data.$Vault.$Name # variable does not exist
                ) {Write-Error "Missing variable" -ea Stop }else {
                    Switch ($ThisType) {
                        "int"    {$Script:PDSettings.Data.$Vault.$Name.Value -= $Value}
                        Default {
                            if ($Script:PDSettings.Data.$Vault.$Name.Value |? {$_ -eq $Value} ) {
                                $Script:PDSettings.Data.$Vault.$Name.Value = ( ( $Script:PDSettings.Data.$Vault.$Name.Value | ?{ $_ -ne $Value } ) -as $Script:PDSettings.Data.$Vault.$Name.Type ) 
                            } else {Write-Error "Value is incorrect, watching for equal value to remove."}
                            
                        }
                    }
                    $Script:PDSettings.Data.$Vault.$Name.Scope = $Scope
                    $update = $true
                    Set-Variable -Name $Name -Value $Script:PDSettings.Data.$Vault.$Name.Value -Scope $Scope
                }
            }
            Default {$PsCmdlet.ParameterSetName |ConvertTo-Json ; Write-Error "Not correct ParameterSetName" -ErrorAction Stop}
        }
    }
    End{
        if ($Update) {
            Write-PersistentData -Data $Script:PDSettings.Data.$Vault -Path $Path -Vault $vault
        }
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
        Write-Verbose "Start of Write-PersistentData"
        #$First = $true
        $list = [System.Collections.ArrayList]@()
    }
    Process{
        # Rewrite hash to list
        foreach ($Key in $data.Keys) {
            $Props = $data.$Key.Keys
            $hash = @{}
            foreach($Prop in $props) {
                $hash.$prop = $data.$key.$Prop
            }
            $hash.Name = $Key
            $list.add([PSCustomObject]$hash) |Out-Null
            $Script:PDSettings.Vault.$Vault.List = $list
        }

        Out-File -FilePath $path -Encoding $Encoding -Force -InputObject ($list|ConvertTo-Json)
    }
    End{
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
        $Path=$PDDefaultPath,

        [String]
        $Vault=$PDDefaultVault
    )
    BEGIN {
        Write-Verbose "Start of Update-PersistentData"
        $first = $null
    }
    Process {
        if ($first -ne $Vault) {
            Get-PersistentData $Path $Vault
            $first = $Vault
        }
        # Update all values
        foreach ($Key in $Script:PDSettings.Data.$Vault.Keys) {
            $hash = $Script:PDSettings.Data.$Vault.$Key
            $ThisVar = Get-Variable -Name $key -Scope $hash.scope -ea ignore
            # Check if the there are a variable, Same dataType, if it is or containts an array or hash of some kind, (NOT ADDED SCOPE CHECK)
            if (
                    !$ThisVar -or # if variable exists
                    $ThisVar.Gettype().Name.ToString() -ne $hash.Type -or # if the datatype is equal
                    # Add scope check
                    [bool](diff ($ThisVar|ConvertTo-Json) ($hash.value |ConvertTo-Json) ) # if there are a diff i value
                ){
                if ($hash.Scope) {
                    Set-Variable -Name $Key -Value $hash.Value -Scope $hash.Scope
                }else {
                    Set-Variable -Name $Key -Value $hash.Value -Scope Global
                }
            }
        } # End of update
    }
    END{
        Write-Verbose "End of Update-PersistentData"
    }
}

Function Show-PersistentData {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Vault=$PDDefaultVault,
        [switch]
        $AllLists,
        [switch]
        $AllListsAndAllData
    )
    Begin{}
    Process {
        if($AllLists){$Script:PDSettings.Vault.Keys}
        elseif($AllListsAndAllData){
            Show-PersistentData -AllLists | Show-PersistentData
        }
        else{
            Write-Warning "Containing inside of $vault"
            $Script:PDSettings.Vault.$Vault.List
        }
    }
    End {}
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
    Process {
        Foreach ($Nam in $name) {
            Set-PersistentData -Remove -Name $Nam
        }
    }
}

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

# Update all variables
Update-PersistentData
if ($Script:PDSettings.Data.$PDDefaultVault.StartWatcher.Value) {
    if ($Script:PDSettings.Data.$PDDefaultVault.StartWatcherQuiet.Value){
        @($Script:PDSettings.Data.$PDDefaultVault.StartWatcher.Value) | % { Set-PersistentData -StartWatcher -Path $_ -Quiet}
    }else {
        @($Script:PDSettings.Data.$PDDefaultVault.StartWatcher.Value) | % { Set-PersistentData -StartWatcher -Path $_}
    }
}

Export-ModuleMember -Function Set-PersistentData,Update-PersistentData,Remove-PersistentData,Show-PersistentData -ErrorAction Ignore