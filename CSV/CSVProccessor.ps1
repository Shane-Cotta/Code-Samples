#Configurable Vars
$FileName = "users.csv"
$EmailDomain = "@abc.edu"
$Source = "c:/temp/incoming/"
$Destination = "c:/temp/outgoing/"
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
    $SourceResults = @{}
    $Path = $Source + $FileName
    $proccessed = $Destination + "Proccessed"
    # Check if file exists
    if ([System.IO.File]::Exists($Path)){
        # Proccess each record within csv
        ForEach ($row in import-csv $Path){
            # Validate email domans match
            if ($row.emailaddress -match $EmailDomain)
            {
                # Add matching results to Hash table
                $Results.add($row.name,$row.emailaddress)
            } else {
                $SourceResults.add($row.name,$row.emailaddress)
                Write-Host $row.emailaddress "Does not match, moving on..."
            }
        }
        # Export proccessed Result set to timestamped csv
        $Results.GetEnumerator() |
            Select-Object -Property @{N='name';E={$_.Key}},
            @{N='emailaddress';E={$_.Value}} | 
            Export-Csv -UseQuotes AsNeeded -NoTypeInformation -Path $Destination\"users$TimeStamp.csv"
        if (Test-Path -Path $proccessed){
            Move-Item -Path $Source$FileName -Destination $proccessed\"$TimeStamp.csv"
        }
        else {
            New-Item -ItemType directory $Destination\"Proccessed"
        }
        # Send follow up email.
        try {       
            $message = new-object Net.Mail.MailMessage;
            $message.From = $MailSender;
            $message.To.Add($MailReciepient);
            $message.Subject = "Emails have been proccessed";
            $message.Body = $Results.Count + " Emails met criteria and were proccessed `n" + $SourceResults.Count + " Did not meet criteria `n" + "Job Finished:" + $TimeStamp;
        
            $smtp = new-object Net.Mail.SmtpClient($SMTPServer, $Port);
            $smtp.EnableSSL = true;
            $smtp.Credentials = New-Object System.Net.NetworkCredential($EmailUsername, $EmailPassword);
            $smtp.send($message);
        }
        catch {
        }
    # If user.csv is not found continue
    } else {
        Write-Host "Nothing to proccess here..."
    }
}
#Log Errors
catch {
    # You can also use this to error log to a Sql DB or call a webhook with a ticket system to create a bug (ex. Jira, Service Now and etc...)
    Write-Error $_
}
