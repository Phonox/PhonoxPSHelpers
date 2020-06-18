Function Format-FileSize {
    <#
    .SYNOPSIS
    Change the display of size, but still the same output
    #>
    [cmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]    
        [int64]$Length
    )
    Process{
        If     ($Length -gt 1TB) {[string]::Format("{0:0.00} TB", $Length / 1TB)}
        ElseIf ($Length -gt 1GB) {[string]::Format("{0:0.00} GB", $Length / 1GB)}
        ElseIf ($Length -gt 1MB) {[string]::Format("{0:0.00} MB", $Length / 1MB)}
        ElseIf ($Length -gt 1KB) {[string]::Format("{0:0.00} kB", $Length / 1KB)}
        ElseIf ($Length -gt 0)   {[string]::Format("{0:0.00} B", $Length)}
        Else                   {""}
    }
}
Export-ModuleMember -Function Format-FileSize