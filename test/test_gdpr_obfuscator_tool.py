from src.gdpr_obfuscator_tool import gdpr_obfuscator_tool as got
import pytest, os, json, boto3
import pandas as pd
from unittest.mock import patch
from botocore.exceptions import ClientError
from moto import mock_aws
from unittest import mock

BUCKET = 'test-bucket'
FILE_KEY = 'new_data/student_data.csv'
FILE_URI = f's3://{BUCKET}/{FILE_KEY}'


@pytest.fixture(scope='function')
def aws_credentials():
    '''Mocked AWS Credentials for moto.'''
    os.environ['AWS_ACCESS_KEY_ID'] = 'testing'
    os.environ['AWS_SECRET_ACCESS_KEY'] = 'testing'
    os.environ['AWS_SECURITY_TOKEN'] = 'testing'
    os.environ['AWS_SESSION_TOKEN'] = 'testing'
    os.environ['AWS_DEFAULT_REGION'] = 'eu-west-2'


@pytest.fixture(scope='function')
def s3_client(aws_credentials):
    with mock_aws():
        yield boto3.client('s3', 'eu-west-2')


@pytest.fixture(scope='function')
def mocked_aws(aws_credentials):
    '''
    Mock all AWS interactions
    Requires you to create your own boto3 clients
    '''
    with mock_aws():
        yield


@pytest.fixture
def test_dataframe_data():
    df = pd.DataFrame(
        {
            'id': [1, 2, 3],
            'name': ['Jay', 'Iyafe', 'Ada'],
            'email_address': [
                'jay@example.com',
                'iyafe@example.com',
                'ada@example.com',
            ]
        }
    ).set_index('id')
    return df


@pytest.fixture
def create_temp_csv_file(tmp_path, test_dataframe_data):
    temp_file = tmp_path / 'student_data.csv'
    test_dataframe_data.to_csv(temp_file)
    return temp_file


@pytest.fixture(scope='function')
def bucket(s3_client):
    s3_client.create_bucket(
        Bucket=BUCKET, CreateBucketConfiguration={'LocationConstraint': 'eu-west-2'}
    )


@pytest.fixture(scope='function')
def upload_file_to_s3(s3_client, create_temp_csv_file):
    s3_client.upload_file(str(create_temp_csv_file), BUCKET, FILE_KEY)


def test_got_returns_https_status_code_and_correct_csv_file_contents(
    s3_client, bucket, upload_file_to_s3, create_temp_csv_file
):
    event = {'file_to_obfuscate': FILE_URI, 'pii_fields': ['name', 'email_address']}

    with mock.patch('os.remove') as mock_remove:
        response = got(event)

    assert response['HTTPStatusCode'] == 200

    # Check if the file was uploaded to S3
    s3_object = s3_client.get_object(
        Bucket=BUCKET, Key=f'/tmp/obfuscated_student_data.csv'
    )
    obfuscated_data = s3_object['Body'].read().decode('utf-8')

    # Check if the contents of the obfuscated file are correct
    assert '*' in obfuscated_data
    assert 'jay@example.com' not in obfuscated_data
    assert 'iyafe@example.com' not in obfuscated_data


def test_got_raises_client_error_when_file_not_found(
    s3_client, bucket, upload_file_to_s3, create_temp_csv_file
):
    event = {
        'file_to_obfuscate': f's3://{BUCKET}/new_data/nonexistent-file.csv',
        'pii_fields': ['name', 'email_address']
    }

    with pytest.raises(ClientError) as excinfo:
        got(event)

    assert excinfo.value.response['Error']['Code'] == str(404)
    assert '(404)' in str(excinfo.value)
    assert 'HeadObject operation: Not Found' in str(excinfo.value)


def test_invalid_format_raises_value_error():
    event = {
        'file_to_obfuscate': 's3://bucket/new_data/file.exe',
        'pii_fields': ['name']
    }

    with pytest.raises(ValueError, match='====>>> Use format in'):
        got(event)


