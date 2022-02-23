# Determine if human or scheduled job is running script
if ($args) {
    $FileName = $args[0]
    $EmailDomain = $args[1]
    $RootDIR = $args[2]
    # Email Settings
    $MailSender = $args[3]
    $MailReciepient = $args[4]
    $SMTPServer = $args[5]
    $Port = $args[6]
    $EmailUsername = $args[7]
    $EmailPassword = $args[8]
} else {
    # Ask the user for global vars needed for a manual execution
    $Ask = Read-Host -Prompt 'Would you like to setup a scheduled task? (Y or N)'
    $File = Read-Host -Prompt 'Input the expected file name to be read (ex. users.csv)'
    $DomainMatch = Read-Host -Prompt 'Input the domains you would like matched from the csv (ex. @abc.edu)'
    $Source = $PSScriptRoot + "/"
    $EmailSender = Read-Host -Prompt 'Input the email sender (ex. no-reply@keepitsimply.net)'
    $EmailReciepient = Read-Host -Prompt 'Input the email reciepient (ex. me@shanecotta.com)'
    $EmailServer = Read-Host -Prompt 'Input the email server (ex. email-smtp.us-west-1.amazonaws.com)'
    $EmailPort = Read-Host -Prompt 'Input the email server port (ex. 587)'
    $EmailUser = Read-Host -Prompt 'Input the email Username (ex. AKIAQTI42N62WR53QXKX)'
    $EmailPass = Read-Host -Prompt 'Input the email Password (ex. 1234)'
    if ($Ask -eq "Y"){
        # Create Scheduled Task in task manager and pass prior execution vars
        $ScriptPath = $Source + "CSVProccessor.ps1 " + $File + " " + $DomainMatch  + " " + $Source + " " + $EmailSender + " " + $EmailReciepient + " " + $EmailServer + " " + $EmailPort + " " + $EmailUser + " " + $EmailPass
        $ScheduleTime = Read-Host -Prompt 'Input the time of day you would like the job to run (ex. 9:15 AM)'
        $RunAs = Read-Host -Prompt 'Input the user like the job to run as (ex. DOMAIN\user)'
        $actions = (New-ScheduledTaskAction -Execute $ScriptPath)
        $trigger = New-ScheduledTaskTrigger -Daily -At $ScheduleTime
        $principal = New-ScheduledTaskPrincipal -UserId $RunAs -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -WakeToRun
        $task = New-ScheduledTask -Action $actions -Principal $principal -Trigger $trigger -Settings $settings
        Register-ScheduledTask 'CSVProccessor' -InputObject $task
        # Vars to use for init. execution
        $FileName = $File
        $EmailDomain = $DomainMatch
        $RootDIR = $Source
        # Email Settings
        $MailSender = $EmailSender
        $MailReciepient = $EmailReciepient
        $SMTPServer = $EmailServer
        $Port = $EmailPort
        $EmailUsername = $EmailUser
        $EmailPassword = $EmailPass
    } elseif ($Ask -eq "N") {
            # Vars to use for one time only manual execution
            $FileName = $File
            $EmailDomain = $DomainMatch
            $RootDIR = $Source
            # Email Settings
            $MailSender = $EmailSender
            $MailReciepient = $EmailReciepient
            $SMTPServer = $EmailServer
            $Port = $EmailPort
            $EmailUsername = $EmailUser
            $EmailPassword = $EmailPass
    } else {
        # Scold the user for not following directions :)
        Write-Host "You need to Specify Y or N"
    }
}

##################
# MAIN
##################
try {
    $SourceFolder = "incoming"
    $DestinationFolder = "outgoing"
    $ProccessedFolder = "proccessed"
    $TimeStamp = Get-Date -Format "yyyyMMddHHmmss"
    $Results = @{}
    $Delta = @{}
    $Path = $RootDIR + $SourceFolder + "/" + $FileName
    Write-Host $Path
    $LogFile = $RootDIR + "log.txt"
    # Check if Directory Structure(s) and log file exists, if not create and start logging
    if ([System.IO.File]::Exists($LogFile)){
    } else{
        New-Item -ItemType "file" -Path $LogFile
        Add-Content -Path $LogFile -Value "TIMESTAMP,STATUS,MESSAGE"
        $MSG = "$TimeStamp,WARN,Logfile missing: created " + $LogFile
        Write-Host $MSG
        Add-Content -Path $LogFile -Value $MSG
    }
    if (Test-Path -Path $RootDIR\$SourceFolder){
    } else {
        New-Item -ItemType directory $RootDIR\$SourceFolder
        $MSG = "$TimeStamp,WARN,Source DIR missing: created " + $RootDIR + $SourceFolder
        Write-Host $MSG
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
        Write-Host $MSG
        Add-Content -Path $LogFile -Value $MSG
    }
    # Check if dropped source file exists
    if ([System.IO.File]::Exists($Path)){
        # Proccess each record within csv
        ForEach ($row in import-csv $Path){
            # Validate email domans match
            if ($row.emailaddress -match $EmailDomain)
            {
                # Add matching results to Hash table
                $Results.add($row.emailaddress,$row.name)
                $MSG = "$TimeStamp,INFO,Added " + $row.emailaddress
                Write-Host $MSG
                Add-Content -Path $LogFile -Value $MSG
            } else {
                # Add Deltas to the delta hash table
                $Delta.add($row.emailaddress,$row.name)
                $MSG = "$TimeStamp,WARN," + $row.emailaddress + " Does not match domain"
                Write-Host $MSG
                Add-Content -Path $LogFile -Value $MSG
            }
        }
        # Export proccessed Result set to timestamped csv
        $Results.GetEnumerator() |
            Select-Object -Property @{N='name';E={$_.Value}},
            @{N='emailaddress';E={$_.Key}} | 
            Export-Csv -NoTypeInformation -Path $RootDIR\$DestinationFolder\"users$TimeStamp.csv"
            ##UNCOMMENT ME
            Move-Item -Path $RootDIR\$SourceFolder\$FileName -Destination $RootDIR\$ProccessedFolder\"$TimeStamp.csv"
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
            Write-Host $MSG
            Add-Content -Path $LogFile -Value $MSG
        }
    # If user.csv is not found continue
    } else {
        $MSG = "$TimeStamp,INFO,The file $Path was not found to proccess"
        Write-Host $MSG
        Add-Content -Path $LogFile -Value $MSG
    }
}
#Log Errors
catch {
    $MSG = "$TimeStamp,ERROR," + $_.Exception.Message
    Write-Host $MSG
    Add-Content -Path $LogFile -Value $MSG
}
