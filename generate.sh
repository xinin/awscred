
#!/bin/bash

#################### Replace ####################
account=''
user=''
credentials_file=''

#################### Dont Touch ####################
read -p "Enter MFA code for "${user}": " mfa

echo "Generating Session Token ..."
sts_temp=`aws sts get-session-token --duration-seconds 3600 --serial-number 'arn:aws:iam::'${account}':mfa/'${user} --token-code ${mfa} --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]'`

export AWS_ACCESS_KEY_ID=$(echo ${sts_temp}|awk -F \" '{printf $2}')
export AWS_SECRET_ACCESS_KEY=$(echo ${sts_temp}|awk -F \" '{printf $4}')
export AWS_SESSION_TOKEN=$(echo ${sts_temp}|awk -F \" '{printf $6}')

echo "Getting old Access Key ..."
old_access_key_id=`aws iam list-access-keys --user-name ${user} --query 'AccessKeyMetadata[0].AccessKeyId'`

echo "Creating new Access Key ..."
access_key=`aws iam create-access-key --user-name ${user} --query 'AccessKey.[AccessKeyId,SecretAccessKey]'`

new_acess_key_id=$(echo ${access_key}|awk -F \" '{printf $2}')
new_secret_access_key=$(echo ${access_key}|awk -F \" '{printf $4}')

echo "Replacing Access Key in "${credentials_file}" ..."
sed -ie '2s/.*/aws_access_key_id = '${new_acess_key_id}'/' ${credentials_file}
sed -ie '3s/.*/aws_secret_access_key = '${new_secret_access_key}'/' ${credentials_file}

echo "Removing old Access Key ..."
aws iam delete-access-key --user-name ${user} --access-key-id ${old_access_key_id//\"}

echo "Cleaning Session Token ..."
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

echo "Done 🦄"