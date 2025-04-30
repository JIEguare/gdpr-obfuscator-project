import pandas as pd
import re, os, json, csv
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
   
    if object_filepath is None:
        raise ValueError(f'====>>> Use format in {file_extension}!!!')
    if object_filepath.group(4) not in file_extension:
        raise ValueError(f'====>>> Use format in {file_extension}!!!')
    
    temp_input_path = f'/tmp/{file_object}'
    temp_output_path = f'/tmp/obfuscated_{file_object}'
    
    client = boto3.client('s3')
    if file_format in file_extension:
        client.download_file(bucket, key, temp_input_path)
        print(f'=====>>> File downloaded from {bucket} successfully....')
    
    fields_to_obfuscate = file_info['pii_fields']
    if file_format == 'csv':
        df = pd.read_csv(temp_input_path, index_col=0)
    elif file_format == 'json':
        df = pd.read_json(temp_input_path)
    else:
        raise ValueError(f'====>>> Use format in {file_extension}!!!')
    
    def masking_function(row):
        for field in fields_to_obfuscate:
            if row[f'{field}'] == None:
                return row
            else:
                row[f'{field}'] = len(str(row[f'{field}'])) * '*'
        return row

    new_df = df.apply(masking_function, axis=1)
    if file_format == 'csv':
        new_df.to_csv(f'{temp_output_path}', index=False)
        print('=====>>> File obfuscated and copied successfully....')
    elif file_format == 'json':
        new_df.to_json(f'{temp_output_path}', orient='records')
    else:
        print(f'====>>> Use format in {file_extension}!!!!')
    
    with open(f'{temp_output_path}', 'rb') as file_data:
        upload_response = client.put_object(Body=file_data,
                                 Bucket=bucket,
                                 Key=f'{temp_output_path}'
                                 )
    print(f'=====>>> File uploaded to {bucket} sucessfully....')
    os.remove(temp_input_path)
    os.remove(temp_output_path)
    
    return upload_response['ResponseMetadata']

def lambda_handler(event, context):
    return gdpr_obfuscator_tool(event)

