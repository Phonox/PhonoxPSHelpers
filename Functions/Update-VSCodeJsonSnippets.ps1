
Function Update-VSCodeJsonSnippets {
<#
.Synopsis
   Update vscode snippets globaly instead of just in THIS Modules workspace.
.DESCRIPTION
   If you never have created an vscode extention and does not have the time for now #postponingTheInevitable
   Enter the path to .code-snippet folder, such as this modules folder .\.vscode
   They will be saved to 
.EXAMPLE
   Update-VSCodeJsonSnippets ./.vscode # On MacOS
Items Found: 4
Total: 4, Existing: 0, Added: 0, Updated: 4
.EXAMPLE
   Update-VSCodeJsonSnippets .\.vscode\ # On PC
Items Found: 4
Total: 4, Existing: 0, Added: 0, Updated: 4
.EXAMPLE
   Update-VSCodeJsonSnippets .\.vscode\ Remove # On PC
Items Found: 4
Total: 4, Existing: 0, Removed: 4
.NOTES
   Future updates requires me to create an extention instead.
#>
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(ValueFromPipeline,
                   ValueFromPipelineByPropertyName,
                   ValueFromRemainingArguments=$false,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        #Help about this parameter
        [Alias("PSPath","FullName")]
        $Path,
        [Parameter(ValueFromPipelineByPropertyName,
                   ValueFromRemainingArguments=$false,
                   Position=1)]
        [ValidateSet("Add","Remove")]
        [string[]]$State = "Add"
    )
    Begin{
        if ( $IsLinux -or $IsMacOS -or $IsWindows) {
            if ($IsLinux)   {$VsCodePath = "$HOME/.config/Code/User/snippets/(language).json" }
            if ($IsMacOS)   {$VsCodePath = "$HOME/Library/Application Support/Code/User/snippets/(language).json" }
            if ($IsWindows) {$VsCodePath = "$ENV:appdata\Code\User\snippets\(language).json" }
        }else {
            $VsCodePath = "$ENV:appdata\Code\User\snippets\(language).json"
        }
        $AllFiles = [System.Collections.ArrayList]@()
    }
    Process{
        $Paths = $Path
        foreach ($Path in $Paths) {
            switch (get-item $Path -ea stop -Force ) {
                { Check-FileAttributes $_ Directory } { Get-ChildItem -Force $Path |? {$_.Name -match "code-snippets$"} | Select -Expand FullName | Update-VSCodeJsonSnippets -state $state ; return "" }
                { $_.Name -match "\.code-snippets$" } { $AllFiles.Add( ( Get-Content -Force $_ -raw |ConvertFrom-Json ) ) | Out-Null ; break }
                Default {Write-Error "Not correct input, requires .code-snippets"}
            }
        }
    }
    End{
        if ($AllFiles) {
            Write-Host "Items Found: $($AllFiles.count)"
            $rewroteJson = [System.Collections.ArrayList]@()
            foreach ( $json in $AllFiles ) {
                $GM    = $json |Get-Member
                $Title = ($GM.where( {$_.MemberType -eq 'NoteProperty' } ) ).Name
                $GM    = $json.$Title |Get-Member
                $rest  = ($GM.where( {$_.MemberType -eq 'NoteProperty' } ) ).Name
                $hash =@{ Title = $title }
                foreach ($member in $rest)
                {$hash.$member = $json.$title.$member}
                $rewroteJson.add([PSCustomObject]$hash) | Out-Null
            }
            $Added    = 0
            $Existing = 0
            $Removed  = 0
            $Updated  = 0
            foreach ($group in ($rewroteJson |group scope) ) {
                $VSScopePath = $VsCodePath -replace "\(language\)",$group.Name
                if (test-path $VSScopePath) {
                    $CurrentScopeFile = Get-Content -raw $VSScopePath |ConvertFrom-Json
                }else{
                    $CurrentScopeFile = "" |ConvertTo-Json
                }
                $AddToThisGroupTitle = $group.Group.Title
                $CurrentTitles = ($CurrentScopeFile|Get-Member |? MemberType -eq 'NoteProperty').Name
                $updatedJsonFile = "{`n"
                $AllAccounted = ( $AddToThisGroupTitle + $CurrentTitles | Sort-Object -Unique ).Count
                foreach ($obj in $AddToThisGroupTitle ) {
                    switch ($State) {
                        'Add'    {
                            if ($CurrentScopeFile.$obj) {
                                $updated++
                            } else {
                                $added++
                            }
                            $data = $AllFiles.$obj |ConvertTo-Json ; 
                            $startofSub = $data.IndexOf('{') ; 
                            $EndOfSub = ( $data.LastIndexOf('}') + 1 - $data.IndexOf('{') ) ; 
                            $SubData = $data.substring($StartOfSub,$EndOfSub) ;
                            $total = $Added+$Existing+$updated+$removed
                            if ( $total -lt $AllAccounted ) { $comma = "," }else {$comma = ""}
                            $updatedJsonFile +=  "`"$obj`": $SubData$comma " 
                            break
                        }
                        'Remove' { $Removed++ ; break } # Do nothing
                    }
                }
                $CurrentNotFromFile = ($CurrentScopeFile| Get-Member |Where-Object { $_.MemberType -eq "NoteProperty" -and $_.Name -notIn $AddToThisGroupTitle }).Name
                foreach ($obj in $CurrentNotFromFile ) { # Add the rest
                    $Existing++
                    $data = $CurrentScopeFile.$obj |ConvertTo-Json ; 
                    $startofSub = $data.IndexOf('{') ; 
                    $EndOfSub = ( $data.LastIndexOf('}') + 1 - $data.IndexOf('{') ) ; 
                    $SubData = $data.substring($StartOfSub,$EndOfSub) ;
                    $total = $Added+$Existing+$updated+$removed
                    if ( $total -lt $AllAccounted ) { $comma = "," }else {$comma = ""}
                    $updatedJsonFile +=  "`"$obj`": $SubData$comma "
                }
                $updatedJsonFile += "`n}"
                $updatedJsonFile | ConvertFrom-Json | Out-Null
                $updatedJsonFile | Out-File -Encoding utf8 $VSScopePath
            } # End of group scope
            $total = $Added+$Existing+$updated+$removed
            switch ($state) {
                'Add'    {Write-Host "Total: $total, Existing: $Existing, Added: $Added, Updated: $Updated"}
                'Remove' {Write-Host "Total: $total, Existing: $Existing, Removed: $Removed"}
            }
        }
    }
}

# Update-VSCodeJsonSnippets ../.vscode
Export-ModuleMember -Function Update-VSCodeJsonSnippets