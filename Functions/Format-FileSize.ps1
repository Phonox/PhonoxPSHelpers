Function Format-FileSize {
    <#
    .SYNOPSIS
    Change the display of size, but still the same output
    #>
    [cmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]    
        [int64]$size
    )
    If     ($size -gt 1TB) {[string]::Format("{0:0.00} TB", $size / 1TB)}
    ElseIf ($size -gt 1GB) {[string]::Format("{0:0.00} GB", $size / 1GB)}
    ElseIf ($size -gt 1MB) {[string]::Format("{0:0.00} MB", $size / 1MB)}
    ElseIf ($size -gt 1KB) {[string]::Format("{0:0.00} kB", $size / 1KB)}
    ElseIf ($size -gt 0)   {[string]::Format("{0:0.00} B", $size)}
    Else                   {""}
}
Export-ModuleMember -Function Format-FileSize