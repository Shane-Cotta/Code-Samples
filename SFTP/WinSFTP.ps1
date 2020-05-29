# ===========================================
# Assign Globals Vars and load assebmlies
# ===========================================
# Get Store
try
    {
        $store = # value retrieval command
    }
catch
    {
        Write-output "Error: Unable to get store number from ACS, $timestamp" >> # log location
        $store = # exception value
        Write-output "Warn: Default store has been set to $store, $timestamp" >> # log location
    }

# Create GetCreds Payload
$getcreds = @{
    key = $store
}

# Convert Payload to JSON and create request
$json = $getcreds | ConvertTo-Json
$callcreds = (Invoke-RestMethod 'https://example.com' -Method Post -Body $json -ContentType 'application/json').result

# Get Current Date and Time
$timestamp = Get-Date -Format "yyMMddHHmmss"

# ============================
# MAIN
# ============================
try
    {
        # Load WinSCP .NET assembly
        Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"

        # Set up session options
        $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
            Protocol = [WinSCP.Protocol]::Sftp
            HostName = $callcreds.host_name
            UserName = $callcreds.username
            Password = $callcreds.password
            GiveUpSecurityAndAcceptAnySshHostKey = $True
    }
    
    $session = New-Object WinSCP.Session

    try
        {
            # Connect
            $session.Open($sessionOptions)

            # Upload files
            $transferOptions = New-Object WinSCP.TransferOptions -Property @{
                FilePermissions = $Null
                PreserveTimestamp = $False
                TransferMode = [WinSCP.TransferMode]::Binary
            }

            $transferResult =
                $session.PutFiles("# Local DIR ", "/example/dir/$store",$False, $transferOptions)

            # Throw on any error
            $transferResult.Check()

            # Print results
            foreach ($transfer in $transferResult.Transfers)
            {
                Write-output "Success: Upload of $($transfer.Filename) $timestamp" >> # log location
            }
        }
        finally
        {
            # Disconnect, clean up
            $session.Dispose()
        }

        exit 0
    }
catch
{
    Write-output "Error: $($_.Exception.Message) $timestamp" >> # log location
    exit 1
}
