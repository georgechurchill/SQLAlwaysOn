write-Host "Configuring SSM"
$iamrole = "AmazonEC2SSMRoleforalwayson" 
$iam_doco = '{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Sid":"",
         "Effect":"Allow",
         "Principal":{
            "Service":[
               "ec2.amazonaws.com",
               "ssm.amazonaws.com"
            ]
         },
         "Action":"sts:AssumeRole"
      }
   ]
}'



$kmsPolicy ='{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action":[
            "kms:Decrypt"
         ],
         "Resource":[
            "arn:aws:kms:xxxxxxxxxx"
         ]
      }
   ]
}'

$kmsPolicy = $kmsPolicy -replace "arn:aws:kms:xxxxxxxxxx", $KMSARN # Take the App.Config.ps1xml paramater




try{Get-IAMRole-RoleName AmazonEC2SSMRoleforalwayson}
Catch
{
    New-IAMRole -RoleName $iamrole -Description "AmazonEC2SSMRoleforalwayson" -AssumeRolePolicyDocument $iam_doco

}

$iamprofilerolename = "AmazonEC2SSMRoleforalwayson"

try{Get-IAMInstanceProfile -InstanceProfileName $iamprofilerolename}
Catch{$iaminstanceprofile = New-IAMInstanceProfile -InstanceProfileName $iamprofilerolename}

try{$kmspolicy = New-IAMPolicy -PolicyName kmsdecrypt -PolicyDocument $kmsPolicy}
Catch{write-host "KMSPolicy Already Exists, skipping"}

write-host "Attaching Policies to Role AmazonEC2SSMRoleforalwayson (AmazonEC2RoleforSSM, AmazonSSMManagedInstanceCore & kmsdecrypt)"

try{
        Register-IAMRolePolicy -RoleName $iamrole -PolicyArn arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM -PassThru
        Register-IAMRolePolicy -RoleName $iamrole -PolicyArn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
        Register-IAMRolePolicy -RoleName $iamrole -PolicyArn $kmsPolicy.Arn
}
Catch{write-Warning "Unable to attach policies to AmazonEC2SSMRoleforalwayson, check permissions"}


Add-IAMRoleToInstanceProfile -RoleName $iamrole -InstanceProfileName $iamprofilerolename -PassThru
Write-Host "Attaching EC2 Systems Manager Role to Instances"
start-sleep -Seconds 60 # Allow role to propogate

aws ec2 associate-iam-instance-profile --instance-id $SQLNode1InstanceID --iam-instance-profile Name="AmazonEC2SSMRoleforalwayson"
aws ec2 associate-iam-instance-profile --instance-id $SQLNode2InstanceID --iam-instance-profile Name="AmazonEC2SSMRoleforalwayson"
aws ec2 associate-iam-instance-profile --instance-id $SQLWitnessID --iam-instance-profile Name="AmazonEC2SSMRoleforalwayson"

write-host "Joining EC2 instances to Domain using SSM Run Document JoinInstanceToDomain with SSM Paramaters domainName, domainJoinUserName & domainJoinPassword"

# to do Run checks to make sure the instances is a EC2 Systems Managed Managed Instance as this takes a bit of time.
start-sleep -Seconds 300

send-SSMCommand -InstanceId $SQLNode1InstanceID -DocumentName JoinInstanceToDomain -DocumentVersion $LATEST -TimeoutSecond 300
send-SSMCommand -InstanceId $SQLNode2InstanceID -DocumentName JoinInstanceToDomain -DocumentVersion $LATEST -TimeoutSecond 300
send-SSMCommand -InstanceId $SQLWitnessID -DocumentName JoinInstanceToDomain -DocumentVersion $LATEST -TimeoutSecond 300

