$Encoding = "UTF8"
# $PDDefaultVault = 'PDDefault'
if (!$ENV:Appdata) { $ENV:Appdata = ( [Environment]::GetFolderPath('ApplicationData') ) } # quickfix for MacOS
$PDDefaultPath = Join-Path $ENV:Appdata "PDDefault.json"
$PDDefaultRemove = 'PDDefaultRemove'
#$PDDefaultPath = (Join-Path $env:TEMP "PDDefault.json")
Function Get-PersistentData {
    <#
.SYNOPSIS
    This is an internal helper for PD, will not be exported
#>
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [string]
        $Path = $PDDefaultPath
    )
    Begin {
        $start = [DateTime]::Now
        Write-Verbose "Start of Get-PersistentData"
    }
    Process {
            if ( !(Test-Path $path) ) { 
                Write-Warning "File Missing! $Path" ; 
            }
            while(!(Select-String -Path $path -Pattern '^]$')) {} # just wait till the file is done written
            $List = Get-Content $Path -Raw -Encoding $Encoding -Force | ConvertFrom-Json -EA Continue |foreach-Object { [PSCustomObject]$_ }
            if (!$list){Throw "Failed"}
            $RemoveIndex = ($list.Name).IndexOf($PDDefaultRemove)
            $RemoveValues = ConvertTo-OnePointHash @($list[$RemoveIndex].Value)

            $EditList = [System.Collections.ArrayList]@()
            for($int=0;$int -lt $list.count;$int++) {
                if ( $RemoveValues[$list[$int].Name] ){ Remove-Variable -Scope Global -Name $list[$int].Name -ea ignore}
                elseif ($int -eq $RemoveIndex){}
                else{ [void]$EditList.Add( $List[$int] ) }
            }

            foreach ($item in $EditList) {
                if ($item.Type -eq 'DateTime') { 
                    $item.Value = ([DateTime]($item.Value)).ToLocalTime()
                }else{
                    $item.Value = $item.Value -as "$($item.Type)"
                }
            }
        if (!$EditList) {continue}
    }
    End {
        #if ($Verbose) {
        $end = [DateTime]::Now
        Write-Verbose "Get-PersistentData took: $([int]($end - $start).TotalMilliseconds) ms"
        #}
        $EditList
        $EditList | Update-PersistentData
        Write-Verbose "End of Get-PersistentData"
    }
}
Function Update-PersistentData {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        $object
    )
    Process{
        if (!$object){Get-PersistentData | Update-PersistentData}
        elseif ($object.type -eq 'DateTime'){  
            Set-Variable -name $object.Name -scope $object.Scope -value $object.value
        }else{
            Set-Variable -name $object.Name -scope $object.Scope -value $object.value
        }
    }
}

Function ConvertTo-PersistentData {
<#
.SYNOPSIS
Helper to convert input to objects that will be processed
#>
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName)]
        $Name,
        [Parameter(ValueFromPipelineByPropertyName)]
        $Value,
        [Parameter(ValueFromPipelineByPropertyName)]
        $Scope,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$Remove,
        [Parameter(ValueFromPipelineByPropertyName)]
        $special,
        $Old)
    Begin{
        $NewEntries =@{}
    }
    Process{
        if ($NewEntries[$name]){Throw "More than one of the same entries! $name"}
        if ($Remove){
            if ( $old[$PDDefaultRemove] ) {
                $hash = [Ordered]@{
                    Name  = $PDDefaultRemove
                    Type  = "string[]"
                    Value = $old[$PDDefaultRemove].Value, $Name
                }
            }
            else{
                $hash = [Ordered]@{
                    Name  = $PDDefaultRemove
                    Type  = "string[]"
                    Value = $Name
                }
            }
            if ($Scope){$hash.Scope = $Scope}
        }else{
            $Type = $Value.GetType().Name
            if ($special){
                $ExistingValue = $old[$name]
                Switch($special){
                    "Add" {
                        switch ($type) {
                            'string'  { $type = "string[]" ; break}
                            'string[]'{  ; break}
                            'int'     {  ; break}
                            'int[]'   {  ; break}
                            'dateTime' {$type = "array"; break}
                            Default {}
                        }
                        $newValue = if ($ExistingValue){$ExistingValue , $Value}else{$Value}
                        break
                    }
                    "Sub" {
                        if (!$ExistingValue){continue}
                        if ($type -eq 'datetime') {$type = "array"}
                        Switch ($type) {
                            'string'  { $newValue = $ExistingValue -replace [regex]::Escape($Value) ; break}
                            'int'     { $NewValue = $ExistingValue - $Value ; break}
                            'dateTime' {$type = "array"; break}
                            Default {
                                $newCollection = [System.Collections.ArrayList]@()
                                $IndexOf = $ExistingValue.IndexOfAny($Value)
                                for($int=0;$int -lt $ExistingValue.count;$int++){
                                    if ($int -in $IndexOf){}
                                    else{ [void]$newCollection.add( $ExistingValue[$int] ) }
                                }
                                $NewValue = $newCollection -as $type
                            }
                        }
                        break
                    }
                }
                $hash = [Ordered]@{
                    Name  = $Name
                    Type  = $Type
                    Value = $newValue
                }
            }else{
                $hash = [Ordered]@{
                    Name  = $Name
                    Type  = $Type
                }
                
                # if ($item.Type -eq 'DateTime') {
                    # $Value = ( [DateTime]$item.Value ).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss") # or ToString('stuff')
                # }
                $hash.Value = $value
            }
        }
        $hash.Scope = $Scope
        $NewEntries.$Name = $hash
        [PSCustomObject]$hash
    }
    End{}
}

