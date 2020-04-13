Function Get-SizeOfGames{
    <#
    .SYNOPSIS
        Check the game size on disk
    .DESCRIPTION
        Create a file D:\gamelist.txt with all parent folder to all games, such as:
        C:\Spel\SteamLibrary\steamapps\common
        D:\A GOG\Galaxy\Games

        Checks the total game size and prints all who are bigger than 1GB(could be too many games otherwise)
    .NOTES
        Backlog: check file exist, else create
        Backlog: check registry for this...
        Backlog: check total size for each disk and compare to total disk.
    #>
    [Alias("Get-GameSize")]
    param (
        [string[]]$list = $ListOfGames, # (Get-Content D:\gamelist.txt)
        [ValidateScript({$_ -match '\d[(TB)|(GB)|(MB)|(kB)|(B)]?'})]
        [string]$MinimumSize = "1GB"
    )
    Get-ChildItemSize $list | % { $qualifyer = @{ } } { #end of begin
        if (!$qualifyer.(Split-Path $_.fullname -Qualifier) ) {
            $qualifyer.(Split-Path $_.fullname -Qualifier) = [int64]0
        }
            $qualifyer.(Split-Path $_.fullname -Qualifier) += $_.Length  ; $_} { #end of process
                #foreach( $key in $qualifyer ){
                #    $qualifyer.$key = Format-FileSize $qualifyer.$key
                #}
            } | #end of end
            Where-Object Length -gt $MinimumSize |
            Sort Length,Name |
            select Name,@{N="Length";E={Format-FileSize $_.Length} }
            
            Write-Warning "Total size of all games:"
            foreach( $key in $qualifyer.Keys ){
                    Write-Warning "$key $(Format-FileSize $qualifyer.$key)"
                }
}
#New-Alias Get-GameSize -Value Get-SizeOfGames
Export-ModuleMember Get-ChilditemSize,Get-SizeOfGames -Alias Get-GameSize -ErrorAction Ignore

#Get-ChildItemSize | select mode,lastwritetime,@{N="Length";E={$_.Length |Format-FileSize} },Name
