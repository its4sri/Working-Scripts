$Names = Get-Content -Path "D:\Scripts\ScheduledRebootScript_BusinessObjects\BusineessObjectsServerList.txt"
Restart-Computer -ComputerName $Names -Force -WsmanAuthentication Kerberos