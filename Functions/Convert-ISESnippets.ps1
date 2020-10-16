Function Convert-ISESnippets {
    <#
    .SYNOPSIS
        Ease the convert from ISE to VS Code if you got your own snippets
    .DESCRIPTION
        Convert ISE snippets to vs code format to same folder or specific (-Destination) folder
    .EXAMPLE
        Convert-ISEsnippets -Path ./ISESnippets/ -Destination ./.vscode/
        Processed 6 files.
    .EXAMPLE
        Convert-ISEsnippets -Path ./ISESnippets/
        Processed 6 files.
    .NOTES
        General notes
    #>
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        [ValidateNotNullOrEmpty()]
        #[Alias("PSPath")]
        [string[]]
        $Paths,
        [string]$Destination
    )
    Begin {
        $ProcessedFiles = 0
        $ErrorActionPreference = "Stop"
        $ProcessFiles = @()
    }
    Process {
        $Pathss = @(Convert-Path $Paths)
        foreach ($Path in $pathss ) {
            if (Check-FileAttributes $Path Directory) { $ProcessFiles += Get-ChildItem -Force $Path | Where-Object { $_.Name -match 'ps1xml$' } }
            elseif ( $Path -match 'ps1xml$' ) { $ProcessedFiles += $Path }
            else { Write-Error "Files is not correct file format: $Path" }
        }
        Foreach ($Path in $ProcessFiles) {
            if (! (Test-path $Path) ) { Write-Error "file path is non existing: $Path" }
            [xml]$Content = Get-Content $Path -Raw -force
            $body = $Content.snippets.snippet.code.script."#cdata-section" -split "`r?`n" # splitting for readability
            $Snippet = @{}
            $title = $Content.snippets.snippet.header.Title
            $Snippet.$title = @{}
            $Snippet.$title.description = $Content.snippets.snippet.header.Description
            $Snippet.$title.scope = "powershell"
            $itemsToAddToPrefix = ( ( $title -replace '-', ' ' ), ( ($title -replace 'version' -split '\W' | Select-Object -skip 1 | Where-Object { $_ }) -join ',' ) -join ',' ) -split ","
            $Snippet.$title.prefix = $itemsToAddToPrefix
            $Snippet.$title.body = $body -replace "\$", "\$"
            $JsonSnippet = $Snippet | ConvertTo-Json
            
            #Test
            $JsonSnippet | ConvertFrom-Json | Out-Null
            
            $FileName = (Split-Path -Leaf $Path) -replace 'ps1xml$', 'code-snippets'
            if (!$Destination) {
                $NewPath = Join-Path (Convert-Path (Split-Path -Parent $Path) ) $FileName
            }
            else {
                $NewPath = Join-Path (Convert-Path $Destination ) $FileName
            }
            $Proceed = $true
            if (test-path $NewPath) {
                if ( $PSCmdlet.ShouldProcess($NewPath, "Overwrite") ) {
                    $Proceed = $true
                }
                else {
                    $Proceed = $false
                }
            }
            if ($Proceed) {
                $JsonSnippet | Out-File -Encoding utf8 -FilePath $NewPath
                $ProcessedFiles++
            }
        }
    }
    End {
        Write-Host "Processed $ProcessedFiles files."
    }
}
Export-ModuleMember -function Convert-ISESnippets
