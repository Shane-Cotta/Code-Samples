#Configurable Vars
$FileName = "users.csv"
$EmailDomain = "@abc.edu"
$Source = "/Users/shanecotta/Desktop/"
$Destination = "/Users/shanecotta/Desktop/"
$TimeStamp = Get-Date -Format "yyyyMMddHHmmss"
# Email Settings
$MailSender = "no-reply@domain.com"
$MailReciepient = "example@domain.com"
$SMTPServer = "smtp.domain.com"
$Port = "587"
$EmailUsername = "example@domain.com"
$EmailPassword = "password"

##################
# MAIN
##################
try {
    $Results = @{}
    $Delta = @{}
    $Path = $Source + $FileName
    $LogFile = $Source + "log.txt"
    # Check if Directory Structure and script files exists
    if (Test-Path -Path $Destination\"Proccessed"){
    } else {
        New-Item -ItemType directory $Destination\"Proccessed"
    }
    if ([System.IO.File]::Exists($LogFile)){
    } else{
        New-Item -ItemType "file" -Path $LogFile
        Add-Content -Path $LogFile -Value "TIMESTAMP, STATUS, MESSAGE"
    }
    # Check if file exists
    if ([System.IO.File]::Exists($Path)){
        # Proccess each record within csv
        ForEach ($row in import-csv $Path){
            # Validate email domans match
            if ($row.emailaddress -match $EmailDomain)
            {
                # Add matching results to Hash table
                $Results.add($row.emailaddress,$row.name)
                $MSG = "$TimeStamp, INFO, Added " + $row.emailaddress
                Add-Content -Path $LogFile -Value $MSG
            } else {
                # Add Deltas to the delta hash table
                $Delta.add($row.emailaddress,$row.name)
                $MSG = "$TimeStamp, WARN, " + $row.emailaddress + " Does not match domain"
                Add-Content -Path $LogFile -Value $MSG
            }
        }
        # Export proccessed Result set to timestamped csv
        $Results.GetEnumerator() |
            Select-Object -Property @{N='name';E={$_.Value}},
            @{N='emailaddress';E={$_.Key}} | 
            Export-Csv -UseQuotes AsNeeded -NoTypeInformation -Path $Destination\"Proccessed"\"users$TimeStamp.csv"
            ##UNCOMMENT ME
            ##Move-Item -Path $Source$FileName -Destination $proccessed\"$TimeStamp.csv"
        # Send follow up email.
        try {       
            $message = new-object Net.Mail.MailMessage;
            $message.From = $MailSender;
            $message.To.Add($MailReciepient);
            $message.Subject = "Emails have been proccessed";
            $Body = [string]$Results.Count + " Emails met criteria and were proccessed `n" + [string]$Delta.Count + " Did not meet criteria `n" + "Job Finished:" + [string]$TimeStamp
            $message.Body = $Body;
            $smtp = new-object Net.Mail.SmtpClient($SMTPServer, $Port);
            $smtp.EnableSSL = true;
            $smtp.Credentials = New-Object System.Net.NetworkCredential($EmailUsername, $EmailPassword);
            $smtp.send($message);
        }
        catch {
            $MSG = "$TimeStamp, ERROR, SMTP: " + $_.Exception.Message
            Add-Content -Path $LogFile -Value $MSG
        }
        Write-Host "########## Deltas"
        Write-Host @Delta
        Write-Host "########## Results"
        Write-Host @Results
    # If user.csv is not found continue
    } else {
        $MSG = "$TimeStamp, INFO, Nothing to proccess found"
        Add-Content -Path $LogFile -Value $MSG
    }
}
#Log Errors
catch {
    # You can also use this to error log to a Sql DB or call a webhook with a ticket system to create a bug (ex. Jira, Service Now and etc...)
    $MSG = "$TimeStamp, ERROR, " + $_.Exception.Message
    Add-Content -Path $LogFile -Value $MSG
}
