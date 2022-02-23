#Configurable Vars
$FileName = "users.csv"
$EmailDomain = "@abc.edu"
$RootDIR = "/Users/shanecotta/Desktop/"
$SourceFolder = "incoming"
$DestinationFolder = "outgoing"
$ProccessedFolder = "proccessed"
$TimeStamp = Get-Date -Format "yyyyMMddHHmmss"
# Email Settings
$MailSender = "no-reply@keepitsimply.net"
$MailReciepient = "me@shanecotta.com"
$SMTPServer = "email-smtp.us-west-1.amazonaws.com"
$Port = "587"
$EmailUsername = "AKIAQTI42N62WR53QXKX"
$EmailPassword = $args[0]

##################
# MAIN
##################
try {
    $Results = @{}
    $Delta = @{}
    $Path = $RootDIR + $FileName
    $LogFile = $RootDIR + "log.txt"
    # Check if Directory Structure(s) and log file exists, if not create and start logging
    if ([System.IO.File]::Exists($LogFile)){
    } else{
        New-Item -ItemType "file" -Path $LogFile
        Add-Content -Path $LogFile -Value "TIMESTAMP,STATUS,MESSAGE"
        $MSG = "$TimeStamp,WARN,Logfile missing: created " + $LogFile
        Add-Content -Path $LogFile -Value $MSG
    }
    if (Test-Path -Path $RootDIR\$SourceFolder){
    } else {
        New-Item -ItemType directory $RootDIR\$SourceFolder
        $MSG = "$TimeStamp,WARN,Source DIR missing: created " + $RootDIR + $SourceFolder
        Add-Content -Path $LogFile -Value $MSG
    }
    if (Test-Path -Path $RootDIR\$DestinationFolder){
    } else {
        New-Item -ItemType directory $RootDIR\$DestinationFolder
        $MSG = "$TimeStamp,WARN,Source DIR missing: created " + $RootDIR + $DestinationFolder
        Add-Content -Path $LogFile -Value $MSG
    }
    if (Test-Path -Path $RootDIR\$ProccessedFolder){
    } else {
        New-Item -ItemType directory $RootDIR\$ProccessedFolder
        $MSG = "$TimeStamp,WARN,Proccessed DIR missing: created " + $RootDIR + $ProccessedFolder
        Add-Content -Path $LogFile -Value $MSG
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
                $MSG = "$TimeStamp,INFO,Added " + $row.emailaddress
                Add-Content -Path $LogFile -Value $MSG
            } else {
                # Add Deltas to the delta hash table
                $Delta.add($row.emailaddress,$row.name)
                $MSG = "$TimeStamp,WARN," + $row.emailaddress + " Does not match domain"
                Add-Content -Path $LogFile -Value $MSG
            }
        }
        # Export proccessed Result set to timestamped csv
        $Results.GetEnumerator() |
            Select-Object -Property @{N='name';E={$_.Value}},
            @{N='emailaddress';E={$_.Key}} | 
            Export-Csv -UseQuotes AsNeeded -NoTypeInformation -Path $RootDIR\$DestinationFolder\"users$TimeStamp.csv"
            ##UNCOMMENT ME
            ##Move-Item -Path $RootDIR$FileName -Destination $RootDIR\$ProccessedFolder\"$TimeStamp.csv"
        # Send follow up email.
        try {       
            $message = new-object Net.Mail.MailMessage;
            $message.From = $MailSender;
            $message.To.Add($MailReciepient);
            $message.Subject = "Emails have been proccessed";
            $Body = [string]$Results.Count + " Emails met criteria and were proccessed `n" + [string]$Delta.Count + " Did not meet criteria `n" + "Job Finished:" + [string]$TimeStamp
            $message.Body = $Body;
            $smtp = new-object Net.Mail.SmtpClient($SMTPServer, $Port);
            $smtp.EnableSSL = $true;
            $smtp.Credentials = New-Object System.Net.NetworkCredential($EmailUsername, $EmailPassword);
            $smtp.send($message);
        }
        catch {
            $MSG = "$TimeStamp,ERROR,SMTP: " + $_.Exception.Message
            Add-Content -Path $LogFile -Value $MSG
        }
    # If user.csv is not found continue
    } else {
        $MSG = "$TimeStamp,INFO,Nothing to proccess found"
        Add-Content -Path $LogFile -Value $MSG
    }
}
#Log Errors
catch {
    $MSG = "$TimeStamp,ERROR," + $_.Exception.Message
    Add-Content -Path $LogFile -Value $MSG
}
