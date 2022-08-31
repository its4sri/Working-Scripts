$ServerList = 'USDSVDSIPWP101'
# $ServerList = Get-DhcpServerInDC | Select DnsName #Get all DHCP servers from AD
$OutputFile = "D:\USDSVDSIPWP101.htm" 
 
# Get domain name, date and time for report title 
$DomainName = (Get-ADDomain).NetBIOSName  
$Time = Get-Date -Format t 
$CurrDate = Get-Date -UFormat "%D" 

# THreshold variables
$Alert = '90'
$Warn = '85'
if($CreateTranscript)
{
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if( -not (Test-Path ($scriptDir + "\Transcripts"))){New-Item -ItemType Directory -Path ($scriptDir + "\Transcripts")}
Start-Transcript -Path ($scriptDir + "\Transcripts\{0:yyyyMMdd}_Log.txt"  -f $(get-date)) -Append
}
 
# Import modules
Import-Module DhcpServer

################ 
##### MAIN ##### 
################ 

$HTML = '<style type="text/css"> 
#TSHead body {font: normal small sans-serif;}
#TSHead table {border-collapse: collapse; width: 100%; background-color:#ABABAB;}
#TSHead th {font: normal small sans-serif;text-align:left;padding-top:5px;padding-bottom:4px;background-color:#7FB1B3;}
#TSHead th, td {font: normal small sans-serif; padding: 0.25rem;text-align: left;border: 1px solid #FFFFFF;}
#TSHead tbody tr:nth-child(odd) {background: #D3D3D3;}
    </Style>' 

# Report Header
$Header = "<H2 align=center><font face=Arial>$DomainName USDSVDSIPWP101-DHCP Scope Statistics as of $Time on $CurrDate</font></H2>"  
$Header2 = "<H4 align=center><font face=Arial><span style=background-color:#FFF284>WARNING</span> at 80% In Use. <span style=background-color:#FF9797>CRITICAL</span> and email alert sent at 95% In Use.</font></H4>" 

$HTML += "<HTML><BODY><script src=sorttable.js></script><Table border=3 cellpadding=0 cellspacing=0 width=100% id=TSHead class=sortable>
        <TR> 
            <TH><B>Scope Name</B></TH>
			<TH><B>Scope State</B></TH>
			<TH><B>IP's In Use</B></TH>
			<TH><B>Free</B></TH>
			<TH><B>% In Use</B></TH>
			<TH><B>Reserved</B></TH>
			<TH><B>Scope ID</B></TH>
			<TH><B>Subnet Mask</B></TH>
			<TH><B>Start of Range</B></TH>
			<TH><B>End of Range</B></TH>
            <TH><B>Gateway</B></TH>
			<TH><B>Lease Duration</B></TH>
        </TR>
        " 

Foreach($Server in $ServerList)
{
$ScopeList = Get-DhcpServerv4Scope -ComputerName $Server
ForEach($Scope in $ScopeList.ScopeID) 
{
    Try{
    $ScopeInfo = Get-DhcpServerv4Scope -ComputerName $Server -ScopeId $Scope
    $ScopeStats = Get-DhcpServerv4ScopeStatistics -ComputerName $Server -ScopeId $Scope | Select ScopeID,AddressesFree,AddressesInUse,PercentageInUse,ReservedAddress
    $ScopeReserved = (Get-DhcpServerv4Reservation -ComputerName $server -ScopeId $scope).count
    $ScopeGateway = (Get-DhcpServerv4OptionValue -OptionId 3 -ScopeID $Scope -ComputerName $Server -ErrorAction:SilentlyContinue)
    }
    Catch{
    }
# Sessions where the username is blank and RDP sessions are excluded from the results	
                $HTML += "<TR>
                    <TD>$($ScopeInfo.Name)</TD>
					<TD bgcolor=`"$(if($ScopeInfo.State -eq "Inactive"){"AAAAB2"})`">$($ScopeInfo.State)</TD>
					<TD>$($ScopeStats.AddressesInUse)</TD>
					<TD>$($ScopeStats.AddressesFree)</TD>
                    <TD bgcolor=`"$(if($ScopeStats.PercentageInUse -gt $Alert){"FF9797"}elseif($ScopeStats.PercentageInUse -gt $Warn){"FFF284"}else{"A6CAA9"})`">$([System.Math]::Round($ScopeStats.PercentageInUse))</TD>
                    <TD>$($ScopeReserved)</TD>
					<TD>$($ScopeInfo.ScopeID.IPAddressToString)</TD>
					<TD>$($ScopeInfo.SubnetMask)</TD>
                    <TD>$($ScopeInfo.StartRange)</TD>
                    <TD>$($ScopeInfo.EndRange)</TD>
                    <TD>$($ScopeGateway.value)</TD>
                    <TD>$($ScopeInfo.LeaseDuration)</TD>
                    </TR>"
} 
}

$HTML += "<H2></Table></BODY></HTML>" 
$Header + $Header2 + $HTML | Out-File $OutputFile
########################################################################################
#############################################Send Email#################################
$smtphost = "emailnasmtp.app.invesco.net"
$email1 = "operations.server@invesco.com"
$email2 = "ITInfra-Wintel-DirectoryServices@invesco.com"
$email3 = "EnvironmentOperations@invesco.com"
$email4 = "MBFN8631@invesco.com"
$subject = "USDSVDSIPWP101 DHCP Scope Statistics" 
$body = Get-Content "D:\USDSVDSIPWP101.htm" 
$smtp= New-Object System.Net.Mail.SmtpClient $smtphost
$msg = New-Object System.Net.Mail.MailMessage
$msg.To.Add($email1)
$msg.To.Add($email3)
$msg.To.Add($email4)
$msg.Cc.Add($email2)
$msg.from = "DoNotReply@invesco.com"
$msg.subject = $subject
$msg.body = $body 
$msg.isBodyhtml = $true 
$smtp.send($msg) 

########################################################################################

########################################################################################