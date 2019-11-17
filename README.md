# Decline-UpdatesByArch
**Credit goes to [Decline-SupersededUpdates.ps1](https://msdnshared.blob.core.windows.net/media/TNBlogsFS/prod.evol.blogs.technet.com/telligent.evolution.components.attachments/01/6906/00/00/03/64/80/93/Decline-SupersededUpdates.txt)**

Script to decline specific-Arch updates in WSUS.

It's recommended to run the script with the -SkipDecline switch to see how many specific-Arch updates are in WSUS and to TAKE A BACKUP OF THE SUSDB before declining the updates.

Parameters:
- $UpdateServer             = Specify WSUS Server Name
- $UseSSL                   = Specify whether WSUS Server is configured to use SSL
- $Port                     = Specify WSUS Server Port
- $SkipDecline              = Specify this to do a test run and get a summary of how many specific-Arch updates we have
- $Arch                     = Specify Arch type(x86/x64/ARM64) of updates to decline

## Usage:

- To do a test run against WSUS Server without SSL
 `Decline-UpdatesByArch.ps1 -UpdateServer SERVERNAME -Port 8530 -Arch x86 -SkipDecline`

- To do a test run against WSUS Server using SSL
 `Decline-UpdatesByArch.ps1 -UpdateServer SERVERNAME -UseSSL -Port 8531 -Arch x86 -SkipDecline`

- To decline all specific-Arch updates on the WSUS Server using SSL
 `Decline-UpdatesByArch.ps1 -UpdateServer SERVERNAME -UseSSL -Port 8531 -Arch x86`
