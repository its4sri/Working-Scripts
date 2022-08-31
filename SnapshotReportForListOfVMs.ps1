#These are the properties assigned to the HTML table via the ConvertTo-HTML cmdlet - this is used to liven up the report and make it a bit easier on the eyes!
 
$tableProperties = "<style>"
$tableProperties = $tableProperties + "TABLE{border-width: 1px;border-style: solid;border-color: black;}"
$tableProperties = $tableProperties + "TH{border-width: 1px;padding: 5px;border-style: solid;border-color: black;}"
$tableProperties = $tableProperties + "TD{text-align:center;border-width: 1px;padding: 5px;border-style: solid;border-color: black;}"
$tableProperties = $tableProperties + "</style>"
 
# Main section of check
Write-Host "Looking for snapshots"
$date = get-date
$datefile = get-date -uformat '%m-%d-%Y-%H%M%S'
$filename = "F:\VMwareSnapshots_" + $datefile + ".htm"
 
#Get your list of VMs, look for snapshots. In larger environments, this may take some time as the Get-VM cmdlet is not very quick.
$ss = Get-vm "D:\Scripts\Manage-Snapshots\VMlist.txt" | Get-Snapshot
Write-Host "   Complete" -ForegroundColor Green
Write-Host "Generating snapshot report"
$ss | Select-Object vm, name, description, powerstate | ConvertTo-HTML -head $tableProperties -body "<th><font style = `"color:#FFFFFF`"><big> Snapshots Report (the following VMs currently have snapshots on!)</big></font></th> <br></br> <style type=""text/css""> body{font: .8em ""Lucida Grande"", Tahoma, Arial, Helvetica, sans-serif;} ol{margin:0;padding: 0 1.5em;} table{color:#FFF;background:#C00;border-collapse:collapse;width:647px;border:5px solid #900;} thead{} thead th{padding:1em 1em .5em;border-bottom:1px dotted #FFF;font-size:120%;text-align:left;} thead tr{} td{padding:.5em 1em;} tbody tr.odd td{background:transparent url(tr_bg.png) repeat top left;} tfoot{} tfoot td{padding-bottom:1.5em;} tfoot tr{} * html tr.odd td{background:#C00;filter: progid:DXImageTransform.Microsoft.AlphaImageLoader(src='tr_bg.png', sizingMethod='scale');} #middle{background-color:#900;} </style> <body BGCOLOR=""#333333""> <table border=""1"" cellpadding=""5""> <table> <tbody> </tbody> </table> </body>" | Out-File $filename
Write-Host "   Complete" -ForegroundColor Green
Write-Host "Your snapshot report has been saved to:" $filename
 
# Create mail message
 
$server = "emailnasmtp.app.invesco.net"
$port = 25
$to      = "operations.server@invesco.com"
$from    = "hemamallikarjuna.yakkala@invesco.com"
$subject = "Snapshot Report for Listed VM's"
 
$message = New-Object system.net.mail.MailMessage $from, $to, $subject, $body
 
#Create SMTP client
$client = New-Object system.Net.Mail.SmtpClient $server, $port
# Credentials are necessary if the server requires the client # to authenticate before it will send e-mail on the client's behalf.
$client.Credentials = [system.Net.CredentialCache]::DefaultNetworkCredentials
 
# Try to send the message
 
try {
    # Convert body to HTML
    $message.IsBodyHTML = $true
    $attachment = new-object Net.Mail.Attachment($filename)
    $message.attachments.add($attachment)
    # Send message
    $client.Send($message)
    "Message sent successfully"
 
}
 
# Catch an error
 
catch {
 
    "Exception caught in CreateTestMessage1(): "
 
}