Edit the Global configs to match your use case. Ensure you run the script as admin/service account with proper directory permissions.

The code will create a proccessed folder in the scripts root directory to move successfully and unsuccessfully proccessed files so they dont get picked up with the next scheduled task.

NOTE: Your email provider may require you to generate an app specific key for the authintication email piece to work. (gmail, yahoo and etc..)

Next Release:
1. Add SQL DB Logging for success and error reporting
2. Better Error handling for dealing with multiple csv drops.
3. Build an Invoke-Rest function to allow API calls to be made to webhook services creating tickets in issue tracking software.
