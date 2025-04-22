import pandas as pd
import re, datetime
import boto3

'''If the GOT function argument passed in is a python dictionary, use module designed.
   However, if the argument is a JSON string, implement the json.loads() function
   in the module to deserialise the JSON string.'''

def gdpr_obfuscator_tool(file_info):
    
    file_extension = ['csv', 'json']
    regex_pattern = re.compile(r'^s3://([^/]+)/(.+/([^/]+\.([a-z]+)))')
    object_filepath = re.fullmatch(regex_pattern, file_info['file_to_obfuscate'])
    bucket = object_filepath.group(1)
    key = object_filepath.group(2)
    file_object = object_filepath.group(3)
    file_format = object_filepath.group(4)
    client = boto3.client('s3')
    
    if file_format in file_extension:
        response = client.get_object(Bucket=bucket, Key=key)
        with open(f'{file_object}', 'wb') as file:
            file.write(response['Body'].read())
        print(f'=====>>> File downloaded from {bucket} successfully....')
    
    fields_to_obfuscate = file_info['pii_fields']
    if file_format == 'csv':
        df = pd.read_csv(file_object, index_col=0)
    elif file_format == 'json':
        df = pd.read_json(file_object)
    else:
        print(f'====>>> Use format in {file_extension}!!!')
    
    def masking_function(row):
        for field in fields_to_obfuscate:
            if row[f'{field}'] == None:
                return row
            else:
                row[f'{field}'] = len(str(row[f'{field}'])) * '*'
        return row

    new_df = df.apply(masking_function, axis=1)
    if file_format == 'csv':
        new_df.to_csv(f'obfuscated_{file_object}', index=False)
        print('=====>>> File obfuscated and copied successfully....')
    elif file_format == 'json':
        new_df.to_json(f'obfuscated_{file_object}', orient='records')
    else:
        print(f'====>>> Use format in {file_extension}!!!!')
    
    with open(f'obfuscated_{file_object}', 'rb') as file_data:
        upload_response = client.put_object(Body=file_data,
                                 Bucket=bucket,
                                 Key=f'obfuscated_data/{file_object}'
                                 )
    print(f'=====>>> File uploaded to {bucket} sucessfully....')
    return upload_response['ResponseMetadata']


my_data = {
"file_to_obfuscate": "s3://personally-identifiable-info-bucket-20250422140329610600000001/new_data/student_data.csv",
"pii_fields": ["name", "email_address"]
}

print(gdpr_obfuscator_tool(my_data))