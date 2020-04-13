
Function Write-FancyMessage{
<#
.Synopsis
   A easy way to get a more fany way to print messages
.DESCRIPTION
   A easy way to get a more fany way to print messages
.EXAMPLE
   Write-FancyMessage "test"
********
* test *
********
.EXAMPLE
Write-FancyMessage "test" -BackgroundColor Green -ForegroundColor DarkYellow
********
* test *
********
.INPUTS
   Strings[]
#>
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(ValueFromPipeline,
                   ValueFromPipelineByPropertyName,
                   ValueFromRemainingArguments=$false,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
		#Text you want to have Fancy
        [string[]]$Object,
        [System.ConsoleColor]
        $ForegroundColor,
        $BorderChar = "*",
        [Switch]$NoNewLine,
        [System.ConsoleColor]
        $BackgroundColor
    )
    Begin{
        $Length = 0
        $AllStrings = [System.Collections.ArrayList]@()
    }
    Process{
        Foreach ($str in $Object) {
            if ($Length -lt $str.Length) {
                $Length = $str.Length
            }
            $AllStrings.Add( $str) | Out-Null
        }
    }
    End{
        $PSBoundParameters.Remove("Object") |out-null
        $PSBoundParameters.Remove("BorderChar") |out-null
        $CharRepeat = $BorderChar * ($Length + 4 )
        Write-Host $CharRepeat @PSBoundParameters
        $AllStrings | % {
            Write-Host "$BorderChar $_$( 
                $i = [int]($Length - $_.Length) ;
                if ($i -gt 0) {' ' * $i} ) $BorderChar" @PSBoundParameters }
        Write-Host $CharRepeat @PSBoundParameters
    }
}
Export-ModuleMember Write-FancyMessage