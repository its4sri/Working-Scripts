
<#

.PARAMETER vc
Name of the virtual center containing the vm

.PARAMETER vm
Name of the virtual machine

.PARAMETER snid
Referenece number from ServiceNow for snapshot

.NOTES
       Change Log    
    	2018-03-20 version 1.0.2.0
			v 0.2.0 - adding code snippet to pull in XML file, load custom module and logging
		2018-01-16 version 1.0.0.1
			v 0.0.1 - Updating script to use modules or PSSnapins
		2014-12-09 version 1.0
              Intial creation
       
#>

# param (     
#      [Parameter(Mandatory=$true)]
#      [string]$vc,
#      [Parameter(Mandatory=$true)]
#      [string]$vm,
#      [string]$snid 
#      )



Function Cleanup-Variables {
<#
.SYNOPSIS
Function collection
.DESCRIPTION

.PARAMETER Command
Begin - This is executed at the beginning of a script to collect the established variables

End - This is executed when closing a script to remove the variables not seen when the script started

.EXAMPLE
---Example #1---
Cleanup-Variables "Begin"

--Example #2---
Cleanup-Variables "End"

#>
$WhatToDo = $args[0]

Switch ($WhatToDo) {
       "Begin" {
              new-variable -force -name startupVariables -value ( Get-Variable |   % { $_.Name } )
              $LoadedSnapins = Get-PSSnapin
              }
       "End" {       
              Get-PSSnapin | Where-Object { $LoadedSnapins -notcontains $_.Name}| % {Remove-PSSnapin -Name "$($_.Name)" -ErrorAction SilentlyContinue  }
              Get-Variable | Where-Object { $startupVariables -notcontains $_.Name } | % { Remove-Variable -Name "$($_.Name)" -Force -Scope "global" -ErrorAction SilentlyContinue}
              }
       }      
}      

Function Load-Snapin {
<#
.SYNOPSIS
Checks if a snapin is loaded, if not checks for resistration and then loads it

.DESCRIPTION

.PARAMETER Snapin
The name of the snapin to be loaded

.EXAMPLE
Loads the powercli addin from VMWARE

Load-Snapin "VMware.VimAutomation.Core"
#>

$snapin=$args[0]
if (get-pssnapin $snapin -ea "silentlycontinue") {
write-host "PSsnapin $snapin is loaded" -foregroundcolor Blue
}
elseif (get-pssnapin $snapin -registered -ea "silentlycontinue") {
write-host "PSsnapin $snapin is registered but not loaded" -ForegroundColor Yellow -BackgroundColor Black
Add-PSSnapin $snapin
Write-Host "PSsnapin $snapin is loaded" -ForegroundColor Blue
}
else {
write-host "PSSnapin $snapin not found" -foregroundcolor Red
}

}

Function Get-Email ([string]$lanid) {
###Function Get-Email
###This function returns the e-mail address of the logged on users
###If the account is a the corp-svc-ctx-xa account or an autosys service account it returns a specific address
###Otherwise to takes the employee ID of the logged in user and looks for an account in the client OU with that same
###employee ID and returns that as the address
#$username = [Environment]::UserName
$username=$RequestorLanid
Switch ($username)
{
"corp-svc-ctx-xa" {return "CORP-SVC-CTX-XA@CORP.AMVESCAP.NET"}
"ushou-asysws*" {return "AutosysSTG@aiminvestments.com" }
"ushou-asyswd*" {return "AutosysDEV@aiminvestments.com" }
"ushou-asyswp*" {return "AutosysACE@aiminvestments.com" }

default {
    $defaultNamingContext=([ADSI]("LDAP://rootDSE")).defaultNamingContext
    $query = "(sAMAccountName=$username)"
    $attrs = @("cn")
    $searcher = New-Object DirectoryServices.DirectorySearcher([ADSI]("LDAP://$defaultNamingContext"), $query, $attrs)
    $objUser = $searcher.FindOne()
    if ($objUser) {
        $emplID = $objUser.GetDirectoryEntry().extensionAttribute1
        $query = "(&(objectCategory=person)(objectClass=user)(extensionAttribute1=$emplID)(mail=*))"
        $searcher = New-Object DirectoryServices.DirectorySearcher([ADSI]("LDAP://OU=AVZ Clients,$defaultNamingContext"), $query, $attrs)
        $objUser = $searcher.FindOne()
        if ($objUser) {
            return $objUser.GetDirectoryEntry().mail
        } else {
            "Regular account not found"
        }
    } else {
        "Admin account not found"
    }
} #closing default switch option
} # closing switch command
} #closing function




############################## 

###End of Function Defintion(s)###

Import-Module knoxdaModule

Write-Verbose "Determining Script Name"
$ScriptName = $($MyInvocation.MyCommand.ToString()).Replace(".ps1", "")
If ($ScriptName -eq $null) { $ScriptName = "ScriptLog" }
Write-Verbose "ScriptName: $ScriptName"
$ScriptPath = $MyInvocation.MyCommand.Definition
$ScriptDir = Split-Path -Parent $ScriptPath
Write-Verbose "ScriptPath: $ScriptPath"
Write-Verbose "ScriptDirectory: $ScriptDir"
Write-Verbose "ScriptXML $ScriptDir\$($ScriptName).xml"


If ($(Get-Module knoxdamodule) -eq $null)
{ Import-Module $($XMLSettings.Configuration.General.knoxdaModule) }

