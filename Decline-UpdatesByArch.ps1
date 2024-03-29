# ========================================================
# Script to decline specific-Arch updates in WSUS.
# ========================================================
# It's recommended to run the script with the -SkipDecline switch to see how many specific-Arch updates are in WSUS and to TAKE A BACKUP OF THE SUSDB before declining the updates.
# Parameters:

# $UpdateServer             = Specify WSUS Server Name
# $UseSSL                   = Specify whether WSUS Server is configured to use SSL
# $Port                     = Specify WSUS Server Port
# $SkipDecline              = Specify this to do a test run and get a summary of how many specific-Arch updates we have
# $Arch                     = Specify Arch type(x86/x64/ARM64) of updates to decline

# Usage:
# =======

# To do a test run against WSUS Server without SSL
# Decline-UpdatesByArch.ps1 -UpdateServer SERVERNAME -Port 8530 -Arch x86 -SkipDecline

# To do a test run against WSUS Server using SSL
# Decline-UpdatesByArch.ps1 -UpdateServer SERVERNAME -UseSSL -Port 8531 -Arch x86 -SkipDecline

# To decline all specific-Arch updates on the WSUS Server using SSL
# Decline-UpdatesByArch.ps1 -UpdateServer SERVERNAME -UseSSL -Port 8531 -Arch x86


[CmdletBinding()]
Param(
	[Parameter(Mandatory=$True,Position=1)]
    [string] $UpdateServer,
	[Parameter(Mandatory=$False)]
    [switch] $UseSSL,
	[Parameter(Mandatory=$True, Position=2)]
    $Port,
	[Parameter(Mandatory=$True,Position=3)]
    [ValidateSet("x86", "x64", "arm64")]
    [string] $Arch,
    [switch] $SkipDecline
)

Write-Host ""
Write-Host "Decline-UpdatesByArch.ps1 has Started at" $(Get-Date -Format G)

$outPath = Split-Path $script:MyInvocation.MyCommand.Path
$outSpecificArchList = Join-Path $outPath "SpecificArchUpdates.csv"
$outSpecificArchListBackup = Join-Path $outPath "SpecificArchUpdatesBackup.csv"
"UpdateID, RevisionNumber, Title, KBArticle, SecurityBulletin, HasSupersededUpdates, Arch" | Out-File $outSpecificArchList

try {
    
    if ($UseSSL) {
        Write-Host "Connecting to WSUS server $UpdateServer on Port $Port using SSL... " -NoNewLine
    } Else {
        Write-Host "Connecting to WSUS server $UpdateServer on Port $Port... " -NoNewLine
    }
    
    [reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null
    #$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($UpdateServer, $UseSSL, $Port);
	$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer();
}
catch [System.Exception] 
{
    Write-Host "Failed to connect."
    Write-Host "Error:" $_.Exception.Message
    Write-Host "Please make sure that WSUS Admin Console is installed on this machine"
	Write-Host ""
    $wsus = $null
}

if ($wsus -eq $null) { return } 

Write-Host "Connected."

$countAllUpdates = 0
$countSpecificArch = 0
$countDeclined = 0

Write-Host "Getting a list of all updates... " -NoNewLine

try {
	$allUpdates = $wsus.GetUpdates()
}

catch [System.Exception]
{
	Write-Host "Failed to get updates."
	Write-Host "Error:" $_.Exception.Message
    Write-Host "If this operation timed out, please decline the SpecificArch updates from the WSUS Console manually."
	Write-Host ""
	return
}

Write-Host "Done"

Write-Host "Parsing the list of updates... " -NoNewLine
foreach($update in $allUpdates) {
    
    $countAllUpdates++
    
    if ($update.IsDeclined) {
        $countDeclined++
    }
    
    if (!$update.IsDeclined -and $update.LegacyName -imatch "-$Arch-") {
        $countSpecificArch++
        "$($update.Id.UpdateId.Guid), $($update.Id.RevisionNumber), $($update.Title), $($update.KnowledgeBaseArticles), $($update.SecurityBulletins), $($update.HasSupersededUpdates), $($Arch)" | Out-File $outSpecificArchList -Append       
    }
}

Write-Host "Done."
Write-Host "List of SpecificArch($Arch) updates: $outSpecificArchList"

Write-Host ""
Write-Host "Summary:"
Write-Host "========"

Write-Host "All Updates =" $countAllUpdates
Write-Host "Any except Declined =" ($countAllUpdates - $countDeclined)
Write-Host "All SpecificArch($Arch) Updates =" $countSpecificArch
Write-Host ""
Write-Host "Summarizing the updates has been done at" $(Get-Date -Format G)

if (!$SkipDecline) {
    
    Write-Host "SkipDecline flag is set to $SkipDecline. Continuing with declining updates"
    $updatesDeclined = 0
    
    foreach ($update in $allUpdates) {
        
        if (!$update.IsDeclined -and $update.LegacyName -imatch "-$Arch-") {
            
            try
            {
                $update.Decline()
                # Write-Host "Declined update $($update.Id.UpdateId.Guid)"
                Write-Progress -Activity "Declining Updates" -Status "Declining update $($update.Id.UpdateId.Guid)" -PercentComplete (($updatesDeclined/$countSpecificArch) * 100)
                $updatesDeclined++
            }
            catch [System.Exception]
            {
                Write-Host "Failed to decline update $($update.Id.UpdateId.Guid). Error:" $_.Exception.Message
            }            
        }
    }   
    
    Write-Host "  Declined $updatesDeclined updates."
    if ($updatesDeclined -ne 0) {
        Copy-Item -Path $outSpecificArchList -Destination $outSpecificArchListBackup -Force
		Write-Host "  Backed up list of SpecificArch updates to $outSpecificArchListBackup"
    }
    
}
else {
    Write-Host "SkipDecline flag is set to $SkipDecline. Skipped declining updates"
}

Write-Host ""
Write-Host "Decline-UpdatesByArch.ps1 has finished at" $(Get-Date -Format G)
Write-Host ""