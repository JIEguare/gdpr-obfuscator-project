import pandas as pd
import re, os, json, csv
import boto3
from botocore.exceptions import ClientError

'''
GDPR Obfuscator Tool

This module provides functionality to obfuscate Personally Identifiable Information (PII)
in CSV and JSON files stored in Amazon S3. It supports file download from S3, masking of
sensitive fields, and uploading the obfuscated result back to S3.

Use Cases:
- If the input is a Python dictionary, the module can operate directly.
- If the input is a JSON string, it must be deserialized using json.loads() before being passed in.
'''



def gdpr_obfuscator_tool(file_info):
    '''
    Obfuscates PII fields in a given file stored in an S3 bucket.

    Parameters:
    -----------
    file_info : dict
        A dictionary with the following keys:
            - file_to_obfuscate: str
                S3 URI of the file to be obfuscated, e.g., "s3://bucket/key/to/file.csv"
            - pii_fields: list
                List of field names (columns) to mask in the file.

    Returns:
    --------
    dict
        AWS S3 response metadata after uploading the obfuscated file.

    Raises:
    -------
    ValueError:
        If the file format is unsupported or the S3 path is invalid.
    ClientError:
        If there is an issue accessing S3 (download or upload).
    '''

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
    try:
        if file_format in file_extension:
            client.download_file(bucket, key, temp_input_path)
            print(f'=====>>> File downloaded from {bucket} successfully....')
    except ClientError as c:
        print(c.response)
        raise c
    except Exception as e:
        print(f'wrong input parameters {e}')

    fields_to_obfuscate = file_info['pii_fields']
    if file_format == 'csv':
        df = pd.read_csv(temp_input_path, index_col=0)
    elif file_format == 'json':
        df = pd.read_json(temp_input_path)
    else:
        raise ValueError(f'====>>> Use format in {file_extension}!!!')

    def masking_function(row):
        '''
        Masks the content of the specified PII fields by replacing each character with '*'.
        df.apply() is used to apply this function to each row element-wise in the DataFrame.
        '''
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
        raise ValueError(f'====>>> Use format in {file_extension}!!!!')

    try:
        with open(f'{temp_output_path}', 'rb') as file_data:
            upload_response = client.put_object(
                Body=file_data, Bucket=bucket, Key=f'{temp_output_path}'
            )
        print(f'=====>>> File uploaded to {bucket} sucessfully....')
    except ClientError as c:
        print(c.response)
        raise c
    except Exception as e:
        print(f'wrong input parameters {e}')
    os.remove(temp_input_path)
    os.remove(temp_output_path)

    return upload_response['ResponseMetadata']


def lambda_handler(event, context):
    '''
    AWS Lambda handler function for the GDPR obfuscation tool.

    Parameters:
    -----------
    event : dict
        Contains the input parameters as required by gdpr_obfuscator_tool().
    context : object
        AWS Lambda context object (unused).

    Returns:
    --------
    dict
        S3 response metadata from the upload operation.
    '''
    return gdpr_obfuscator_tool(event)