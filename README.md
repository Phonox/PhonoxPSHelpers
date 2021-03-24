﻿# PhonoxPSHelpers

This powershell module was created to make life easier.
For instance 'PersistentData' which is the main feature makes it easier to save and restore variables to/from file.
None of these features are written for performance. So this should NOT replace a DB or anything similar!
The old version of PersistentData might have been faster but i like this better for now.

With the PersistentData feature, other functions will become better.

## WHY YOU SHOULD USE THIS

- Having problem to remember IP adresses that repeateadly comes back every now and again?
- Keep forgetting when you got to work?
- How long you worked?
- Do you use CLI daily? and bad at keeping track of time? or when you last time you used the terminal/powershell if you have multiple of them?
- You have multiple of instances of powershell and keep picking the instance which did not have a specific variable?
- Just came up with an backlog item and just need to type it down before putting it elsewhere? Set-Persistent Backlog -add "more stuff"
- Keep using same values on other functions? (can be fixed by creating new function(wrapper) that use these variables as default values)
- You wanted to set variable in the profile but never got there?

## Tests

There's just a few of them right now.. when i have time, I'll do some more

## Updates

There will not be frequent updates from me, unless it is critical one.

## Help

For more info
`Get-Command -Module PhonoxPSHelpers`
`Help <function> -full`

## Features/Functions

- New prompt. It will show what time it is, how long since you started the first powershell instance today(and also saves the 6 most recent days to variable/persistentdata, so it will be easier to remeber how long you have been working.)

- Get-ChildItemSize which is Get-ChildItem with added member for the size

- ListGame.ps1 / Get-GameSize uses Get-ChildItemSize and a variable from PersistentData, which have the paths to all my games and print out Name, size and total size of all games on each disk.

- Write-FancyMessage will only print what ever you wish with a frame

- Register-Watcher is usefull when you want to watch a file change

- Set-Timer use full if you wish to set a timer of some kind? which will run even if you are running something else in the background
