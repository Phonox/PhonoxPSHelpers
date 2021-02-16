#Requires -Modules Microsoft.Powershell.Utility
#Requires -Modules Microsoft.Powershell.Security
#Requires -Version 4

<#
.AUTHOR
    Patrik Svartholm / SWEDEN
.RELEASE
    2020-02-07
.VERSION
    1.4
.RELEASENOTES
    1.3 -> 1.4 Ändrat mindre viktiga varningar till Verbose
    1.3 -> 1.4 Skriver ut resultatet för alla filer
    1.3 -> 1.4 Create-Checksum/Verify-Checksum: Ändrar .Hash till .Path då pathen är unik tillskillnad till .hash genom att det kan finnas samma fil på fler ställen
    1.2 -> 1.3 VERIFY-Checksum: When there are other Algorithm presented, use the same on Create-Checksum
    1.2 -> 1.3 VERIFY-Checksum: If $Original contains less or equal to 1 column (READ: failes) to import correct data, stop the process and tell user to update script!
    1.2 -> 1.3 All functions: Added better Parameter help
    1.2 -> 1.3 Added #Requires at the top of the script
    1.1 -> 1.2 Create-Checksum: Made sure modules are imported
    1.0 -> 1.1 Create-Checksum: Made sure important commands are available
#>

