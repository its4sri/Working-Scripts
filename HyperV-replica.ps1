# Get date in UK format day/month/year
$date = Get-Date -Format dd/MM/yy
 
# Send email message
#Send-MailMessage -From $MailFrom -To $MailTo -Subject $MailSubject -BodyAsHtml -Body "$status" -SmtpServer $MailServer
$smtpServer = "smtp.na.amvescap.com"
$msg = new-object Net.Mail.MailMessage
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$msg.From = "donotreply@invesco.com"
$msg.To.Add("ITInfra-ServerOperations@invesco.com")
#$msg.To.Add("venkata.dantuluri@invesco.com")
$msg.Subject = "Global Hyper-V Replication Status" 
$msg.IsBodyHTML = $true

#Mail content - Formated HTML tables
$style = ""
$style = "<html><head><style>BODY{font-family: Calibri; font-size: 11pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #87CEFA; padding: 5px; }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style></head>"
$body = ""
$body += "Please check below health status and if it is other than 'Normal' take necessary action<br>"

#Get replication status of Europe Servers
$varEUbody = ""
$varEUbody = "<br><u><b> Europe Servers </b></u><br>"
$varEUbody += "<table><tr><th>Name</th><th>State</th><th>Health</th><th>Mode</th><th>PrimaryServer</th><th>ReplicaServer</th></tr>"
$varEUstatus = Get-VMReplication -ComputerName GBLONHV01 | Select-Object Name, State, Health, Mode, PrimaryServer, ReplicaServer
$varValue = ""
foreach ($varValue in $varEUstatus) {
$varEUbody += "<tr><td>"+$varValue.'Name' + "</td>" + "<td>"+ $varValue.'State' + "</td>"

if ($varValue.'Health' -eq "Normal")
	{
		$varEUbody += "<td style=""background-color:#d3f8d3;color:green;""><b>$($varValue.'Health')</b></td>"
	}
	elseif ($varValue.'Health' -eq "Critical")
	{
		$varEUbody += "<td style=""background-color:#FAEBD7;color:red""><b>$($varValue.'Health')</b></td>"
	}
    else
    {
        $varEUbody += "<td style=""background-color:#ffbb99;color:ff4d4d""><b>$($varValue.'Health')</b></td>"
    }

$varEUbody += "<td>"+$varValue.'Mode' + "</td>" + "<td>"+ $varValue.'PrimaryServer' + "</td>" + "<td>"+ $varValue.'ReplicaServer' + "</td></tr>"

}
$varEUbody += "</table><br>"


#Get replication status of North America Servers
$varNUSbody = ""
$varNUSbody = "<br><u><b> North America Servers </b></u><br>"
$varNUSbody += "<table><tr><th>Name</th><th>State</th><th>Health</th><th>Mode</th><th>PrimaryServer</th><th>ReplicaServer</th></tr>"
$varNUSstatus = Get-VMReplication -ComputerName USHOUHV01 | Select-Object Name, State, Health, Mode, PrimaryServer, ReplicaServer

$varValue = ""
foreach ($varValue in $varNUSstatus) {
$varNUSbody += "<tr><td>"+$varValue.'Name' + "</td>" + "<td>"+ $varValue.'State' + "</td>"

if ($varValue.'Health' -eq "Normal")
	{
		$varNUSbody += "<td style=""background-color:#d3f8d3;color:green;""><b>$($varValue.'Health')</b></td>"
	}
	elseif ($varValue.'Health' -eq "Critical")
	{
		$varNUSbody += "<td style=""background-color:#FAEBD7;color:red""><b>$($varValue.'Health')</b></td>"
	}
    else
    {
        $varNUSbody += "<td style=""background-color:#ffbb99;color:ff4d4d""><b>$($varValue.'Health')</b></td>"
    }

$varNUSbody += "<td>"+$varValue.'Mode' + "</td>" + "<td>"+ $varValue.'PrimaryServer' + "</td>" + "<td>"+ $varValue.'ReplicaServer' + "</td></tr>"

}
$varNUSbody += "</table><br>"


$body += $varAPACbody + $varEUbody + $varNUSbody
$body += "Click <a href=http://sharepoint/sites/itinfrastructureportal/wintel/so/Shared%20Documents/Server%20Documents/Hyper-V%20-%20Small%20Office/Hyper-V%20Troubleshooting.doc>here</a> to open Hyper-V Troubleshooting doc. Script is scheduled in USHOUSSUTL01V.<br>"
$body += "</body></html>"

$msg.Body = $style + $body
$smtp.Send($msg)