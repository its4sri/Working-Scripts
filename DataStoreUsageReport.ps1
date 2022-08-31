#set-executionpolicy Unrestricted -Force # Execute Policy 
##### Add VMWare Snanpin.
if(-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue))
{
   Add-PSSnapin VMware.VimAutomation.Core 
}
#*****************************************
$SCRIPT_PARENT   = Split-Path -Parent $MyInvocation.MyCommand.Definition 

#************** Remove old files ***************************
remove-item ($SCRIPT_PARENT + "\Report\*.html") -force

########### Connect VCs from VC_List.txt ############
$VCs= Get-Content ($SCRIPT_PARENT + "\vc_list.txt") -ErrorAction SilentlyContinue # mention vcenter name where you want to check resources.
# $VCs= Get-Content  -Path D:\Scripts\DataStoreSpaceReport\vc_list.txt  
$D = get-date -uformat "%m-%d-%Y-%H:%M" # To get a current date.

Write-Host "Connecting to VC" -foregroundcolor yellow

#*****************************************
foreach($vc in $VCs) 
{ 

Connect-VIServer $VC -WarningAction 0

$outputfile = ($SCRIPT_PARENT + "\Report\$($VC).html") #".\Report\$($VC).html"
Write-Host ""
Write-Host "Collecting details from $VC" -foregroundcolor green
$Result = @()
$Result += Get-View -ViewType Datastore | Where-Object {$_.Name -notmatch "pag"} | Select-Object -Property Name, 
  @{N="FreeSpaceGB";E={[Math]::Round($_.Summary.FreeSpace/1GB,0)}}, 
  @{N="CapacityGB"; E={[Math]::Round($_.Summary.Capacity/1GB,0)}}, 
  @{N="ProvisionedSpaceGB";E={[Math]::Round(($_.Summary.Capacity - $_.Summary.FreeSpace + $_.Summary.Uncommitted)/1GB,0)}},
  @{N="FreeSpace";E={[math]::Round(((100* ($_.Summary.FreeSpace/1GB))/ ($_.Summary.Capacity/1GB)),0)}}  | sort -Property "FreeSpace"
 
      $HTML = '<style type="text/css">
      #Header{font-family:"Trebuchet MS", Arial, Helvetica, sans-serif;width:100%;border-collapse:collapse;}
      #Header td, #Header th {font-size:14px;border:1px solid #98bf21;padding:3px 7px 2px 7px;}
      #Header th {font-size:14px;text-align:center;padding-top:5px;padding-bottom:4px;background-color:#cccccc;color:#000000;}
      #Header tr.alt td {color:#000;background-color:#EAF2D3;}
      </Style>'

    $HTML += "<HTML><BODY><Table border=1 cellpadding=0 cellspacing=0 id=Header><caption><font size=3 color=green><h1 align=""center"">~$VC-DataStore Verification Report~ </h1></font>
    <h4 align=""right""><font size=3 color=""#00008B"">Date: $D </font></h4></caption>
               
            <TR>
                  <TH><B>DataStore Name</B></TH>
                  <TH><B>Free Space (GB)</B></TD>
                  <TH><B>Capacity (GB)</B></TH>
                  <TH><B>Provisioned Space (GB)</B></TH>
                  <TH><B>Free Space (%)</B></TH>
                  
            </TR>"
    Foreach($Entry in $Result)
    {
        if($Entry.FreeSpace -lt "20")
            {
                  $HTML += "<TR bgColor=Red>"
            }
            else
            {
                  $HTML += "<TR>"
            }
            $HTML += "
                                    <TD>$($Entry.Name)</TD>
                                    <TD>$($Entry.FreeSpaceGB)</TD>
                                    <TD>$($Entry.CapacityGB)</TD>
                                    <TD>$($Entry.ProvisionedSpaceGB)</TD>
                                    <TD>$($Entry.FreeSpace)</TD>
                              </TR>"
    }
    $HTML += "</Table></BODY></HTML>"

      $HTML | Out-File $OutputFile

Disconnect-VIServer $VC -Confirm:$false
}

$Uname = Get-Content Env:USERNAME
$Comp = Get-Content Env:COMPUTERNAME
   
#Send mail-> 
    # Add email IDs in email_id.txt file with , and in next line.    
    $mailto = Get-Content ($SCRIPT_PARENT + "\email_id.txt") -ErrorAction SilentlyContinue
    $SMTPserver = "emailnasmtp.app.invesco.net" # SMTP server
    $msg = new-object Net.Mail.MailMessage  
    $smtp = new-object Net.Mail.SmtpClient($SMTPserver)  
    $msg.From = "MBFN6270@invesco.com" # Sender ID
    $msg.IsBodyHTML = $true 
    $msg.To.Add($mailto)  # Mail To id get from list
 
    $msg.Subject = "Datastores Usage Report - $vcs" # Subject of the email.
 
 foreach($vc in $vcs) 
     { 
     $MailTextT =  Get-Content ($SCRIPT_PARENT + "\Report\*.html") -ErrorAction SilentlyContinue
     #$Sig =  "<html><p class=MsoNormal><o:p>&nbsp;</o:p></p><B> Regards, <p> Ashok Kumar (ashokkumar.chukka@invesco.com)</B></p></html>"
     #$Top = "<html> This Script is executed on Server - <B>$Comp</B> by User - <b> $Uname </b></html>"
     #$MailText= $Top + $MailTextT + $Sig
     $MailText= $MailTextT
     
    } 
    
   $msg.Body = $MailText
   $smtp.send($msg)
      
 
#*****************************************