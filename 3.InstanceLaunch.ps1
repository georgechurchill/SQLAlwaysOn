# Copyright (c) 2019. Amazon Web Services UK LTD. All Rights Reserved.
# AWS Microsoft Solution Architecture Team
#
# Name	     		: SQL AlwaysOn
# Version    		: 1.0.0
# Encoded    		: No
# Paramaters   		: None
# Platform   		: Windows
# Associated Files	: .\App.Config.ps1xml
# Abstract   		: Launch 3 x EC2 instances using paramaters in .\App.Config.ps1xml
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

#Launch SQL Node & 2
$SQLNode1CPUs = "CoreCount="+$SQLNode1CPUs+",ThreadsPerCore=1"
$SQLNode2CPUs = "CoreCount="+$SQLNode2CPUs+",ThreadsPerCore=1"
$SQLNode1Tag = "ResourceType=instance,Tags=[{Key=Name,Value=" + $SQLNode1Tag + "}]"
$SQLNode2Tag = "ResourceType=instance,Tags=[{Key=Name,Value=" + $SQLNode2Tag + "}]"
$SQLWitnessTag = "ResourceType=instance,Tags=[{Key=Name,Value=" + $SQLAlwaysOnWitnessTag + "}]"
write-host "Launching SQL Cluster"

$SQLNode1 = aws ec2 run-instances --image-id $SQLNode1AMIID --instance-type $SQLNode1InstanceType --cpu-options $SQLNode1CPUs --key-name $SQLNode1KeyPair --subnet-id $SQLNode1SubNetID   --tag-specifications $SQLNode1Tag --associate-public-ip-address  # --security-groups $securitygroups
$SQLNode2 = aws ec2 run-instances --image-id $SQLNode2AMIID --instance-type $SQLNode2InstanceType --cpu-options $SQLNode2CPUs --key-name $SQLNode2KeyPair --subnet-id $SQLNode2SubNetID   --tag-specifications $SQLNode2Tag --associate-public-ip-address # --security-groups $securitygroups
$SQLWitness = aws ec2 run-instances --image-id $SQLAlwaysOnWitnessAMIID   --instance-type $SQLAlwaysOnWitnessType  --key-name $SQLAlwaysOnWitnessKeyPair --subnet-id $SQLWitnessSubNetID --tag-specifications $SQLWitnessTag --associate-public-ip-address # --security-groups $securitygroups

function GetInstanceID {param($LaunchOutput)
    #Get the Instance ID from the new instance
    $InstanceId = $LaunchOutput.Item(6) # Item 6 in the JSON output
    $separator = ": " # Split the strinfg on the seperator
    $option = [System.StringSplitOptions]::RemoveEmptyEntries
    $InstanceId = $InstanceID.split($separator,3,$option)
    $instanceId =  $InstanceID[1] 
    $instanceId = $InstanceId.Replace('",',"")
    $instanceId = $InstanceId.Replace('"',"")
    #write-host "The Instance ID is: "$InstanceId
    return $instanceId
}
$global:SQLNode1InstanceID = GetInstanceID($SQLNode1)
$global:SQLNode2InstanceID = GetInstanceID($SQLNode2)
$global:SQLWitnessID = GetInstanceID($SQLWitness)

write-host "SQLNode1                       : " $SQLNode1InstanceID
write-host "SQLNode2                       : " $SQLNode2InstanceID
write-host "SQLWitness                     : " $SQLWitnessID
write-host "Waiting for EC2 instances to become Running..."

$instancestate = (Get-EC2Instance $SQLWitnessID).Instances.State.Name

Do 
{
    start-sleep -Seconds 30
    Write-Host "Instance State: " $instancestate
    $instancestate = (Get-EC2Instance $SQLWitnessID).Instances.State.Name
}
while($instancestate  -ne "running")
start-sleep -Seconds 30 # provide some buffer
write-host "Instance State " $instancestate



