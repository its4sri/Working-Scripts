################################################
# Configure the variables below for the vCenter
################################################
$VMName = "USSQLRDMWD100"
$vCenter = "usvmivcsalp101.corp.amvescap.net"
$ScriptDirectory = "D:\Scripts\Disk Export\"
################################################
# Running the script, nothing to change below
################################################
#######################
# Importing vCenter credentials
#######################
# Setting credential file
$vCenterCredentialsFile = $ScriptDirectory + "\vCenterCredentials.xml"
# Testing if file exists
$vCenterCredentialsFileTest =  Test-Path $vCenterCredentialsFile
# IF doesn't exist, prompting and saving credentials
IF ($vCenterCredentialsFileTest -eq $False)
{
$vCenterCredentials = Get-Credential -Message "Enter vCenter login credentials"
$vCenterCredentials | EXPORT-CLIXML $vCenterCredentialsFile -Force
}
ELSE
{
# Importing credentials
$vCenterCredentials = IMPORT-CLIXML $vCenterCredentialsFile
}
#######################
# Installing then importing PowerCLI module
#######################
$PowerCLIModuleCheck = Get-Module -ListAvailable VMware.PowerCLI
IF ($PowerCLIModuleCheck -eq $null)
{
Install-Module -Name VMware.PowerCLI –Scope CurrentUser -Confirm:$false -AllowClobber
}
# Importing PowerCLI
Import-Module VMware.PowerCLI
#######################
# Connecting to vCenter
#######################
Connect-VIServer -Server $vCenter -Credential $vCenterCredentials
#####################
# Getting VM guest disk info
#####################
$VMGuestDiskScript = Invoke-VMScript -ScriptText {
# Creating alphabet array
$Alphabet=@()
65..90|ForEach{$Alphabet+=[char]$_}
# Getting drive letters inside the VM where the drive letter is in the alphabet, can't filter on null or empty for some reason
$DriveLetters = Get-Partition | Where-Object {($Alphabet -match $_.DriveLetter)} | Select -ExpandProperty DriveLetter
# Reseting serials
$DiskArray = @()
# For each drive letter getting the serial number
ForEach ($DriveLetter in $DriveLetters)
{
# Getting disk info
$DiskInfo = Get-Partition -DriveLetter $DriveLetter | Get-Disk | Select *
$DiskSize = $DiskInfo.Size
$DiskUUID = $DiskInfo.SerialNumber
# Formatting serial to match in vSphere, if not null
IF ($DiskSerial -ne $null)
{
$DiskSerial = $DiskSerial.Replace("_","").Replace(".","")
}
# Adding to array
$DiskArrayLine = New-Object PSObject
$DiskArrayLine | Add-Member -MemberType NoteProperty -Name "DriveLetter" -Value "$DriveLetter"
$DiskArrayLine | Add-Member -MemberType NoteProperty -Name "SizeInBytes" -Value "$DiskSize"
$DiskArrayLine | Add-Member -MemberType NoteProperty -Name "UUID" -Value "$DiskUUID"
$DiskArray += $DiskArrayLine
}
# Converting Disk Array to CSV data format
$DiskArrayData = $DiskArray | ConvertTo-Csv
# Returning Disk Array CSV data to main PowerShell script
$DiskArrayData
# End of invoke-vmscript below
} -VM $VMName -ToolsWaitSecs 120
# Pulling the serials from the invoke-vmscript and trimming blank spaces
$VMGuestDiskCSVData = $VMGuestDiskScript.ScriptOutput.Trim()
# Converting from CSV format
$VMGuestDiskData = $VMGuestDiskCSVData | ConvertFrom-Csv
# Hostoutput of VM Guest Data
"
VMGuestDiskData:" 
$VMGuestDiskData | Format-Table -AutoSize
#####################
# Building list of VMDKs for the Customer VM
#####################
# Creating array
$VMDKArray = @()
# Getting VMDKs for the VM
$VMDKs = Get-VM $VMName | Get-HardDisk
# For Each VMDK building table array
ForEach($VMDK in $VMDKs)
{
# Getting VMDK info
$VMDKFile = $VMDK.Filename
$VMDKName = $VMDK.Name
$VMDKControllerKey = $VMDK.ExtensionData.ControllerKey
$VMDKUnitNumber = $VMDK.ExtensionData.UnitNumber
$VMDKDiskDiskSizeInGB = $VMDK.CapacityGB
$VMDKDiskDiskSizeInBytes = $VMDK.ExtensionData.CapacityInBytes
# Getting UUID
$VMDKUUID = $VMDK.extensiondata.backing.uuid.replace("-","")
# Using Controller key to get SCSI bus number
$VMDKBus = $VMDK.Parent.Extensiondata.Config.Hardware.Device | Where {$_.Key -eq $VMDKControllerKey}
$VMDKBusNumber = $VMDKBus.BusNumber
# Creating SCSI ID
$VMDKSCSIID = "scsi:"+ $VMDKBusNumber + ":" + $VMDKUnitNumber
# Matching VMDK to drive letter based on UUID first, if no serial UUID matching on size in bytes
$VMDKDiveLetter = $VMGuestDiskData | Where-Object {$_.UUID -eq $VMDKUUID} | Select -ExpandProperty DriveLetter
$VMDKMatchOn = "UUID"
IF ($VMDKDiveLetter -eq $null)
{
$VMDKDiveLetter = $VMGuestDiskData | Where-Object {$_.SizeInBytes -eq $VMDKDiskDiskSizeInBytes} | Select -ExpandProperty DriveLetter
$VMDKMatchOn = "Size"
}
# Matching drive letter for marking SWAP disk
IF ($SWAPDriveLetters -match $VMDKDiveLetter)
{
$VMDKSwap = "true"
}
ELSE
{
$VMDKSwap = "false"
}
# Creating array of VMDKs
$VMDKArrayLine = New-Object PSObject
$VMDKArrayLine | Add-Member -MemberType NoteProperty -Name "VM" -Value $VMName
$VMDKArrayLine | Add-Member -MemberType NoteProperty -Name "DiskName" -Value $VMDKName
$VMDKArrayLine | Add-Member -MemberType NoteProperty -Name "DriveLetter" -Value $VMDKDiveLetter
$VMDKArrayLine | Add-Member -MemberType NoteProperty -Name "MatchedOn" -Value $VMDKMatchOn
$VMDKArrayLine | Add-Member -MemberType NoteProperty -Name "DiskSizeGB" -Value $VMDKDiskDiskSizeInGB
$VMDKArrayLine | Add-Member -MemberType NoteProperty -Name "SCSIBus" -Value $VMDKBusNumber
$VMDKArrayLine | Add-Member -MemberType NoteProperty -Name "SCSIUnit" -Value $VMDKUnitNumber
$VMDKArrayLine | Add-Member -MemberType NoteProperty -Name "SCSIID" -Value $VMDKSCSIID
$VMDKArrayLine | Add-Member -MemberType NoteProperty -Name "DiskUUID" -Value $VMDKUUID
$VMDKArrayLine | Add-Member -MemberType NoteProperty -Name "DiskSizeBytes" -Value $VMDKDiskDiskSizeInBytes
$VMDKArrayLine | Add-Member -MemberType NoteProperty -Name "DiskFile" -Value $VMDKFile
$VMDKArray += $VMDKArrayLine
}
#####################
# Final host output of VMDK array
#####################
$VMDKArray | Format-Table -AutoSize
#####################
# End of script
#####################