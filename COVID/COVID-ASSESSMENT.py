import json
import os
import boto3
from datetime import datetime
import pytz
from pytz import timezone
from io import StringIO
from pysftp import Connection, CnOpts

def lambda_handler(event, context):
    
    # Declare global Vars
    date_format='%m/%d/%Y'
    date = datetime.now(tz=pytz.utc)
    date = date.astimezone(timezone('US/Pacific'))
    currentdate = date.strftime(date_format)
    
    # Declare responses
    NotSickResponse = {
        "statusCode": 200,
        "headers": {},
        "body": json.dumps({
            "message": "Thank you! If at any time during your shift you begin to experience any of these symptoms, notify your supervisor immediately to discuss if you should remain at work."
        })
    }
    
    SickResponse = {
        "statusCode": 200,
        #"headers": {},
        "body": json.dumps({
            "message": "Looks like you are sick and should stay home, please contact your supervisor."
        })
    }
    
    ErrorResponse = {
        "statusCode": 200,
        "headers": {},
        "body": json.dumps({
            "message": "Looks like there was a problem collecting your info, please try again later, if the issue persists contact the Help Desk."
        })
    }
    
    IncorrectEmployeeID = {
        "statusCode": 200,
        "headers": {},
        "body": json.dumps({
            "message": "Looks like your employee ID might be incorrect, please verify and try again."
        })
    }
    
    AlreadySubmitted = {
        "statusCode": 200,
        "headers": {},
        "body": json.dumps({
            "message": "You have already submitted for the day, please try again tomorrow."
        })
    }
    
    ################################
    # MAIN
    ################################
    # Validate Employee ID
    try:
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table('existingEmployee')
        response = table.get_item(
            Key={
                'empid': int(event['empid'])
            }
        )
        item = response['Item']
        print(item)
        print("INFO: Validated Employee ID "+ event['empid'])
    except Exception as e:
        print('WARN: Employee ID '+ event['empid'] +' does not exist in DynamoDB', e)
        return IncorrectEmployeeID
        exit(0)
    # Validate If already submitted for the day
    try:
        dynamodb = boto3.resource('dynamodb')
        table = dynamodb.Table('covid_checklist')
        response = table.get_item(
            Key={
                'empid': int(event['empid']),
                'submitted_date': currentdate
            }
        )
        item = response['Item']
        print(item)
        print("INFO: "+ event['empid'] + " has already submitted on " + currentdate)
        return AlreadySubmitted
        exit(0)
    except:
        print("INFO: "+ event['empid'] + " has not submitted on " + currentdate)
    # Record Submition if validations check out
    try:
        # Declare DB VARS
        table = dynamodb.Table('covid_checklist')
        # Symptom Check Fail
        if "0" in [event["major_symptoms"], event["other_symptoms"], event["feel_ill"]]:
            try:
                table.put_item(
                   Item={
                        'empid': int(event['empid']),
                        'major_symptoms': event["major_symptoms"],
                        'other_symptoms': event["other_symptoms"],
                        'feel_ill': event["feel_ill"],
                        'submitted_date': currentdate,
                    }
                )
                
                cnopts = CnOpts()
                cnopts.hostkeys = None
                with Connection('********'
                                ,username= '********'
                                ,password = '********'
                                ,cnopts=cnopts
                                ) as sftp:
                    with sftp.cd('COVID_Checklist'):
                        f = sftp.open('COVID_Checklist.txt', 'ab')
                        data=event['empid'] + '|' + event["major_symptoms"] + '|' + event["other_symptoms"] + '|' + event["feel_ill"] + '|' + currentdate
                        f.write(data+'\n')
            except Exception as e:
                print("ERROR: at Symptom Check Fail", e)
                return ErrorResponse
                exit(1)
            else:
                return SickResponse
    except Exception as e:
        print("ERROR: at Establishing Dynamo DB", e)
        return ErrorResponse
        exit(1)
    else:
        # Insert Not Sick Response
        try:
            table.put_item(
               Item={
                    'empid': int(event['empid']),
                    'major_symptoms': event["major_symptoms"],
                    'other_symptoms': event["other_symptoms"],
                    'feel_ill': event["feel_ill"],
                    'submitted_date': currentdate,
                }
            )
            cnopts = CnOpts()
            cnopts.hostkeys = None
            with Connection('********'
                            ,username= '********'
                            ,password = '********'
                            ,cnopts=cnopts
                            ) as sftp:
                with sftp.cd('COVID_Checklist'):
                    f = sftp.open('COVID_Checklist.txt', 'ab')
                    data=event['empid'] + '|' + event["major_symptoms"] + '|' + event["other_symptoms"] + '|' + event["feel_ill"] + '|' + currentdate
                    f.write(data+'\n')
        except Exception as e:
            print("ERROR: at inserting new entry:", e)
            return ErrorResponse
            exit(1)
        else:
            return NotSickResponse
            exit(0)
