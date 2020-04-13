#if (!$WhoWatchesTheWatchers) {
#    $WhoWatchesTheWatchers = @()
#}
Function Register-Watcher {
    param(
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_ -IsValid ) -and (Get-Item $_ ).PSIsContainer})]
        $Folder,
        $Filter = "*.*",
        [scriptblock]$ActionChanged,
        [scriptblock]$ActionCreated,
        [scriptblock]$ActionDeleted,
        [scriptblock]$ActionRenamed,
        [scriptblock]$ActionAll,
        [switch]$Quiet
    )
    Begin {
        #$fileChange = [Enum]::GetValues([system.io.WatcherChangeTypes])
    }
    Process {
        if (!$ActionChanged -and !$ActionCreated -and !$ActionDeleted -and !$ActionRenamed -and !$ActionAll){"Missing Scriptblock!" ; break}
        [System.IO.FileSystemWatcher]$watcher = New-object IO.FileSystemWatcher $folder,$filter -property @{
            IncludeSubDirectories = $true
            EnableRaisingEvents = $true
        } #NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite, DirectoryName'
        #if ($ActionChanged) {$watcher.Changed += $ActionChanged}
        #if ($ActionCreated) {$watcher.Created += $ActionCreated}
        #if ($ActioDeleted ) {$watcher.Deleted += $ActionDeleted}
        #if ($ActionRenamed) {$watcher.Renamed += $ActionRenamed}
    
        $ChangeAction = [scriptblock]::Create('
            $Path       = $Event.SourceEventArgs.FullPath
            $RelativePath= Resolve-Path -Relative $path
            $Name      = $Event.SourceEventArgs.Name
            #$Name       = Split-Path -Path $path -leaf
            $ChangeType = $Event.SourceEventArgs.ChangeType
            $TimeStamp  = $Event.TimeGenerated.ToString("yyyy-MM-dd HH:mm:ss")
            #Kontroller för att slippa dubbla notifications
            if (!$Lastupdate) { $LastUpdate = @{} }
            if ( ($TimeStamp -eq $LastUpdate.$Path ) ) {return 1}
            $LastUpdate.$Path = $TimeStamp
            Start-Sleep -Milliseconds ( Get-Random -Minimum 0 -Maximum 15)
            '
        )
        #. "D:\sweccis\_new\verktyg\PowerShellTools\ToolsForSkynet\PowerShellHelpers\Public\PowerLint.ps1"
        $ChangeAction = [ScriptBlock]::Create("
        $ChangeAction
        If (!`$$Quiet) {
            Write-Host -ForegroundColor Red `"`n`$timeStamp `$changeType a file:`"
            #Write-Host -ForegroundColor Cyan `$RelativePath
            Write-Host -ForegroundColor Cyan `$Path;
        }
        Try {
        switch (`$ChangeType) {
            Created {$ActionCreated }
            Deleted {$ActionDeleted }
            Changed {$ActionChanged } 
            Rename  {$ActionRenamed }
        }
        #ActionALL
        $ActionAll
        #End OF ActionALL
        } Catch {Write-Error $_}
        
        If (!`$$Quiet) {
            write-host ''
            prompt *>&1
            Write-Host ''
        }
        ")
        
        if     ($ActionChanged) {Register-ObjectEvent $watcher "Changed" -Action $changeAction } # -SourceIdentifier "FileChanged" }
        elseif ($ActionCreated) {Register-ObjectEvent $watcher "Created" -Action $changeAction } # -SourceIdentifier "FileCreated" }
        elseif ($ActionDeleted) {Register-ObjectEvent $watcher "Deleted" -Action $changeAction } # -SourceIdentifier "FileDeleted" }
        elseif ($ActionRenamed) {Register-ObjectEvent $watcher "Renamed" -Action $changeAction } # -SourceIdentifier "FileRenamed" }
        elseif ($ActionAll)     {Register-ObjectEvent $watcher "Changed" -Action $changeAction } # -SourceIdentifier "FileRenamed" }
    }
    End{}
}

Export-ModuleMember -function Register-Watcher