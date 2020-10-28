  [CmdletBinding()]
  PARAM (
    [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [String[]]$ComputerName = $env:ComputerName
  )
  #List of Manufacture Codes that could be pulled from WMI and their respective full names. Used for translating later.
  $ManufacturerHash = @{ 
    "AAC" =	"AcerView";
    "ACR" = "Acer";
    "AOC" = "AOC";
    "AIC" = "AG Neovo";
    "APP" = "Apple Computer";
    "AST" = "AST Research";
    "AUO" = "Asus";
    "BNQ" = "BenQ";
    "CMO" = "Acer";
    "CPL" = "Compal";
    "CPQ" = "Compaq";
    "CPT" = "Chunghwa Pciture Tubes, Ltd.";
    "CTX" = "CTX";
    "DEC" = "DEC";
    "DEL" = "Dell";
    "DPC" = "Delta";
    "DWE" = "Daewoo";
    "EIZ" = "EIZO";
    "ELS" = "ELSA";
    "ENC" = "EIZO";
    "EPI" = "Envision";
    "FCM" = "Funai";
    "FUJ" = "Fujitsu";
    "FUS" = "Fujitsu-Siemens";
    "GSM" = "LG Electronics";
    "GWY" = "Gateway 2000";
    "HEI" = "Hyundai";
    "HIT" = "Hyundai";
    "HSL" = "Hansol";
    "HTC" = "Hitachi/Nissei";
    "HWP" = "HP";
    "IBM" = "IBM";
    "ICL" = "Fujitsu ICL";
    "IVM" = "Iiyama";
    "KDS" = "Korea Data Systems";
    "LEN" = "Lenovo";
    "LGD" = "Asus";
    "LPL" = "Fujitsu";
    "MAX" = "Belinea"; 
    "MEI" = "Panasonic";
    "MEL" = "Mitsubishi Electronics";
    "MS_" = "Panasonic";
    "NAN" = "Nanao";
    "NEC" = "NEC";
    "NOK" = "Nokia Data";
    "NVD" = "Fujitsu";
    "OPT" = "Optoma";
    "PHL" = "Philips";
    "REL" = "Relisys";
    "SAN" = "Samsung";
    "SAM" = "Samsung";
    "SBI" = "Smarttech";
    "SGI" = "SGI";
    "SNY" = "Sony";
    "SRC" = "Shamrock";
    "SUN" = "Sun Microsystems";
    "SEC" = "Hewlett-Packard";
    "TAT" = "Tatung";
    "TOS" = "Toshiba";
    "TSB" = "Toshiba";
    "VSC" = "ViewSonic";
    "ZCM" = "Zenith";
    "UNK" = "Unknown";
    "_YV" = "Fujitsu";
      }

# Location Hash Table
$LocationHash = @{
"127.0.0" = "800 Scenic Drive";
"" = "800 Scenic Drive";
"" = "800 Scenic Drive";
"" = "800 Scenic Drive";
"" = "800 Scenic Drive";
"" = "912 D Street";
"" = "1418 J Street";
"" = "920 16th Street";
"" = "2101 Geer Road";
"" = "1208 9th Street";
"" = "4640 Spyres Way"; 
"" = "711 14th Street";
"" = "421 East Morris Ave";
"" = "500 North 9th Street";
"" = "2215 Bluegum Avenue";
"" = "251 East Hackett Rd";
"" = "1904 Richland Avenue";
"" = "1917 Memorial Drive";
"" = "Stanworks Patterson";
"" = "1310 W. Main Street";
"" = "801 11th Street";
"" = "190 Hackett Road";
"" = "1014 Scenic Drive";
}
      
# Declare SnipeIT Config
$baseURL = "https://itam.example.org/api/v1"
$apikey = "YOUR API KEY"

# Declare Globals
$serialnumber = (Get-WmiObject win32_bios).SerialNumber
$gethostname = $env:COMPUTERNAME
#---- To be used later for creating an asset
#$localassettag = [string]$gethostname -replace "\D+" -replace "[][]"
$getSubnetLocation
$currentuser = $env:UserName

# Declare Headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/x-www-form-urlencoded")
$headers.Add("Accept", "application/json")
$headers.Add("Authorization", "Bearer $apikey")

# Retrieve SnipeIT UserID with username
$username = Invoke-RestMethod "$baseURL/users?search=$currentuser&limit=1" -Method 'GET' -Headers $headers
$userid = $username.rows.id

# Retrieve Asset with serial
$assetvalues = Invoke-RestMethod "$baseURL/hardware/byserial/$serialnumber" -Method 'GET' -Headers $headers
$computervalue = Invoke-RestMethod "$baseURL/hardware/byserial/$serialnumber" -Method 'GET' -Headers $headers

$computerid = $computervalue.rows.id
$assetid = $assetvalues.rows.id
$assettag = $assetvalues.rows.asset_tag

# Declare JSON values
$checkout = @{
    assigned_user="$userid"
    checkout_to_type="user"
    note="Automated Checkout to $currentuser"

}
############################################################
# Define Functions
############################################################
function get-ipsubnet {

    $ipV4 = Test-Connection -ComputerName $env:COMPUTERNAME -Count 1 | Select -ExpandProperty IPV4Address

    $ipV4Octet = $ipV4.IPAddressToString

    return $ipV4Octet.Remove($ipV4Octet.LastIndexOf('.'))

}

function updateHostname() {

    if ($computervalue.rows.name -ne $gethostname) {
        
        Write-Host "hostname does not match, updating..."
        $patch_name = @{
            name="$gethostname"
            }
        Invoke-RestMethod "$baseURL/hardware/$computerid" -Method 'PATCH' -Headers $headers -Body $patch_name
    } else {
        Write-Host "Hostname up-to-date... skipping"
    }

}

function updateLocation() {

    # Location Globals
    $ipsubnet = get-ipsubnet
    $HashAddress = $LocationHash.$ipsubnet
    $location_query = @{
        search=$HashAddress
    }
    $locationID = Invoke-RestMethod "$baseURL/locations" -Method 'GET' -Headers $headers -Body $location_query 
    if ($computervalue.rows.rtd_location.name -ne $HashAddress) {
        
        Write-Host "Location does not match, updating..."

        $patch_name = @{
            rtd_location_id=$locationID.rows.id
            }
        Invoke-RestMethod "$baseURL/hardware/$computerid" -Method 'PUT' -Headers $headers -Body $patch_name
    } else {
        Write-Host "Location is up-to-date... skipping"
    }

}

function updateMonitorLocation() {

    # Location Globals
    $ipsubnet = get-ipsubnet
    $HashAddress = $LocationHash.$ipsubnet
    $location_query = @{
        search=$HashAddress
    }
    $locationID = Invoke-RestMethod "$baseURL/locations" -Method 'GET' -Headers $headers -Body $location_query 
    if ($assetvalues.rows.rtd_location.id -ne $computervalue.rows.rtd_location.id) {
        Write-Host "$Mon_Model $Mon_Serial_Number location does not match $assettag...updating"
        $patch_name = @{
            rtd_location_id=$locationID.rows.id
        }
        Invoke-RestMethod "$baseURL/hardware/$assetid" -Method 'PUT' -Headers $headers -Body $patch_name
    } else {
        Write-Host "Monitors location "$assetvalues.rows.rtd_location.id" is equal to the attached computers location" $computervalue.rows.rtd_location.id
    }

}

function updateUserLocation() {

    # Location Globals
    $ipsubnet = get-ipsubnet
    $HashAddress = $LocationHash.$ipsubnet
    $location_query = @{
        search=$HashAddress
    }
    $locationID = Invoke-RestMethod "$baseURL/locations" -Method 'GET' -Headers $headers -Body $location_query 
    if ($username.rows.location.id -ne $computervalue.rows.rtd_location.id) {
        Write-Host "User location ID does not match $assettag...updating"
        $patch_name = @{
            location_id=$locationID.rows.id
        }
        Invoke-RestMethod "$baseURL/users/$userid" -Method 'PUT' -Headers $headers -Body $patch_name
    } else {
        Write-Host "User location ID is equal to the attached computers location " $computervalue.rows.rtd_location.id " Skipping..."
    }

}

function AuditComputer() {

    try {
		$NextAuditDate = (Get-Date).AddYears(2).tostring(“yyyy-MM-dd”)
	    $audit_computer = @{
          asset_tag=$computervalue.rows.asset_tag
		  next_audit_date="$NextAuditDate"
        }
		Invoke-RestMethod "$baseURL/hardware/audit" -Method 'POST' -Headers $headers -Body $audit_computer
    } 
	catch {
        Write-Host "Unable to audit computer, probably does not exist, Skipping..."
		continue
    }
	
}

function AuditMonitor() {

    try {
		$NextAuditDate = (Get-Date).AddYears(2).tostring(“yyyy-MM-dd”)
		$audit_monitor = @{
          asset_tag=$assetvalues.rows.asset_tag
		  next_audit_date="$NextAuditDate"
        }
		Invoke-RestMethod "$baseURL/hardware/audit" -Method 'POST' -Headers $headers -Body $audit_monitor
    } 
	catch {
        Write-Host "Unable to audit monitor, probably does not exist, Skipping..."
		continue
    }
	
}

function CheckCurrentAssignedUser() {

    if ($computervalue.rows.assigned_to.id -ne $userid) {
        
        Write-Host "Checked out user does not match, updating..."
        #Checkin Asset from previous user
        Invoke-RestMethod "$baseURL/hardware/$assetid/checkin" -Method 'POST' -Headers $headers
        #Checkout Asset to current user
        Invoke-RestMethod "$baseURL/hardware/$assetid/checkout" -Method 'POST' -Headers $headers -Body $checkout
    } else {
        Write-Host "Asset Already Assigned to current user... skipping"
    }

}

############################################################
# Main
############################################################
# Check if Asset already belongs to a user
try {

    # Validate if hostname needs to be updated.
    updateHostname
    # Check if Computer location is accurate
    updateLocation
	# Check if user location matches computer location
	updateUserLocation
    # Validate if assigned user needs to be updated.
    CheckCurrentAssignedUser
	# Audit Computer
	AuditComputer
}
catch {
    Write-Host "Error at checking/assigning asset to user"
    continue
}
################ End Computer Checkout Logic ################

#Grabs the Monitor objects from WMI
$Monitors = Get-WmiObject -Namespace "root\WMI" -Class "WMIMonitorID" -ComputerName $ComputerName -ErrorAction SilentlyContinue
#Takes each monitor object found and runs the following code:
try {
    ForEach ($Monitor in $Monitors) {
        try {
            #Grabs respective data and converts it from ASCII encoding and removes any trailing ASCII null values
            If ($null -ne [System.Text.Encoding]::ASCII.GetString($Monitor.UserFriendlyName)) {
                $Mon_Model = ([System.Text.Encoding]::ASCII.GetString($Monitor.UserFriendlyName)).Replace("$([char]0x0000)","")
            } else {
                $Mon_Model = $null
            }
            If ($null -ne [System.Text.Encoding]::ASCII.GetString($Monitor.SerialNumberID)) {
                $Mon_Serial_Number = ([System.Text.Encoding]::ASCII.GetString($Monitor.SerialNumberID)).Replace("$([char]0x0000)","")
            } else {
                $Mon_Serial_Number = $null
            }
            If ($null -ne [System.Text.Encoding]::ASCII.GetString($Monitor.ManufacturerName)) {
                $Mon_Manufacturer = ([System.Text.Encoding]::ASCII.GetString($Monitor.ManufacturerName)).Replace("$([char]0x0000)","")
            } else {
                $Mon_Manufacturer = $null
            }

            #Sets a friendly name based on the hash table above. If no entry found sets it to the original 3 character code
            $Mon_Manufacturer_Friendly = $ManufacturerHash.$Mon_Manufacturer
            If ($null -eq $Mon_Manufacturer_Friendly) {
                $Mon_Manufacturer_Friendly = $Mon_Manufacturer
            }
            # Declare JSON and re-assign var values for Attached Monitor(s)
            $assetvalues = Invoke-RestMethod "$baseURL/hardware/byserial/$Mon_Serial_Number" -Method 'GET' -Headers $headers
            $assetid = $assetvalues.rows.id
            $checkout_Mon = @{
              assigned_asset="$computerid"
              checkout_to_type="asset"
              note="Detected a monitor change, Assigning $Mon_Model $Mon_Serial_Number to $assettag"
            }

            ################ Validate Monitors ################
            if ($assetvalues.rows.assigned_to.id -ne $computervalue.rows.id) {
                Write-Host "updating $Mon_Model $Mon_Serial_Number to $assettag."
                #Checkin Asset from previous user
                Invoke-RestMethod "$baseURL/hardware/$assetid/checkin" -Method 'POST' -Headers $headers
                #Checkout Asset to Current Attached Computer Asset
                Invoke-RestMethod "$baseURL/hardware/$assetid/checkout" -Method 'POST' -Headers $headers -Body $checkout_Mon
                # Validate if Name needs to be updated.
                Write-Host "checked out $Mon_Model $Mon_Serial_Number to $assettag"
            }
            elseif ($assetvalues.rows.assigned_to.id -eq $computervalue.rows.id) {
                Write-Host "Monitor $Mon_Model $Mon_Serial_Number is already checked out to $assettag... skipping"
            }
			# UPDATE MONITOR Location to match 
			updateMonitorLocation
			# Audit Monitor
			AuditMonitor
			
            ################ End Monitor Validation ################
        }
        catch {
            continue
        }
    }
}
catch {
    Write-Host "Error at monitor Foreach: " $_.Exception.Message
}
