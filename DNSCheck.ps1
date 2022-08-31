$Output= @()
$names = Get-content "D:\Chaitanya\DNSCheck\Prod.txt"
foreach ($name in $names)
{
 if (Test-Connection -ComputerName $name -Count 1 -ErrorAction SilentlyContinue){
  $Output+= "$name,up";Resolve-DnsName -Type A ($name)
   Write-Host "$Name up" -ForegroundColor Green
  }
  else{
    $Output+= "$name,down"
    Write-Host "$Name down" -ForegroundColor Red
  }
}
$Output | Out-file D:\Chaitanya\DNScheckreport\ServerDNSStats.csv