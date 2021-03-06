Function Get-SizeOfGames {
    <#
    .SYNOPSIS
        Check the game size on disk
    .DESCRIPTION
        Fetch all the parent game paths, for instance: 
        "C:\Spel\SteamLibrary\steamapps\common",
        "D:\A GOG\Galaxy\Games"

        Either save them to variable or to a persistent variable
        Set-persistentData ListOfGames "C:\Spel\SteamLibrary\steamapps\common","D:\A GOG\Galaxy\Games"

        Checks the total game size and prints all who are bigger than 1GB(could be too many games otherwise)
    .NOTES
        Backlog: check file exist, else create
        Backlog: check registry for this...
        Backlog: check total size for each disk and compare to total disk.
    .EXAMPLE
     Get-SizeOfGames -MinimumSize 50gb 
        WARNING: Total size of all games:
        WARNING: C: 121,33 GB
        WARNING: D: 747,76 GB
        Name                        Length
        ----                        ------
        Gears5                      75,64 GB
        Call of Duty Modern Warfare 86,72 GB
        DiRT Rally 2.0              108,27 GB
    .EXAMPLE
     Get-SizeOfGames "C:\Spel\SteamLibrary\steamapps\common","D:\A GOG\Galaxy\Games" -MinimumSize 50gb 
        WARNING: Total size of all games:
        WARNING: C: 121,33 GB
        WARNING: D: 747,76 GB
        Name                        Length
        ----                        ------
        Gears5                      75,64 GB
        Call of Duty Modern Warfare 86,72 GB
        DiRT Rally 2.0              108,27 GB
    #>
    [Alias("Get-GameSize")]
    param (
        [string[]]$list = $ListOfGames, # (Get-Content D:\gamelist.txt)
        [ValidateScript( { $_ -match '\d[(TB)|(GB)|(MB)|(kB)|(B)]?' })]
        [string]$MinimumSize = "1GB"
    )
    Get-ChildItemSize $list | ForEach-Object { $qualifyer = @{ } ; $TotalGames = 0 } { #end of begin
        if (!$qualifyer.(Split-Path $_.fullname -Qualifier) ) {
            $qualifyer.(Split-Path $_.fullname -Qualifier) = [int64]0
        }
        $qualifyer.(Split-Path $_.fullname -Qualifier) += $_.Length ; $TotalGames++  ; $_ } { #end of process
        #foreach( $key in $qualifyer ){
        #    $qualifyer.$key = Format-FileSize $qualifyer.$key
        #}
    } | #end of end
    Where-Object Length -gt $MinimumSize |
    Sort-Object Length, Name |
    Select-Object Name, @{N = "Length"; E = { Format-FileSize $_.Length } }
            
    Write-Warning "Total size of all games:"
    foreach ( $key in $qualifyer.Keys ) {
        Write-Warning "$key $(Format-FileSize $qualifyer.$key)"
    }
    Write-Warning "Total amount of games: $TotalGames"
}
#New-Alias Get-GameSize -Value Get-SizeOfGames
Export-ModuleMember Get-ChilditemSize, Get-SizeOfGames -Alias Get-GameSize -ErrorAction Ignore

#Get-ChildItemSize | select mode,lastwritetime,@{N="Length";E={$_.Length |Format-FileSize} },Name
