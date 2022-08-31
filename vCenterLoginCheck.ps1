
Function Get-VCReport
{

   Begin{

            Remove-Item "D:\Scripts\vCenterSOD\VCinventory.xlsx" -Force
          
                    
            $excelobject = New-Object -ComObject Excel.Application
            $workbook = $excelobject.Workbooks.add()
            $Filename = "D:\Scripts\vCenterSOD\VCinventory.xlsx"
            $workbook.Saveas($Filename)  
            
            $vc = Get-Content "D:\Scripts\vCenterSOD\Servers.txt"
              
                Foreach($vi in $vc)
                {
            Connect-VIServer -Server $vi -ErrorAction Continue
            
                }

         }

   Process
            {

            [string]$comp = $_
                               				
		           Switch ($comp)
                   {

                     1 {
                      $ws = $workbook.WorkSheets.add()
                       $ws.Name = "HostStatus"
                        $row = 1
                        $ws.cells.item($row,1) = "HostName"
                        $ws.cells.item($row,2) = "Status"
                        $ws.cells.item($row,3)= "CPU Usage in %"
                        $ws.cells.item($row,4)= "Mem Usage in %"
                        $ws.cells.item($row,5)= "VC Name"
                         $row = 2
                       
                        $vc = Get-content "D:\Scripts\vCenterSOD\Servers.txt"  

                       foreach($vi in $vc)
                       
                           {
                                                     
$hsVC1 = Get-VMhost -Server $vi|Select-Object Name,ConnectionState,@{Name='CPUUsage'; Expression={[math]::Round($($_.CpuUsageMhz/$_.CpuTotalMhz)*100)}},@{Name='MemUsage'; Expression={[math]::Round($($_.MemoryUsageGB/$_.MemoryTotalGB)*100)}}
                
                          

                                    foreach($Alarms in $hsVC1)
                                    {
                                     $status = $Alarms.ConnectionState
                                    $ws.cells.item($row,1) = $Alarms.Name
                                    $ws.cells.item($row,2) = "$status"
                                    $ws.cells.item($row,3)= $Alarms.CPUUsage
                                    $ws.cells.item($row,4)= $Alarms.MemUsage
                                    $ws.cells.item($row,5)= $vi

                                    $row++
                                    }
                     
                           }
                       }
                       
                   2 {$ws = $workbook.WorkSheets.add()
                          $ws.Name = "Datastore Information"
                               
                       
                        $row = 1
                        
                        $ws.cells.item($row,1) = "DS Name"
                        $ws.cells.item($row,2) = "Capacity in GB"
                        $ws.cells.item($row,3)= "Free Space in %"
                        $ws.cells.item($row,4)= "VC Name"
                        $row = 2
                        
                        $vc = Get-content "D:\Scripts\vCenterSOD\Servers.txt"  
                        foreach($vi in $vc)
                        {

$DSVC1 = Get-Datastore -Server $vi |Select-Object Name,CapacityGB,@{Name='FreeSpace'; Expression={[math]::Round($($_.FreespaceGB/$_.CapacityGB)*100)}}
                               
                            
                            foreach($DSVC in $DSVC1)
                            {
                            $ws.cells.item($row,1) = $DSVC.name
                            $ws.cells.item($row,2) = $DSVC.CapacityGB
                            $ws.cells.item($row,3)= $DSVC.FreeSpace
                            $ws.cells.item($row,4)= $vi
                            $row++
                            }
                        }

                                                        
                      }

                    3 {

                    $ws = $workbook.WorkSheets.add()
                          $ws.Name = "Alarms"
                               
                          $row = 1
                        
                        $ws.cells.item($row,1) = "HostName"
                        $ws.cells.item($row,2) = "Alarm"
                        $ws.cells.item($row,3) = "Priority"
                        $ws.cells.item($row,4) = "VCName"
                         $row = 2

                        $vc = Get-Content "D:\Scripts\vCenterSOD\Servers.txt"  

                        foreach($vi in $vc)
                        {
                        
                        $hst = Get-VMHost -server $vi -ErrorAction Continue
                        Foreach($ht in $hst)
                              {
                                $esx = Get-View $ht
                                foreach($triggered in $esx.TriggeredAlarmState)
                                    {
                                    $alarmDef = Get-View -Id $triggered.Alarm
                                    if(($triggered.overallstatus -like "Red") -or ($triggered.overallstatus -like "Yellow"))
                                            {
                                            $war = $alarmDef.Info.Name
                                            $state = $triggered.overallstatus
                                            $Name = $ht.name
                            
                                                   

                                                    $ws.cells.item($row,1) = $Name
                                                    $ws.cells.item($row,2) = $war
                                                    $ws.cells.item($row,3)= "$State"
                                                    $ws.cells.item($row,4)= $vi
                                                    $row++
                                            }

                                    }

                               }

                        }

                    
                      } 
                      
                     4{$ws = $workbook.WorkSheets.add()
                          $ws.Name = "vCenter Status"
                               
                       
                        $row = 1
                        
                        $ws.cells.item($row,1) = "VC Name"
                        $ws.cells.item($row,2) = "Login Status"
                        $row = 2
                        
                        $vc = Get-content "D:\Scripts\vCenterSOD\Servers.txt"  
                        foreach($vis in $vc)
                        {


                            Connect-VIServer $vis
                             $VI = $defaultVIServer
             
                             If($vis -eq $VI)

                             {
                             $loginstatus = "Susccess"
                                                             
                            $ws.cells.item($row,1) = $vis
                            $ws.cells.item($row,2) = $loginstatus
                            $row++
                            }
                            
                        }

                                                        
                      }
                      
                         
                   }
               
            }           

   End
       {
          $workbook.WorkSheets.item("sheet1").delete()
           $workbook.Save()
            $excelobject.Workbooks.Close()
            $excelobject.Quit()
                [void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook)
                [void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($excelobject)
                [void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($ws)
                [GC]::Collect()
            Disconnect-VIserver * -Confirm:$false

       }

}



Function VCConnection
{
BEGIN
	{
	
	#This script is for checking VC Connection Status

    Remove-Item "D:\Scripts\vCenterSOD\Report.htm" -Force
    
    $i = 0

   
$reportpath = "D:\Scripts\vCenterSOD\Report.htm" 

new-item $reportpath -type file

$report = $reportpath

Clear-Content $report 
Add-Content $report "<html>" 
Add-Content $report "<head>" 
Add-Content $report "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>" 
Add-Content $report '<title>vCenter Login Check</title>' 
add-content $report '<STYLE TYPE="text/css">' 
add-content $report  "<!--" 
add-content $report  "td {" 
add-content $report  "font-family: Tahoma;" 
add-content $report  "font-size: 11px;" 
add-content $report  "border-top: 1px solid #999999;" 
add-content $report  "border-right: 1px solid #999999;" 
add-content $report  "border-bottom: 1px solid #999999;" 
add-content $report  "border-left: 1px solid #999999;" 
add-content $report  "padding-top: 0px;" 
add-content $report  "padding-right: 0px;" 
add-content $report  "padding-bottom: 0px;" 
add-content $report  "padding-left: 0px;" 
add-content $report  "}" 
add-content $report  "body {" 
add-content $report  "margin-left: 5px;" 
add-content $report  "margin-top: 10px;" 
add-content $report  "margin-right: 0px;" 
add-content $report  "margin-bottom: 10px;" 
add-content $report  "" 
add-content $report  "table {" 
add-content $report  "border: thin solid #000000;" 
add-content $report  "}" 
add-content $report  "-->" 
add-content $report  "</style>" 
Add-Content $report "</head>" 
Add-Content $report "<body>" 
add-content $report  "<table width='100%'>" 
add-content $report  "<tr bgcolor='Lavender'>" 
add-content $report  "<td colspan='7' height='25' align='center'>" 
add-content $report  "<font face='tahoma' color='#003399' size='4'><strong>vCenter Login Check</strong></font>" 
add-content $report  "</td>" 
add-content $report  "</tr>" 
add-content $report  "</table>" 
add-content $report  "<table width='100%'>" 
Add-Content $report  "<tr bgcolor='Lavender'>" 
Add-Content $report  "<td width='5%' align='center'><B>vCenter</B></td>" 
Add-Content $report  "<td width='5%' align='center'><B>Status</B></td>" 

	}
	PROCESS
	{	
Add-Content $report "</tr>" 

     [string]$computerName = $_.TrimEnd()

             Connect-VIServer $computerName
             $VI = $defaultVIServer
             
                   If($computerName -eq $VI)
                    {
                      Add-Content $report "<td bgcolor= 'Lavender' align=center><B>$VI</B></td>"
                      Add-Content $report "<td bgcolor= 'Lavender' align=center><B>Success</B></td>"
                      Disconnect-VIServer $computerName -confirm:$false
                    }	
                    
                    Else
                    {
                      Add-Content $report "<td bgcolor= 'Lavender' align=center><B>$computerName</B></td>"
                      Add-Content $report "<td bgcolor= 'Red' align=center><B>Failed</B></td>"
                        $i = $i+1
                    }

 Add-Content $report "</tr>"        
		
	}
    END	
    { 

     If($i -ne 0)
       {
       $overallstate = "$i failed"
       }
      Else
       {
       $overallstate = "Success"
       }
$Counters = 1, 2, 3, 4
$Counters | Get-VCReport

#Send email
$smtpServer = "emailnasmtp.app.invesco.net" 
$MailFrom = "donotreply@invesco.com" 
$mailto = "serveroperations@invesco.com"
$msg = new-object system.Net.Mail.MailMessage
$file = "D:\Scripts\vCenterSOD\VCinventory.xlsx"
$attachment = New-Object Net.Mail.Attachment($file)
$msg.Attachments.Add($attachment)
$smtp = new-object Net.Mail.SmtpClient($smtpServer) 
$msg.From = $MailFrom 
$msg.IsBodyHTML = $true 
$msg.To.Add($Mailto) 
#$msg.CC.Add($mailcc)
$msg.Subject = "Global VMware Healthchecks $overallstate " 
$MailTextT =  Get-Content  -Path "D:\Scripts\vCenterSOD\Report.htm"
$msg.Body = $MailTextT 
$smtp.Send($msg) 
    Write-host "Script Completed"
    }

}
Get-Content D:\Scripts\vCenterSOD\Servers.txt | VCConnection