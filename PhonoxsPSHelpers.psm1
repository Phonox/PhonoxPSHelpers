$pathPublic = "$PSScriptRoot\Functions"
$pathSnippet = "$PSScriptRoot\ISESnippets"
get-childitem $pathPublic\*psm1,$pathPublic\*ps1 |
  ?{$_.Name -notmatch "\.test.?\.ps1$|\.test.?\.psm1$"} | Sort -Descending |
  % -Begin {"Importing files:";$total = 0} `
    -Process {
          $total++; 
          Import-Module $_.FullName -DisableNameChecking #-Verbose
          Write-Verbose "Imported $_"
      } `
    -End {
      Write-Warning "Imported $total files."
      (Get-command -Module PhonoxsPSHelpers -CommandType Function |Measure-Object).count
    }

if ([bool]$host.PrivateData.window ) {
  Import-IseSnippet $pathSnippet -Recurse
  Get-ChildItem $pathSnippet | 
  % -Begin {"Importing files:";$total = 0} `
    -Process {
      $total++; 
      Write-Verbose "Imported $_"
    } `
    -End {
      Write-Verbose "Imported $total files."
      (Get-command -Module PhonoxsPSHelpers -CommandType all |Measure-Object).count
    }
}