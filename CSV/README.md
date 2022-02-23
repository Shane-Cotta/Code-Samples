RUNTIME Requirements as tested in sandbox/development: \
Mac OS, Powershell v7.1+
\
\
Enviornments not tested: \
Windows\linux Powershell < v7.1.\

Supported arguments (all are required in the order listed):
1. source file name to be read (ex. users.csv)
2. domain you would like matched from the csv (ex. @abc.edu)
3. the email sender (ex. no-reply@keepitsimply.net)
4. the email reciepient (ex. me@shanecotta.com)
5. the email server (ex. email-smtp.us-west-1.amazonaws.com)
6. the email server port (ex. 587)
7. the email Username (ex. AKIAQTI42N62WR53QXKX)
8. the email Password (ex. 1234)

Windows:
1. Drop into root directory of choice and run script using and elevated powershell windows
2. Follow the prompts and select if you would like to install a scheduled task or run the code once \
      a) If installing as a scheduled task, this will install the scheduled task with the name CSVProccessor.

Linux/Unix:
1. Follow the associated Microsoft documentation to install powershell on linux [Here](https://docs.microsoft.com/en-us/powershell/scripting/install/install-debian?view=powershell-7.2#:~:text=via%20Package%20Repository-,PowerShell%20for%20Linux%20is%20published%20to,for%20easy%20installation%20and%20updates.&text=As%20superuser%2C%20register%20the%20Microsoft,sudo%20apt%2Dget%20install%20powershell%20.)
2. Create the following cron making sure to populate with your scripts root directory 
    a) export VISUAL=nano; crontab -e
3. Add the following subsutiting with your arguments: 0 0 1 * * pwsh -File "/home/user/scripts/examplescript.ps1 $File $DomainMatch $EmailSender $EmailReciepient $EmailServer $EmailPort $EmailUser $EmailPass"
    
NOTE: Verify you run the script as admin/service account with proper directory permissions.

The code will create the below folder structure/files within the scripts root directory.:\
Root \
--> incoming \
----> (users.csv) \
--> outgoing \
----> (usersyyyyMMddHHmmss.csv) \
--> proccessed \
----> Proccessed source file (yyyyMMddHHmmss.csv) \
--> log.txt \

NOTE: Your email provider may require you to generate an app specific key for the auth to work. (gmail, yahoo and etc..) included is an aws SES account in the launchers examples, please DM for a password to the SMTP sandbox.
