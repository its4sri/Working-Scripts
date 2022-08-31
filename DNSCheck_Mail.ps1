$smtpServer = “emailnasmtp.app.invesco.net”
$msg = new-object Net.Mail.MailMessage
$smtp = new-object Net.Mail.SmtpClient($smtpServer) 
#From Address
$msg.From = "donotreply@invesco.com"
#To Address, Copy the below line for multiple recipients
$msg.To.Add(“Operations.Server@invesco.com”)
#Message Body
$msg.Body=”Hi Team,

Please find the attached report of DNS status for 2008 and 200R2 servers.
Please take necessary actions if any host record is mising.
Server which are showing down needs to be verified.

Regards,
Server Ops.
”
#Message Subject
$msg.Subject = “DNS record status report for 2008 and 2008 R2 PROD Servers”
#your file location
$files=Get-ChildItem “\\ushoudsip01\DNScheckreport”

Foreach($file in $files)
{
Write-Host “Attaching File :- ” $file
$attachment = New-Object System.Net.Mail.Attachment –ArgumentList \\ushoudsip01\DNScheckreport\$file
$msg.Attachments.Add($attachment)

}
$smtp.Send($msg)
$attachment.Dispose();
$msg.Dispose();