Function Create-Checksum {
    <#
.Synopsis
   Combine Get-FileHash and Get-AuthenticodeSignature
.DESCRIPTION
   Create object with all the important validation fields
   Use only on folders, if you point on a file then the parent folder is selected.
.EXAMPLE
   Create-Checksum  D:\temp\new |Write-ToGenericCSVFile -path  D:\temp\new
   WARNING: File: D:\temp\new\new.checksum.csv

.EXAMPLE
   Create-Checksum D:\temp\new -WriteToFile
   WARNING: File: D:\temp\new\new.checksum.csv

.EXAMPLE
    Create-Checksum  D:\temp\new

Algorithm              : SHA256
Hash                   : 4F78C125C6CD12A84EE63611DFA4A0BC03A4095A244C251A8268589765A47A7D
Path                   : .\win10_new.html
SignerCertificate      : 
Status                 : UnknownError
StatusMessage          : The form specified for the subject is not one supported or known by the specified trust provider
TimeStamperCertificate : 

Algorithm              : SHA256
Hash                   : F8FCFE42EBC4417D6E0F5DBDA7183D68D6BC282BDEFDFAA9593567C4E888C9FC
Path                   : .\win10_new.xml
SignerCertificate      : 
Status                 : UnknownError
StatusMessage          : The form specified for the subject is not one supported or known by the specified trust provider
TimeStamperCertificate : 

Algorithm              : SHA256
Hash                   : ACEC00CB60D90AD1F395C359CBCAC60940A75ED44909C2E45A8B237B9FA2FDC8
Path                   : .\win10_old.html
SignerCertificate      : 
Status                 : UnknownError
StatusMessage          : The form specified for the subject is not one supported or known by the specified trust provider
TimeStamperCertificate : 

Algorithm              : SHA256
Hash                   : 295EA4F4537E8C57864305C519620F99F44690EE2190D23BD1BD044AB6058F9C
Path                   : .\win10_old.xml
SignerCertificate      : 
Status                 : UnknownError
StatusMessage          : The form specified for the subject is not one supported or known by the specified trust provider
TimeStamperCertificate : 
.LINK
Create-Checksum
.LINK
Write-ToGenericCSVFile
.LINK
Verify-Checksum
#>
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ValueFromRemainingArguments = $false,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { test-path $_ } ) ]
        #Enter a path to the folder, if file is specified, it will hopefully search the whole folder and recursivly
        $Path = "D:\temp\new",
        [ValidateSet("MACTripleDES", "MD5", "RIPEMD160", "SHA1", "SHA256", "SHA384", "SHA512")]
        #Ability to change algorithm, but hasn't added that ability yet to the verify-checksum function yet.. WIP
        $Algorithm = "SHA256",
        [switch]
        $WriteToFile,
        #ToDictionary changes the output to HashTable and the checksum as the key and puts everything inside it to make the Verify process lightningfast.
        [switch]
        $ToDictionary
    )
    Begin {
        Write-Verbose "Starting creation of Checksum"
        #$fileHash = @()
        #$selected = "SignerCertificate","Status","StatusMessage","TimeStamperCertificate"
        $list = New-object System.Collections.ArrayList
        $Allhash = @{}
        $start = get-date
        if ( !(Get-Module Microsoft.Powershell.Utility  ) ) { import-module Microsoft.Powershell.Utility  -ErrorAction stop }
        if ( !(Get-Module Microsoft.Powershell.Security ) ) { import-module Microsoft.Powershell.Security -ErrorAction stop }
        Get-Command Get-FileHash, Get-AuthentiCodeSignature -ErrorAction Stop | Out-null
    }
    Process {
        if ( (Split-Path -Qualifier $path) -eq ($path -replace '\\') ) {
            Write-Warning "This the root of that disk! THIS is NOT recommended!"
            if ( !( $pscmdlet.ShouldProcess($path, "Get-ChildItem -RECURSE") ) ) {
                Continue
            }
        }
        Try {
            Push-Location $path
            $files = Get-ChildItem -Recurse $path -Force -ErrorAction Ignore -File | Where-Object { $_ -notmatch '\.?checksum\.csv$|checksum' }
            if ($files.count -gt 400) { Write-Warning "Loads of files! Could take time! files: $($files.count)" }
            $fileHash = $files | 
            Get-FileHash -Algorithm $Algorithm |
            Select-Object Algorithm, Hash, @{N = "Path"; E = { Resolve-Path -Relative $_.Path } } |
            ForEach-Object {} { $temp = Get-AuthenticodeSignature $_.Path ; 
                $_ | Add-Member -NotePropertyName "SignerCertificate" -NotePropertyValue $temp.SignerCertificate.Thumbprint 
                $_ | Add-Member -NotePropertyName "Status" -NotePropertyValue $temp.Status 
                $_ | Add-Member -NotePropertyName "StatusMessage" -NotePropertyValue $temp.StatusMessage 
                $_ | Add-Member -NotePropertyName "TimeStamperCertificate" -NotePropertyValue $temp.TimeStamperCertificate.Thumbprint
                $AllHash."$($_.Path)" = $_
                $list.add( $_ )
                $_
            } {} | 
            ForEach-Object { $int = 0 } { $int++; if ($int % 1000 -eq 0) { Write-Verbose "At: $int Time: $( (Get-date) - $start)"; $_ } } { }
        }
        Catch {
            Write-Error $_
            Write-Warning "Have not taken care of this."
            Write-Warning "Most likely that you are trying to check the root"
        }
        Finally {
            Pop-Location
        }
        Write-Verbose ""
    }
    End {
        $end = Get-Date
        if ($WriteToFile) {
            Write-ToGenericCSVFile -Stuff $list -Path $path
        }
        elseif ($ToDictionary) {
            $allHash
        }
        else {
            $list
        }
        write-Verbose "Took: $($end - $start) Files: $($list.count)"
        Write-Verbose "End of creation of Checksum"
    }
}


