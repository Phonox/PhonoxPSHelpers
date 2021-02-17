$pathPublic = Join-Path $PSScriptRoot  "Functions"
$pathSnippet = Join-Path $PSScriptRoot "ISESnippets"
Get-ChildItem $pathPublic/*psm1, $pathPublic/*ps1 |
Where-Object { $_.Name -notmatch "\.test.?\.ps1$|\.test.?\.psm1$" } | Sort-Object -Descending |
ForEach-Object -Begin { $total = 0 } `
  -Process {
  Try {
    Import-Module $_.FullName -DisableNameChecking -errorAction Stop #-Verbose
    Write-Verbose "Imported $_"
    $total++
  } Catch {write-error $_}
} `
  -End {
  Write-Warning "Imported $total files."
}

if ([bool]$host.PrivateData.window ) {
  Import-IseSnippet $pathSnippet -Recurse
  Get-ChildItem $pathSnippet | 
  ForEach-Object -Begin { "Importing files:"; $total = 0 } `
    -Process {
    $total++; 
    Write-Verbose "Imported $_"
  } `
    -End {
    Write-Verbose "Imported $total files."
    (Get-command -Module PhonoxsPSHelpers -CommandType all | Measure-Object).count
  }
}

if (get-module PhonoxsPSHelpers) {
  Update-PersistentData
  if ($PersistentDataJobs) {Start-PersistentDataJobs}
}