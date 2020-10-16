Function Format-FileSize {
    <#
    .SYNOPSIS
    Change the display of size, but still the same output
    #>
    [cmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]    
        [int64]$Length
    )
    Process {
        if ($Length -lt 1) {
            return "$Length`B"
        }
        
        #switch -Regex ([math]::truncate([math]::log($Length,1024))) {
        #    '^0' {"$Length B"}
        #    '^1' {"{0:n2} KB" -f ($Length / 1KB)}
        #    '^2' {"{0:n2} MB" -f ($Length / 1MB)}
        #    '^3' {"{0:n2} GB" -f ($Length / 1GB)}
        #    '^4' {"{0:n2} TB" -f ($Length / 1TB)}
        #     Default {"{0:n2} PB" -f ($Length / 1pb)}
        #}
        
        If ($Length -gt 1TB) { [string]::Format("{0:0.00}TB", $Length / 1TB) -replace ",","." }
        ElseIf ($Length -gt 1GB) { [string]::Format("{0:0.00}GB", $Length / 1GB) -replace ",","." }
        ElseIf ($Length -gt 1MB) { [string]::Format("{0:0.00}MB", $Length / 1MB) -replace ",","." }
        ElseIf ($Length -gt 1KB) { [string]::Format("{0:0.00}KB", $Length / 1KB) -replace ",","." }
        ElseIf ($Length -gt 0) { [string]::Format("{0:0.00}B", $Length) -replace ",","." }
        Else { $Length }
    }
}
Export-ModuleMember -Function Format-FileSize