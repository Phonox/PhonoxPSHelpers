#$cont = gc $MyInvocation.MyCommand.source
# eller path

function stuff ($content,$maachers = "\s+$",[string]$Message = "Trailing white space ending") {
    Begin{$LotsOfMatchers = @()}
    Process {
        for([int]$int=0;$int -lt $content.count;$int++){
            if($content[$int] -match $maachers) {
                $hash = [PSCustomObject]@{
                    Message  = $Message
                    Line     = $($int + 1)
                    Matching = $maachers
                    Info     = $content[$int]
                }
                $LotsOfMatchers += $hash
            }
        }
    }
    End {$LotsOfMatchers |sort Line}
}

function trailingWhiteSpace ($content){
    stuff -content $content -maachers "\s+$" -Message "Trailing white space ending"
}

function PSEnvironmentVariable ($content){
    stuff -content $content -maachers "Matches\ *=" -Message "Trailing white space ending"
}

function SWEDDOCNumbering ($content){
    stuff -content $content -maachers "[\w\.\d]+ *#\." -Message "Numbering requires newrow/carrige return"
}

function SWEDDOCNotesAndSimilar ($content){
    stuff -content $content -maachers "(?!^)\ *(?!\.)\.\.\ (?!(\w|_|-|``)+\:\:)" -Message "Label missing on note,warning or similar"
}


Function Run-PowerLint ([ValidateNotNullOrEmpty()][string]$Path, [ValidateSet("All","trailingWhiteSpace","PSEnvironmentVariable","SWEDDOCNumbering","SWEDDOCNotesAndSimilar")]$OptionsToRun = "All") {
    Begin {
        $all = @(); 
        if ( (pwd) -ne $path ) { Push-Location -Path $Path -ea ignore } ; 
        $Global:PowerLint = $null
    }
    Process {
        $files = gci .\ -Recurse -ea Ignore -File |? Name -notmatch 'png$|jpg$|gif$|exe$|old$|xml$|md$|iso$|mds$|chm$|log$|mdb$|7z$'
        #|? Name -Match "ps1$|psm1$|psd1$"
        # Find trailing WhiteSpace
        foreach ($file in $files) {
            $content = gc $file.FullName -ea Ignore
            
            if ("All" -in $OptionsToRun) {
                $all += trailingWhiteSpace $content       | select Message,Line,Matching,@{N='File';E={Resolve-Path -Relative $file.FullName} },Info
                $all += SWEDDOCNumbering $content         | select Message,Line,Matching,@{N='File';E={Resolve-Path -Relative $file.FullName} },Info
                $all += SWEDDOCNotesAndSimilar $content   | select Message,Line,Matching,@{N='File';E={Resolve-Path -Relative $file.FullName} },Info
                $all += PSEnvironmentVariable $content   | select Message,Line,Matching,@{N='File';E={Resolve-Path -Relative $file.FullName} },Info
            }
            else{
                if ("trailingWhiteSpace"     -in $OptionsToRun) {$all += trailingWhiteSpace $content     | select Message,Line,Matching,@{N='File';E={Resolve-Path -Relative $file.FullName} },Info}
                if ("SWEDDOCNumbering"       -in $OptionsToRun) {$all += SWEDDOCNumbering $content       | select Message,Line,Matching,@{N='File';E={Resolve-Path -Relative $file.FullName} },Info}
                if ("SWEDDOCNotesAndSimilar" -in $OptionsToRun) {$all += SWEDDOCNotesAndSimilar $content | select Message,Line,Matching,@{N='File';E={Resolve-Path -Relative $file.FullName} },Info}
                if ("PSEnvironmentVariable"  -in $OptionsToRun) {$all += PSEnvironmentVariable $content  | select Message,Line,Matching,@{N='File';E={Resolve-Path -Relative $file.FullName} },Info}
            }
            #Switch ($OptionsToRun) {
            #    "trailingWhiteSpace" {$all += trailingWhiteSpace $content | select Message,Line,Matching,@{N='File';E={Resolve-Path -Relative $file.FullName} },Info}
            #    "SWEDDOCNumbering"   {$all += SWEDDOCNumbering $content   | select Message,Line,Matching,@{N='File';E={Resolve-Path -Relative $file.FullName} },Info}
            #    "All"                {
            #                         $all += trailingWhiteSpace $content | select Message,Line,Matching,@{N='File';E={Resolve-Path -Relative $file.FullName} },Info
            #                         $all += SWEDDOCNumbering $content   | select Message,Line,Matching,@{N='File';E={Resolve-Path -Relative $file.FullName} },Info
            #                         }
            #}
            
        }
    }
    End {
        #$all |sort File,Line |ft -AutoSize |out-host ; Write-Host "Total:" $all.Count ; Pop-Location ; $Global:PowerLint = $all
        $all |sort File,Line |ft -AutoSize ; Write-Host "Total:" $all.Count ; Pop-Location ; $Global:PowerLint = $all
    }
}

Function Start-PowerLint ([ValidateNotNullOrEmpty()][string[]]$path = ".\") {
    #$newPath = (Resolve-Path $path ).Path
    #Register-Watcher -Folder (Resolve-Path $NewPath ).Path -ActionChanged  {Run-PowerLint -path $NewPath }
    Register-Watcher -Folder $Path -ActionChanged  {Run-PowerLint -path $Path }
    #Run-PowerLint -path $path
}
try {Export-moduleMember -function Run-PowerLint,Start-PowerLint -ErrorAction stop}
catch {}