def test_missing_file_to_obfuscate_key_raises_key_error():
    event = {'pii_fields': ['email']}

    with pytest.raises(KeyError):
        got(event)


def test_invalid_format_raises_attribute_error():
    event = {'file_to_obfuscate': 's3://bucket/file.exe', 'pii_fields': ['name']}

    with pytest.raises(AttributeError):
        got(event)


@patch('pandas.DataFrame.apply')
def test_masking_function_is_called(
    mock_apply, s3_client, bucket, upload_file_to_s3, create_temp_csv_file
):
    
    s3_client.upload_file(str(create_temp_csv_file), BUCKET, FILE_KEY)

    test_input = {
        'file_to_obfuscate': f's3://{BUCKET}/{FILE_KEY}',
        'pii_fields': ['name', 'email_address']
    }

    # Patch read_csv to avoid needing actual file
    with patch(
        'pandas.read_csv',
        return_value=pd.DataFrame(
            [{'id': 1, 'name': 'John', 'email_address': 'john@example.com'}]
        ),
    ) as mock_read:
        
        with mock.patch('os.remove') as mock_remove:
            got(test_input)

        assert (
            mock_apply.called
        ), 'masking_function was not called via DataFrame.apply()'


FILE_KEY_JSON = 'new_data/student_data.json'
FILE_URI_JSON = f's3://{BUCKET}/{FILE_KEY_JSON}'


@pytest.fixture
def create_temp_json_file(tmp_path, test_dataframe_data):
    temp_json_file = tmp_path / 'student_data.csv'
    test_dataframe_data.to_json(temp_json_file)
    return temp_json_file


@pytest.fixture(scope='function')
def upload_json_file_to_s3(s3_client, create_temp_json_file):
    s3_client.upload_file(str(create_temp_json_file), BUCKET, FILE_KEY_JSON)


def test_got_returns_https_status_code_and_correct_json_file_contents(
    s3_client, bucket, upload_json_file_to_s3, create_temp_json_file
):
    event = {
        'file_to_obfuscate': FILE_URI_JSON,
        'pii_fields': ['name', 'email_address']
    }

    with mock.patch('os.remove') as mock_remove:
        response = got(event)

    assert response['HTTPStatusCode'] == 200

    # Check if the file was uploaded to S3
    s3_object = s3_client.get_object(
        Bucket=BUCKET, Key=f'/tmp/obfuscated_student_data.json'
    )
    obfuscated_json_data = s3_object['Body'].read().decode('utf-8')

    # Check if the contents of the obfuscated file are correct
    assert '*' in obfuscated_json_data
    assert 'jay@example.com' not in obfuscated_json_data
    assert 'ada@example.com' not in obfuscated_json_data


def test_got_raises_client_error_when_json_file_not_found(
    s3_client, bucket, upload_json_file_to_s3, create_temp_json_file
):
    event = {
        'file_to_obfuscate': f's3://{BUCKET}/new_data/nonexistent-file.json',
        'pii_fields': ['name', 'email_address']
    }

    with pytest.raises(ClientError) as excinfo:
        got(event)

    assert excinfo.value.response['Error']['Code'] == str(404)
    assert '(404)' in str(excinfo.value)
    assert 'HeadObject operation: Not Found' in str(excinfo.value)


def test_invalid_json_file_format_raises_value_error():
    event = {
        'file_to_obfuscate': 's3://bucket/new_data/file.exe',
        'pii_fields': ['name']
    }

    with pytest.raises(ValueError, match='====>>> Use format in'):
        got(event)


def test_missing_json_file_to_obfuscate_key_raises_key_error():
    event = {'pii_fields': ['email']}

    with pytest.raises(KeyError):
        got(event)


def test_invalid_json_file_format_raises_attribute_error():
    event = {'file_to_obfuscate': 's3://bucket/file.exe', 'pii_fields': ['name']}

    with pytest.raises(AttributeError):
        got(event)