Function Write-ToGenericCSVFile {
    <#
.Synopsis
   Convert any object into csv file and name it checksum.csv unless stated in path
.DESCRIPTION
   Convert any object into csv file and name it checksum.csv unless stated in path
.EXAMPLE
   Create-Checksum D:\temp\new |Write-ToGenericCSVFile -path D:\temp\new
   WARNING: File: D:\temp\new\new.checksum.csv
.EXAMPLE
   Write-ToGenericCSVFile -Stuff $lotsOfObjects -Path D:\temp\new\test.checksum.csv
   WARNING: File: D:\temp\new\new.checksum.csv
.LINK
Create-Checksum
.LINK
Write-ToGenericCSVFile
.LINK
Verify-Checksum
#>
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(ValueFromPipeline,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        #Put the objects you want to write to a file
        $Stuff,
        [String]
        #Path is where you wish to save the file, it will be saved as checksum.csv
        $Path,
        # Ability to change Delimiter for the CSV, usually ',' is the common delimiter, but i've changed it to ';'
        $Delimiter = ";"
    )
    Begin {
        if (!$path) {
            $pwd = (Get-Location).Path
            $path = Join-Path $pwd ( (Split-path -leaf $pwd) + ".checksum.csv" )
        }
        if ( (Get-Item $path -ErrorAction Ignore ).PSIsContainer ) {
            $path = Join-Path $path ( (Split-path -leaf $path) + ".checksum.csv" )
        }
        if ($path -notmatch ".checksum.csv$") {
            $path = $path + ".checksum.csv"
        }
        $list = New-object System.Collections.ArrayList
    }
    Process {
        foreach ($new in $stuff) {
            #if (!$Columns) {
            #    $Columns = $new |gm -MemberType *Propert* |select -ExpandProperty Name | sort -Unique
            #}
            $list.Add($new) | out-null
        }
    }
    End {
        #($list |select $Columns | ConvertTo-Csv -Delimiter $Delimiter -NoTypeInformation) -replace '"' |Out-File $path -Encoding utf8
        Write-Verbose "Writing to file: $path"
        ($list | ConvertTo-Csv -Delimiter $Delimiter -NoTypeInformation) -replace '"' | Out-File $path -Encoding utf8
        Write-Warning "File: $path"
    }
}