#Creating Log directory if it doesn't exist
If (!(Test-Path -Path "$ScriptDir\Logs" -ErrorAction SilentlyContinue))
{
	Try { New-Item "$ScriptDir\Logs" -Type Directory }
	Catch { Write-Error -Message "Error creating Logpath folder" }
	Finally { }
}
If (Test-Path -Path "$ScriptDir\Logs")
{
	Trace-Script -LogAction "Begin" -ScriptName $ScriptName -LogPath "$ScriptDir\Logs"
}
Else
{
	Write-Output "Log directory does not exists and cannot be created"
}

If ($XMLFilePath.Length -eq 0)
{
	Write-Output "Loading Default XML file"
	$XMLFilePath = "$ScriptDir\$($ScriptName).xml"
}
Write-Verbose "XMLFilePath: $XMLFilePath"

If (Test-Path $XMLFilePath)
{
	Write-Verbose "Loading XML File from $XMLFilePath"
	[XML]$XMLSettings = Get-Content $XMLFilePath
}
Else { Write-Verbose "XML File not found" }

$ErrorActionPreference = "SilentlyContinue"
#Getting the data from Text file.
$file =  "\\ushoudsutl01\Scripts\SnapshotCreation\Input_Servers.TXT"
$content = Get-Content $file |select -skip 1
#$content='USHOUBUILD01VT'
#forach loop for each row of column
foreach ($line in $content)
{
    $line1=$line -split ','
    $vm=$line1[0]
    $SNNumber=$line1[1]
    $RequestorLanid=$line1[2]  
    #If for selecting the Vcenter 
If($vm -like '*HOU*')
{
    $VC='usvmivcsalp200'
}
ELSEIf($vm -like '*HYD*')
{
    $VC='usvmivcsalp200'
}
ELSEif($vm -like '*ATL*')
{
    $VC='usvmivcsalp200'
}

#Getting the email ID from lanID
$email=get-email $RequestorLanid

If(Test-Connection -ComputerName $vm)
{
Cleanup-Variables "Begin"
$datestring = (Get-Date).ToString('dd-MM-y')
$snid=$snnumber
Write-Host "ServiceNow record :"$snnumber
If ($snid.length -eq 0) {$snid = "1"}  
Write-Verbose $email
Write-Verbose $datestring
Write-Verbose $env:USERNAME
Write-Verbose $snid
		#Added in version 1.0.0.1 to deal with switch to Modules
		Try
		{
			Add-PSSnapin VMware.VimAutomation.Core
			Add-PSSnapin "VMware.VimAutomation.Core"
			Add-PSSnapin "VMWare.VimAutomation.License"			
		}
	Catch [System.Management.Automation.PSArgumentException]{}	
	Finally { }
		
	Try { Get-Module vmware* -ListAvailable | Import-Module }
	Catch { }
	Finally { }		

If ($Defaultviservers -ne $null) {$Defaultviservers | Disconnect-VIServer -Confirm:$False}
Connect-VIServer -server $vc
$vmobject = Get-VM -Name $vm | Where {$_.powerstate -eq "PoweredOn"}

$snapshotlist = Get-Snapshot -VM $vmobject
$createsnapshot = $true
#If there are more than two snapshots skipping the creation. 
If ($snapshotlist.Count -gt 2) { $createsnapshot = $false 
write-debug 'Already 3 Snapshot Exists '
  $BODY = "The following snapshots already exist:    "
       Foreach ($snap in $snapshotlist) {
                     $BODY+= $snap.name + '         |         '
                     }     
                     $subject='Snapshot Creation skipped for :'+ $vm                                   
      Send-MailMessage -To $email -Cc "Operations.Server@invesco.com" -Subject $subject -From "MBFN6270@invesco.com" -SmtpServer "emailnasmtp.app.invesco.net" -Body $BODY            
                     }
#creating the snapshots
If ($createsnapshot -eq $true) {
Write-Debug 'Snapshort will be created'
       $snapshotname = "AUTOSNAPSHOT: " + $snid + ": " + $datestring + ": " + $env:USERNAME
       While ($snapshotlist.name -contains $snapshotname ) {
              $snid = 1 + $snid 
              $snapshotname = "AUTOSNAPSHOT#" + $snid + "," + $datestring.ToString() + "," + $env:USERNAME
              }
       $body = New-snapshot -VM $vmobject -Name $snapshotname 
       $subject='Snapshot creation successfull for : '+ $vm         
       Send-MailMessage -To $email -Cc "Operations.Server@invesco.com" -Subject $subject -From "MBFN6270@invesco.com" -SmtpServer "emailnasmtp.app.invesco.net" -Body $BODY
       # Send-MailMessage -To $email -Cc "GBLCSSOpsPlatform@invesco.com" -Subject $subject -From "MBFN6270@invesco.com" -SmtpServer "emailnasmtp.app.invesco.net" -Body $BODY            
       } 
#Cleanup-Variables "End"
}
else
{    
    $subject='Cannot create snapshot Server is not exist:"  '+ $vm
    Send-MailMessage -To $email -Cc "gadde.suresh@invesco.com" -Subject $subject -From "MBFN6270@invesco.com" -SmtpServer "emailnasmtp.app.invesco.net"
   # Send-MailMessage -To $email -Cc "GBLCSSOpsPlatform@invesco.com" -Subject $subject -From "MBFN6270@invesco.com" -SmtpServer "emailnasmtp.app.invesco.net" 
}    
}

Clear-Content $file
Add-Content $file 'ServerName,SNNumber,RequestorLanid'

