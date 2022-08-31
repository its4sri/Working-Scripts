# Script will generate Disk Space Report for Exchange Servers (Daily, Weekly, Monthly)

$ErrorActionPreference = "SilentlyContinue";
$scriptpath = $MyInvocation.MyCommand.Definition 
$dir = Split-Path $scriptpath 

#Variables to configure
$percentWarning = 20;
$percentCritcal = 10;
$smtpServer = "emailnasmtp.app.invesco.net" 
$ReportSender = "donotreply@invesco.com"  
$users = "serveroperations@invesco.com", "IAMI-IT@invesco.com"; 
$MailSubject = "IAMI Servers DiskSpace Report $titledate"

#No change needed from here!!!
$reportPath = "$dir\Logs\"
$reportName = "DiskSpaceRpt_$(get-date -format ddMMyyyy).html";
$diskReport = $reportPath + $reportName
$redColor = "#FF0000"
$orangeColor = "#FBB917"
$whiteColor = "#FFFFFF"
$greenColor = "#7FFF00"
$i = 0;
$computers = Get-Content "$dir\servers_list.txt";
$datetime = Get-Date -Format "MM-dd-yyyy_HHmmss";
If (Test-Path $diskReport)
    {
        Remove-Item $diskReport
    }
$titleDate = get-date -uformat "%m-%d-%Y - %A"
$header = "
		<html>
		<head>
		<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>
		<title>DiskSpace Report</title>
		<STYLE TYPE='text/css'>
		<!--
        	table {
            		border: thin solid #666666;
        	}
		td {
			font-family: Tahoma;
			font-size: 11px;
			border-top: 1px solid #999999;
			border-right: 1px solid #999999;
			border-bottom: 1px solid #999999;
			border-left: 1px solid #999999;
			padding-top: 0px;
			padding-right: 0px;
			padding-bottom: 0px;
			padding-left: 0px;
		}
		body {
			margin-left: 5px;
			margin-top: 5px;
			margin-right: 0px;
			margin-bottom: 10px;
			table {
			border: thin solid #000000;
		}
		-->
		</style>
		</head>
		<body>
		<table width='100%'>
		<tr bgcolor='#CCCCCC'>
		<td colspan='7' height='25' align='center'>
		<font face='tahoma' color='#003399' size='4'><strong>DiskSpace Report for $titledate</strong></font>
		</td>
		</tr>
		</table>
"
 Add-Content $diskReport $header
 $tableHeader = "
 <table width='100%'><tbody>
	<tr bgcolor=#CCCCCC>
    <td width='10%' align='center'>Server</td>
	<td width='5%' align='center'>Drive Label</td>
	<td width='15%' align='center'>Drive</td>
	<td width='10%' align='center'>Total Capacity(GB)</td>
	<td width='10%' align='center'>Used Capacity(GB)</td>
	<td width='10%' align='center'>Free Space(GB)</td>
	<td width='5%' align='center'>Freespace %</td>
	</tr>
"
Add-Content $diskReport $tableHeader
  foreach($computer in $computers)
	{	
	$disks = Get-WmiObject -ComputerName $computer -Class Win32_Volume -Filter "DriveType = 3" | Where-Object {$_.Label -ne "System Reserved"}
	$computer = $computer.toupper()
		foreach($disk in $disks)
	{        
		$deviceID = $disk.Label;
        	$volName = $disk.Name;
		[float]$size = $disk.Capacity;
		[float]$freespace = $disk.FreeSpace; 
		$percentFree = [Math]::Round(($freespace / $size) * 100, 2);
		$sizeGB = [Math]::Round($size / 1073741824, 2);
		$freeSpaceGB = [Math]::Round($freespace / 1073741824, 2);
        $usedSpaceGB = [Math]::Round($sizeGB - $freeSpaceGB, 2);
        $color = $greenColor;
	if($percentFree -lt $percentWarning)      
		{
	   $color = $orangeColor	
      if($percentFree -lt $percentCritcal)
        {
        $color = $redColor
        }
        }        
    $dataRow = "
		<tr>
        <td width='10%'>$computer</td>
		<td width='5%' align='center'>$deviceID</td>
		<td width='15%' >$volName</td>
		<td width='10%' align='center'>$sizeGB</td>
		<td width='10%' align='center'>$usedSpaceGB</td>
		<td width='10%' align='center'>$freeSpaceGB</td>
		<td width='5%' bgcolor=`'$color`' align='center'>$percentFree</td>
		</tr>
"
Add-Content $diskReport $dataRow;
Write-Host -ForegroundColor DarkYellow "$computer $deviceID percentage free space = $percentFree";
    $i++		
	}
}
 $tableDescription = "
 </table><br><table width='20%'>
	<tr bgcolor='White'>
    <td width='10%' align='center' bgcolor='#FBB917'>Warning less than $percentWarning% free space</td>
	<td width='10%' align='center' bgcolor='#FF0000'>Critical less than $percentCritcal% free space</td>
	</tr>
"
 	Add-Content $diskReport $tableDescription
	Add-Content $diskReport "</body></html>"
if ($i -gt 0)
{
    foreach ($user in $users)
{
        Write-Host "Sending Email notification to $user"
		
		$smtp = New-Object Net.Mail.SmtpClient($smtpServer)
		$msg = New-Object Net.Mail.MailMessage
		$msg.To.Add($user)
        $msg.From = $ReportSender
		$msg.Subject = $MailSubject
        $msg.IsBodyHTML = $true
        $msg.Body = get-content $diskReport
		$smtp.Send($msg)
        $body = ""
    }
  }