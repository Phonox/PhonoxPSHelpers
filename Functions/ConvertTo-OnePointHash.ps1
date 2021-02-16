Function ConvertTo-OnePointHash {
<#
.SYNOPSIS
This function is a helper to search huge lists by creaing hash/dictionaries
.DESCRIPTION
When you have a lists of +1000 each and trying to look for same properites for instance
While any other loop takes too much time to process this is a great asset
.Example
$First = ConvertTo-OnePointHash $listOne ID
$Second = ConvertTo-OnePointHash $listTWO ID
foreach ($key in $first.keys) {
    if ( ! $Second.$key)  {
        # This is not present in $First
    }else{
        if ($First.$key.SomeOption -ne $Second.$Key.SomeOption) {
            # This property has been changed
        }
    }
} # This is a way to use this to speed up 
#>
    [Cmdletbinding()]
    Param(
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [array]$Array,
        [Alias("ID")] 
        $UniqueID,
        [switch]$OverWrite,
        [switch]$SkipCheck
    )
    Begin{
        Write-Verbose "Starting ConvertTo-OnePointHash"
        $Hash = @{}
        $start = [datetime]::Now
        $int = 0
        $TimesOverWritten = 0
    }
    Process{
        if ($SkipCheck) {
            $Array.foreach{
                $int++
                $hash[$_.$UniqueID] = $_
                if ($PSBoundParameters.Verbose) {
                    if ( ( $int % 3000) -eq 0 ) {
                        $end = [dateTime]::Now
                        $diff = ($end - $start).ToString()
                        Write-Host Item $int time past $diff
                    }
                }
            }
        }else {
            $test = $Array[0] | Get-Member -MemberType Properties | Where-Object Name -eq $UniqueID
            if (!$test) {Throw "Missing or incorrect parameter $UniqueID"}

            $Array.foreach{
                $int++
                # if ($SkipCheck) in pipeline takes even more time to process compared to the code above
                if ($hash[$_.$UniqueID] ) {
                    if ($OverWrite) {
                        $TimesOverWritten++
                    }else {
                        Throw "UniqueID Is not Unique! Tried to overwrite $($_.$UniqueID), Add -OverWrite as parameter to continue"
                    }
                }
                $hash[$_.$UniqueID] = $_
                if ($PSBoundParameters.Verbose) {
                    if ( ( $int % 3000) -eq 0 ) {
                        $end = [dateTime]::Now
                        $diff = ($end - $start).ToString()
                        Write-Host Item $int time past $diff
                    }
                }
            }
        }
    }
    End{
        $hash # return object
        if ($PSBoundParameters.Verbose) {
            $end = [dateTime]::Now
            $diff = ($end - $start).ToString()
            if ($OverWrite) { Write-Host "Time overwritten $TimesOverWritten" }
            Write-Verbose "ConvertTo-OnePointHash took $diff - Items handled $int"
        }
    }
}
Export-ModuleMember -Function ConvertTo-OnePointHash