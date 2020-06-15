Function Get-ChildItemSize {
    <#
    .SYNOPSIS
    Changes the normal Get-ChildItem to display Length on folders aswell
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [Alias("lss")]
    Param(
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string[]]$Path = ".\"
    )
    Begin{
        # COULD PUT THIS TO THE IMPORT OF THE MODULE! Update-FormatData -PrependPath @org
        # Got some EPIC help from /u/brolifen @reddit
        $FormatXml = "$PSScriptRoot\..\ps1xml\FileSystem.format.ps1xml"
        $org = "$pshome\FileSystem.format.ps1xml"
        if ( !(test-path $FormatXml) ) {
            if ( !(Test-Path $org) ) {Write-Error -ErrorAction stop "File cannot be found: $org" }
            if ( !(test-path (Split-Path $FormatXml) ) ) {
                mkdir -Force (Split-Path $FormatXml)
            }
            Copy-Item -Force $org $FormatXml
            #Write-Error -ErrorAction stop "File cannot be found: $FormatXml"
        }
        Update-FormatData -PrependPath $FormatXml
        #$orgi = cat $org -Raw
        #Update-FormatData -PrependPath $org  #does not work correctly
        #Update-FormatData -PrependPath @orgi #does not work correctly
    }
    Process{
        Foreach ($P in $Path ) {
        $PSBoundParameters.Path = $p
            Get-ChildItem @PSBoundParameters | ForEach-Object {
                if( $_.Attributes -like "*Directory*" ){ 
                    $Size = (Get-ChildItem $_.Fullname -Recurse -Force -ea Ignore -File| Measure-Object Length -sum | Select-Object -ExpandProperty sum )
                    if (!$size){$size = 0}
                    Add-Member -InputObject $_ -MemberType NoteProperty -Name 'Length' -Value $size
                    $_
                } else{$_}
            }
        }
    }
    End{       
    }
}

#New-Alias -Name lss -Value Get-ChildItemSize
Export-ModuleMember -Function Get-ChildItemSize -alias lss