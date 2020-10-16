
Function Check-FileAttributes {
    <#
    .SYNOPSIS
    Sometimes windows FS, will show an int instead of string on the enumeration of System.IO.FileAttributes
    .DESCRIPTION
    Sometimes windows FS, will show an int instead of string on the enumeration of System.IO.FileAttributes
    which this will fix to show slightly better
    .EXAMPLE
    Check-FileAttributes ..\PhonoxsPSHelpers.psd1 Archive
    True
    .EXAMPLE
    Check-FileAttributes ..\PhonoxsPSHelpers.psd1 Directory
    False
    .EXAMPLE
    Check-FileAttributes ..\PhonoxsPSHelpers.psd1
    Archive, ReparsePoint
    .EXAMPLE
    Check-FileAttributes ..\PhonoxsPSHelpers.psd1 -ToString
    Archive, ReparsePoint
    .OUTPUTS
    [Bool]
    [System.IO.fileattributes]
    [String]
    #>
    [CmdletBinding(DefaultParameterSetName = 'FileAttributes')]
    Param(
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "FileAttributes")]
        [System.IO.FileAttributes]$FileAttributes,
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "FileInfo")]
        [System.IO.FileInfo]$FileInfo,
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "DirectoryInfo")]
        [System.IO.DirectoryInfo]$DirectoryInfo,
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "Path")]
        [string]$Path,

        [Parameter(Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileAttributes]$ShouldContain,

        [Parameter(Position = 2, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [switch]$ToString
    )
    Begin {}
    Process {
        $ProcessFile = $null
        switch ($PsCmdlet.ParameterSetName) {
            'FileAttributes' { $ProcessFile = $FileAttributes ; Break }
            'FileInfo' { $ProcessFile = $FileInfo.Attributes ; Break }
            'DirectoryInfo' { $ProcessFile = $DirectoryInfo.Attributes ; Break }
            'Path' { $PSBoundParameters.Remove("Path") | Out-Null ; Get-item -force $Path | Check-FileAttributes @PSBoundParameters ; return; }
            Default {}
        }
        $Contains = $null
        foreach ($ob in ( [system.enum]::GetValues( [System.IO.FileAttributes] ) ) ) {
            switch ( $ProcessFile -band $ob ) {
                { $_ -eq $ShouldContain -and $ShouldContain } { return $true }
                { !$ShouldContain -and $_ } { $Contains += $_ }
            }
        }
        switch ($ShouldContain) {
            { $_ } { return $false }
            { !$_ } { 
                switch ([bool]$ToString) {
                    { $_ } { $Contains.ToString() }
                    { !$_ } { $Contains }
                }
            }
        }
    }
    End {}
}

Export-ModuleMember -Function Check-FileAttributes