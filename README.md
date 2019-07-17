# Copyright (c) 2019. Amazon Web Services UK LTD. All Rights Reserved.
# AWS Microsoft Solution Architecture Team
#
# Name	     		  : SQL AlwaysOn
# Version    		  : 1.0.0
# Encoded    		  : No
# Paramaters   	  : None
# Platform   		  : Windows
# Associated Files: None
# Abstract   		  : ReadMe Document
# 
# Revision History	: - 1.0.0 | 17/07/2019 Initial Version
#	     
# Author            : George Churchill


##################### Automation SQL Deployment.##########################################################################

# YOU ACKNOWLEDGE AND AGREE THAT THE SCRIPT IS PROVIDED FREE OF CHARGE "AS IS" AND "AVAILABLE" BASIS, AND THAT YOUR 
# USE OF RELIANCE UPON THE APPLICATION OR ANY THIRD PARTY CONTENT AND SERVICES ACCESSED THEREBY IS AT YOUR SOLE RISK AND 
# DISCRETION. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

##########################################################################################################################

The following scripts launch a two node SQL Windows Cluster and a File Share witness onto EC2 instances. The instances need to be deployed into a pre-configured VPC and Subnets Configuration for the SQL nodes is found in the App.Config.ps1xml file. Adjust the parameters in this file to customise the environment.
Any AWS resources created by this script will be charged at the Standard Rates. Google AWS Simple Monthly Calculator to find regional costs.

Pre-Requisites for the Script.
1.	AWS Account, VPC and Subnets. It is recommended to deploy all EC2 instances into different availability zones for high availability.
2.	AWS Permissions: Create AWS Roles, Create Policies, Attach Roles to EC2 Instances, Create SSM Parameters, Create SSM Documents, Execute SSM Run Command, Create EC2 instances, 		Create Security Groups, user account with permissions to Domain Join EC2 Instances to an Active Directory
3.	PowerShell (Latest Version) installed
4.	AWS CLI (Latest Version) installed
5.	.Net Framework 4.7 Installed
6.	AWS Profile Configured
7. 	AWS KMS ARN used to decrypt DomainJoinPassword SSM Paramater
8.	Microsoft Active Directory that is reachable by the EC2 instances
9.	AWS Key Pair
10. 	Amazon Machine Image with Windows installed (script used default Amazon Windows Server 2019 Image, but this can be ammended if required)


Context
The Script runs through some basic checks such as checking for a supported version of Windows PowerShell and AWS CLI. Then the script checks SSM Paramaters that are required for Domain Joining a Windows EC2 instance to the Domain specificed in the App.Config.ps1xml file. The Paramater Store Paramaters are:
•	DomainName (from App.Config.ps1xml)
•	DomainJoinUserName (one time user prompt)
•	DomainJoinPassword (one time user promot)

If the above parameters do not exist, the user will be promoted to enter the username and password at runtime. The credentials are passed to AWS parameters store and stored using the names above. The DomainJoinPassword is stored as a secure string and can only be decrypted using the kms key specified in the App.Config.ps1xml
Note that when SSM runs, it does not run with any domain suffix attached to the user paramater. Therefore you must add a domain name to the user name in the form of user@userdomain.com when providing the username

The script checks for an AWS Systems Manager Document that is run on the EC2 instances using SSM Run Command. The Document is called JoinInstanceToDomain. If this document is not found, a new document is created. The document calls the System Manager Parameters at run time and joins the EC2 instances to the Domain specified in the App.Config.ps1xml file.

Once the Pre-Requisite Checks have been found the script launches three EC2 instances using the configuration stored in App.Config.ps1xml.  Take note of the CPU Parameters, as the default values constrain the number of CPUs launched to reduce SQL licence requirements.

Once the EC2 instances are Launched Successfully, a new role called AmazonEC2SSMRoleforalwayson is created. The Role has Policies attached to it that allow the EC2 instance to be managed by AWS SSM and to decrypt the Domain Join Password. The Role is attached to each of the EC2 instances. The script then waits for 5 min to allow the systems to communicate with SSM. Once the EC2 Instances become “Managed Instances” SSM runs the JoinInstanceToDomain Document to join the Systems to the Domain.

App.Config.ps1xml Information:

Region Name 		: Region to Launch EC2 Instances
KMSARN			: AWS KMS Key used to decrypt SSM Parameters
VPC Name		: VPC ID of the VPC to Launch the SQL Servers into
SQLNode1SubNetID	: Subnet ID that SQL Node 1 will be launched into. This Subnet must exist
SQLNode2SubNetID	: Subnet ID that SQL Node 2 will be launched into. This Subnet must exist
SQLWitnessSubNetID	: Subnet ID that the File Share witness will be launched into. This Subnet must exist
Type			: Amazon EC2 Type
CPU			: Number of CPU's to Launch the instance with
KeyPair			: Key Pair used to decrypt the local admin password
Tag			: Tag used on the EC2 instance
SecurityGroups		: Not working at present
AMIID			: Amazon Machine Image ID Used to Launch the Windows Instance
DomainJoin		: Name of the Domain to Join the machine to.

