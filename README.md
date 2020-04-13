# PhonoxPSHelpers

This powershell module was created to make life easier.
For instance 'PersistentData' which is the main feature makes it easier to save and restore variables to/from file.
None of these features are written for performance. So this should NOT replace a DB or anything similar!
The old version of PersistentData might have been faster but i like this better for now.

With the PersistentData feature, other functions will become better.

The prompt function will how what time it is, how long since you started powershell today(and also saves the 6 most recent days to variable/persistentdata, so it will be easier to remeber how long you have been working.)

Get-GameSize utilizes PersistentData variable, which have the paths to all my games.

# WHY YOU SHOULD USE THIS.

- Having problem to remember IP adresses that repeateadly comes back every now and again?
- Keep forgetting when you got to work?
- How long you worked?
- Do you use CLI daily? and bad at keeping track of time? or when you last time you used the terminal/powershell if you have multiple of them?
- You have multiple of instances of powershell and keep picking the instance which did not have a specific variable?
- Just came up with an backlog item and just need to type it down before putting it elsewhere? Set-Persistent Backlog -add "more stuff"
- Keep using same values on other functions? (can be fixed by creating new function(wrapper) that use these variables as default values)

# Tests

I have not put the time in to create tests for everything yet.

# Backlog

High prio(Almost critial):

- PersistentData - (should be there)(reintroduced) Multiple powershell instances at the same time with autoupdate on - The import of the persistentdata-file will result of not finding it.

Low prio:

- PersistentData - Performance issue (I guess as I rewrote this function, changed it from 'a list of variable and search for the variable' to 'list and change it to hashtable and back a list again')
- PersistentData - Dynamic param for Vault, Path and Name.
- PersistentData - New feature - SettingsVault and keeper of all Vaults, Paths and some other general settings which does not requires so many updates.
- PersistentData - (reintroduced) When multiple of powershell instances is in use - Remove variable on other instances
- PersistentData - Try other Scopes and see what they do.
- VerifyFiles - might not be complete (it is somewhat customized)
- VerifyFiles - HUGE OVERHEAD!!! (but the uses are small and not much of a problem for now.)
- Tests - Make tests for all functions
- Tests - Make tests that show the most usefull usecases/how to use these features.
- General module - Change module manifest, change "*" with correct values. (this will increase performance a slight)

# Updates

There will not be frequent updates from me, unless it is critical one.
