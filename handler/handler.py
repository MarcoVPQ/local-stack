import json

def handler(event, context):
    print(f'The file {event["Records"][0]["s3"]["object"]["key"]} has been uploaded.')


    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Event received"})
    }