Function Set-PersistentData {
<#
.SYNOPSIS
    This will save a variable to disk.
.DESCRIPTION
    This feature was created to easily save variables to disk and then import the variables as they last were, and must work over other PS-instances. (if you have 4 instances of powershell, they should all have the same data)
.LINK
    Show-PersistentData
.LINK
    Set-PersistentData
    #>
    [CmdletBinding()]
    Param( 
        [Parameter(ValueFromPipelineByPropertyName,Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("N")]
        [string]$Name,

        [Parameter(ValueFromPipelineByPropertyName,Position=1)]
        [Alias("V")]
        $Value,

        [ValidateSet('Add','Subtract')]
        [Parameter(ValueFromPipelineByPropertyName,Position=2)]
        [Alias("S")]
        [String]$Special,

        [ValidateSet("Global", "Script", "Local", "Private")]
        [Parameter(ValueFromPipelineByPropertyName,Position=3)]
        $Scope = "Global",

        [Alias("R")]
        [Parameter(ValueFromPipelineByPropertyName)]
        [Switch]$Remove)
    Begin{
        $Packages = [System.Collections.ArrayList]@()
        $Old = Get-PersistentData | ConvertTo-OnePointHash -UniqueID name
    }
    Process{
        if (!$Name) {Continue}
        if ($Special -and !$Value) { Throw "Value is missing"}
        if ($Remove -or !$Value) {
            $switch = "Remove"
        }elseif($Special){
            $switch = "Special"
        }else{
            $switch = "Normal"
        }
        if(!$scope){$Scope = "global"}
        switch ($switch) {
            Normal {
                [void]$Packages.Add( ( [PSCustomObject]@{
                    Name = $name
                    Value = $Value
                    Scope = $Scope
                }) )
                break
            }
            Special{ 
                [void]$Packages.Add( ( [PSCustomObject]@{
                    Name = $name
                    Value = $Value
                    Scope = $Scope
                    Special = $special
                }) )
                Break
            }
            Remove {
                [void]$Packages.Add( ( [PSCustomObject]@{
                    Name = $name
                    Value = $Value
                    Scope = $Scope
                    Remove = $true
                } ) )
                break
            }
        }
    }
    End{
        $WriteToFile = $Packages| ConvertTo-PersistentData -Old $old | Replace-PersistentData -old $old
        $WriteToFile |ConvertTo-Json |Out-File -Encoding $Encoding -FilePath $PDDefaultPath
        [void](Update-PersistentData)
    }
}

Function Replace-PersistentData{
    [CmdletBinding()]
    Param(
        $Old,
        [Parameter(ValueFromPipeline)]
        [PSCustomObject]$object
    )
    Begin{
        $NewListCreation = [System.Collections.ArrayList]@()
        $NamesSoFar = [System.Collections.ArrayList]@()
    }
    Process{
        if($old[($object.name)]){
            $OldObject = $old[($object.name)]
            if ($OldObject.scope -ne $object.scope -or $OldObject.Type -ne $object.Type -or ($OldObject.value|ConvertTo-Json) -ne ($object.value |ConvertTo-Json) ) {
                if ($object.Type -eq 'DateTime') {
                    $object.value = ( [DateTime]($object.Value) ).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss") # or ToString('stuff')
                }
                [void]$NewListCreation.Add($object)
            } # else no change
        }else{ # New object
            if ($object.Type -eq 'DateTime') {
                $object.value = ( [DateTime]($object.Value) ).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss") # or ToString('stuff')
            }
            [void]$NewListCreation.Add($object)
        }
        [void]$NamesSoFar.Add( $object.name )
    }
    End{
        $hashNames = ConvertTo-OnePointHash $NamesSoFar
        foreach ($item in $old.GetEnumerator() ) {
            if ( ! $hashNames[($item.key)] ) {
                [void]$NewListCreation.Add( ($item.value) )
            }
        }
        $NewListCreation
    }
}

Function Show-PersistentData {
    Param($Path = $PDDefaultPath)
    Get-PersistentData -Path $PDDefaultPath |Sort-Object -Property Name | Format-Table Name,Type,Scope,Value -AutoSize
}
Function Remove-PersistentData{
    Param(
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string[]]$Name
    )
    Begin{
        $AllNames = [System.Collections.ArrayList]@()
    }
    Process{
        Foreach($N in $Name) {
            [void]$AllNames.Add( (
            [PSCustomObject]@{
                Name = $n
                Remove = $true
            } ) )
        }
    }
    End{
        $AllNames|Set-PersistentData
    }
}
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

Export-ModuleMember -Function Set-PersistentData, Update-PersistentData, Remove-PersistentData, Show-PersistentData, Start-PersistentDataJobs,Get-PersistentData -ErrorAction Ignore