Function Convert-ISESnippets {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string[]]
        [ValidateNotNullOrEmpty()]
        [Alias("PSPath")]
        $Path,
        [string]$Destination
    )
    Begin {
        $ProcessedFiles = 0
        $ErrorActionPreference = "Stop"
    }
    Process {
        $Paths = $Path
        Foreach ($Path in $Paths) {
            if (! (Test-path $Path) ) { Write-Error "file path is non existing: $Path"}
            [xml]$Content = Get-Content $Path -Raw
            $body = $Content.snippets.snippet.code.script."#cdata-section" -split "`r?`n" # splitting for readability
            $Snippet = @{}
            $title = $Content.snippets.snippet.header.Title
            $Snippet.$title = @{}
            $Snippet.$title.description = $Content.snippets.snippet.header.Description
            $Snippet.$title.scope = "powershell"
            $Snippet.$title.prefix = $title -replace '-',' '
            $Snippet.$title.body = $body -replace "\$","\$"
            $JsonSnippet = $Snippet | ConvertTo-Json
            
            #Test
            $JsonSnippet | ConvertFrom-Json | Out-Null
            
            $FileName = (Split-Path -Leaf $Path) -replace 'ps1xml$','code-snippets'
            if (!$Destination) {
                $NewPath = Join-Path (Convert-Path (Split-Path -Parent $Path) ) $FileName
            }else{
                $NewPath = Join-Path (Convert-Path $Destination ) $FileName
            }
            $Proceed = $true
            if (test-path $NewPath) {
                if ( $PSCmdlet.ShouldProcess($NewPath, "Overwrite") ) {
                    $Proceed = $true
                }else {
                    $Proceed = $false
                }
            }
            if ($Proceed) {
                $JsonSnippet | Out-File -Encoding utf8 -FilePath $NewPath
                $ProcessedFiles++
            }
        }
    }
    End{
        Write-Host "Processed $ProcessedFiles files."
    }
}
# Get-ChildItem -File ../ISESnippets |? Name -match 'ps1xml$' | Convert-ISESnippets -Destination "../.vscode"
Export-ModuleMember -function Convert-ISESnippets