Function Verify-Checksum {
    <#
.Synopsis
   Enter a path to folder to do a check against 
.DESCRIPTION
   If there are checksum.csv or .dat, this function will work and try to parse it
.EXAMPLE
   Verify-Checksum -path d:\temp\new -Verbose
VERBOSE: Start of Verify-Checksum
VERBOSE: Working on D:\temp\temp.checksum.csv
VERBOSE: Starting creation of Checksum
VERBOSE: 
VERBOSE: Took: 00:00:00.6630000
VERBOSE: End of creation of Checksum
VERBOSE: Equal amounth of files!
VERBOSE: Matching checksum: .\Admin.htm
WARNING: Error! No SignerCertificate on .\Admin.htm
VERBOSE: Matching checksum: .\test.ps1
WARNING: Error! No SignerCertificate on .\test.ps1
VERBOSE: Matching checksum: .\typ.txt
WARNING: Error! No SignerCertificate on .\typ.txt
VERBOSE: Matching checksum: .\User.htm
WARNING: Error! No SignerCertificate on .\User.htm
VERBOSE: Matching checksum: .\new\win10_new.html
WARNING: Error! No SignerCertificate on .\new\win10_new.html
VERBOSE: Matching checksum: .\new\win10_new.xml
WARNING: Error! No SignerCertificate on .\new\win10_new.xml
VERBOSE: Matching checksum: .\new\win10_old.html
WARNING: Error! No SignerCertificate on .\new\win10_old.html
VERBOSE: Matching checksum: .\new\win10_old.xml
WARNING: Error! No SignerCertificate on .\new\win10_old.xml
VERBOSE: Matching checksum: .\test\computer1-stuff-test2-2019-10-01-verbose.html
WARNING: Error! No SignerCertificate on .\test\computer1-stuff-test2-2019-10-01-verbose.html
VERBOSE: Matching checksum: .\test\computer1-stuff-test2-2019-10-01.html
WARNING: Error! No SignerCertificate on .\test\computer1-stuff-test2-2019-10-01.html
VERBOSE: Matching checksum: .\test\computer1-Stuff-test2-2019-10-01.xml
WARNING: Error! No SignerCertificate on .\test\computer1-Stuff-test2-2019-10-01.xml
VERBOSE: Matching checksum: .\test\computer1-Stuff-test3-2019-10-01-verbose.html
WARNING: Error! No SignerCertificate on .\test\computer1-Stuff-test3-2019-10-01-verbose.html
VERBOSE: Matching checksum: .\test\computer1-Stuff-test3-2019-10-01.html
WARNING: Error! No SignerCertificate on .\test\computer1-Stuff-test3-2019-10-01.html
VERBOSE: Matching checksum: .\test\computer1-Stuff-test3-2019-10-01.xml
WARNING: Error! No SignerCertificate on .\test\computer1-Stuff-test3-2019-10-01.xml
VERBOSE: Matching checksum: .\test\computer1-Stuff-test4-2019-10-01-verbose.html
WARNING: Error! No SignerCertificate on .\test\computer1-Stuff-test4-2019-10-01-verbose.html
VERBOSE: Matching checksum: .\test\computer1-Stuff-test4-2019-10-01.html
WARNING: Error! No SignerCertificate on .\test\computer1-Stuff-test4-2019-10-01.html
VERBOSE: Matching checksum: .\test\computer1-Stuff-test4-2019-10-01.xml
WARNING: Error! No SignerCertificate on .\test\computer1-Stuff-test4-2019-10-01.xml
VERBOSE: Matching checksum: .\test\computer1-Stuff-test5-2019-10-01-verbose.html
WARNING: Error! No SignerCertificate on .\test\computer1-Stuff-test5-2019-10-01-verbose.html
VERBOSE: Matching checksum: .\test\computer1-Stuff-test5-2019-10-01.html
WARNING: Error! No SignerCertificate on .\test\computer1-Stuff-test5-2019-10-01.html
VERBOSE: Matching checksum: .\test\computer1-Stuff-test5-2019-10-01.xml
WARNING: Error! No SignerCertificate on .\test\computer1-Stuff-test5-2019-10-01.xml
VERBOSE: Matching checksum: .\test\computer1-Stuff-test1-2019-10-01-verbose.html
WARNING: Error! No SignerCertificate on .\test\computer1-Stuff-test1-2019-10-01-verbose.html
VERBOSE: Matching checksum: .\test\computer1-Stuff-test1-2019-10-01.html
WARNING: Error! No SignerCertificate on .\test\computer1-Stuff-test1-2019-10-01.html
VERBOSE: Matching checksum: .\test\computer1-Stuff-test1-2019-10-01.xml
WARNING: Error! No SignerCertificate on .\test\computer1-Stuff-test1-2019-10-01.xml
VERBOSE: Matching checksum: .\test\w10.fast.NO.WALL.log
WARNING: Error! No SignerCertificate on .\test\w10.fast.NO.WALL.log
VERBOSE: Matching checksum: .\test\w10.NO.WALL.log
WARNING: Error! No SignerCertificate on .\test\w10.NO.WALL.log
VERBOSE: Matching checksum: .\test\win10_old.html
WARNING: Error! No SignerCertificate on .\test\win10_old.html
VERBOSE: Matching checksum: .\test\win10_old.xml
WARNING: Error! No SignerCertificate on .\test\win10_old.xml
VERBOSE: Matching checksum: .\test\win10_old_new.xml
WARNING: Error! No SignerCertificate on .\test\win10_old_new.xml
VERBOSE: Matching checksum: .\test\win10_org.html
WARNING: Error! No SignerCertificate on .\test\win10_org.html
VERBOSE: Matching checksum: .\test\win10_org.xml
WARNING: Error! No SignerCertificate on .\test\win10_org.xml
VERBOSE: Matching checksum: .\test\win10_org_new.xml
WARNING: Error! No SignerCertificate on .\test\win10_org_new.xml
VERBOSE: Matching checksum: .\test\win7.fast.NO.WALL.log
WARNING: Error! No SignerCertificate on .\test\win7.fast.NO.WALL.log
VERBOSE: Matching checksum: .\test\win7.NO.WALL.log
WARNING: Error! No SignerCertificate on .\test\win7.NO.WALL.log
VERBOSE: The Variable $Resume holds all this information, including VerifyStatus
VERBOSE: End of Verify-Checksum 00:00:00.7520000
.LINK
Create-Checksum
.LINK
Write-ToGenericCSVFile
.LINK
Verify-Checksum
#>
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ValueFromRemainingArguments = $false,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        #Enter a path to the folder, if file is specified, it will hopefully search the whole folder and recursivly
        [String]
        $Path
    )
    Begin {
        Write-Verbose "Start of Verify-Checksum"
        $Resume = New-object System.Collections.ArrayList
        $checkAgains = "*checksum.csv", "*.dat"
        $begin = get-date
    }
    Process {
        $CheckSumFiles = @()
        if ( (Split-Path -Qualifier $path) -eq ($path -replace '\\') ) {
            Write-Warning "This the root of that disk! THIS is NOT recommended!"
            if ( !( $pscmdlet.ShouldProcess($path, "Get-ChildItem -RECURSE") ) ) {
                Continue
            }
        }
        foreach ( $again in $checkAgains) {
            $CheckSumFiles += Get-ChildItem -file -Recurse -Force -path $path $again -EA Ignore | Select-Object -expand Fullname
        }

        foreach ($file in $CheckSumFiles) {
            Write-Verbose "Working on $file"
            if ($file -match '\.dat$') {
                $data = Get-Content $file
                #$data = @("765CA737C624AD3485751B5A6DA279327A2230911C96A22138E2A1F6822241F5.\path\file.exe765CA737C624AD3485751B5A6DA279327A2230911C96A22138E2A1F6822241F5.\path\file.exe",
                #"765CA737C624AD3485751B5A6DA279327A2230911C96A22138E2A1F6822241F5.\path\file.exe765CA737C624AD3485751B5A6DA279327A2230911C96A22138E2A1F6822241F5.\path\file.exe")
                $edited = $data -replace '(\.\\[\w\ \\]+\.\w\w\w)', ';$1NewRow' -split 'NewRow' | Where-Object { $_ } | ForEach-Object { $csv = "Algorithm;Hash;Path`n" } { $csv += "SHA256;$_`n" } { $csv } 
                $Original = $edited  | ConvertFrom-Csv -Delimiter ";"
            }
            elseif ($file -match '\.csv$') {
                $data = Import-Csv -Delimiter ";" -Path $file
                $Original = $data
            }
            if ( ( $Original | Get-Member -MemberType *proper* | Where-Object Name -notin "Chars", "Length" | Sort-Object -Unique Name ).name -le 1 ) {
                # If there only 1 Property, ie. failed import
                Write-Error "Failed to import the file, search for this row and update the script" -ErrorAction Stop
            }
            
            If ( $Original.Algorithm ) {
                $Algorithm = $Original.Algorithm | Select-Object -First 1
            }
            else {
                $Algorithm = "SHA256"
            }

            $CheckSumPath = (Split-Path -Parent $file)
            $ActualFilesHash = Create-Checksum -Path $CheckSumPath -ToDictionary -Algorithm $Algorithm -ErrorAction Stop

            if ($ActualFilesHash.keys.count -ne $Original.count) {
                Write-Warning "Actual count is not equal to original folder count"
            }
            else {
                Write-Verbose "Equal amounth of files!"
            }
            if ($ActualFilesHash.keys.count -gt $Original.count) {
                Write-Warning "There are more files at $CheckSumPath compared to checksumfile(Actual: $($ActualFilesHash.keys.count) vs checksumfile $($Original.count) )"
            }
            if ($ActualFilesHash.keys.count -lt $Original.count) {
                Write-Warning "There are fewer files at $CheckSumPath compared to checksumfile(Actual: $($ActualFilesHash.keys.count) vs checksumfile $($Original.count) )"
            }
            $CountDownHash = $ActualFilesHash
            
            $int = 0
            foreach ( $sum in $Original ) {
                $int++
                if ($int % 1000 -eq 0) { write-verbose "At: $int Time: $((Get-date) - $start)" }
                $found = $ActualFilesHash."$($sum.Path)"
                #$found = $ActualFiles |? Path -eq $sum.path #This will be exponentially slower compared to hash.key which does not search..
                if ($found) {
                    $CountDownHash.Remove( $Sum.Path )
                    if ($found.count -gt 1) {
                        Write-warning "ERROR! Found more than one of this file: $($sum.path)"
                    }
                    if ( $found.hash -eq $sum.hash ) {
                        Write-Verbose "Matching checksum: $($sum.path)"

                        if ( $found.SignerCertificate -eq $sum.SignerCertificate ) {
                            Write-Verbose "Matching SignerCertificate: $($sum.path)"
                            
                            if ( $found.TimeStamperCertificate -eq $sum.TimeStamperCertificate ) {
                                Write-Verbose "Matching TimeStamperCertificate: $($sum.path)"
                                
                                $sum | Add-Member -NotePropertyName "VerifyStatus" -NotePropertyValue "AllMatches"
                                $resume.Add( $sum ) | Out-Null
                            }
                            elseif (! $found.SignerCertificate -and ! $sum.TimeStamperCertificate) {
                                Write-Verbose "Error! No TimeStamperCertificate on $($sum.path)"
                                $sum | Add-Member -NotePropertyName "VerifyStatus" -NotePropertyValue "NoTimeStamperCertificate"
                                $resume.Add( $sum ) | Out-Null
                            }
                            else {
                                Write-Warning "ERROR!   BAD    TimeStamperCertificate: $($sum.path)"
                                Write-Warning "ERROR!  Actual  TimeStamperCertificate: $($found.TimeStamperCertificate)"
                                Write-Warning "ERROR! Original TimeStamperCertificate: $($sum.TimeStamperCertificate)"
                                $sum | Add-Member -NotePropertyName "VerifyStatus" -NotePropertyValue "BadTimeStamperCertificate"
                                $resume.Add( $sum ) | Out-Null
                            }
                        }
                        elseif (! $found.SignerCertificate.Thumbprint -and ! $sum.SignerCertificate) {
                            Write-Verbose "Error! No SignerCertificate on $($sum.path)"
                            $sum | Add-Member -NotePropertyName "VerifyStatus" -NotePropertyValue "NoSignerCertificate"
                            $resume.Add( $sum ) | Out-Null
                        }
                        else {
                            Write-Warning "ERROR!   BAD    SignerCertificate: $($sum.path)"
                            Write-Warning "ERROR!  Actual  SignerCertificate: $($found.SignerCertificate)"
                            Write-Warning "ERROR! Original SignerCertificate: $($sum.SignerCertificate)"
                            $sum | Add-Member -NotePropertyName "VerifyStatus" -NotePropertyValue "BadSignerCertificate"
                            $resume.Add( $sum ) | Out-Null
                        }
                    }
                    else {
                        Write-Warning "ERROR!   BAD    CHECKSUM: $($sum.path)"
                        Write-Warning "ERROR!  Actual  CHECKSUM: $($found.Hash)"
                        Write-Warning "ERROR! Original CHECKSUM: $($sum.Hash)"
                        $sum | Add-Member -NotePropertyName "VerifyStatus" -NotePropertyValue "BadChecksum"
                        $resume.Add( $sum ) | Out-Null
                    }
                }
                else {
                    Write-Warning "ERROR! FILE NOT FOUND: $($sum.hash)"
                    $sum | Add-Member -NotePropertyName "VerifyStatus" -NotePropertyValue "NotFound"
                    $resume.Add( $sum ) | Out-Null
                }
            }
            if ($CountDownHash.keys.count -gt 0) {
                Write-Warning "ERROR! Found at $Path but not in Checksum file:"
                foreach ($Key in $CountDownHash.Keys) {
                    $CountDownHash.$Key.Path
                    $CountDownHash.$Key | Add-Member -NotePropertyName "VerifyStatus" -NotePropertyValue "BadExtraFile"
                    $Resume.Add( $CountDownHash.$Key ) | Out-Null
                }
            }
        }
    }
    End {
        $global:Resume = $Resume
        Write-Verbose "The Variable `$Resume holds all this information, including VerifyStatus"
        Write-Verbose "Total files checked: $($Resume.count)"
        $Resume | Group-Object VerifyStatus | Select-Object Count, Name
        Write-Verbose "End of Verify-Checksum $( (get-date) - $begin)"
    }
}

Export-ModuleMember Create-Checksum, Verify-Checksum -ErrorAction Ignore