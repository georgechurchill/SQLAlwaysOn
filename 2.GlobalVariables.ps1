# Copyright (c) 2019. Amazon Web Services UK LTD. All Rights Reserved.
# AWS Microsoft Solution Architecture Team
#
# Name	     		: SQL AlwaysOn
# Version    		: 1.0.0
# Encoded    		: No
# Paramaters   		: None
# Platform   		: Windows
# Associated Files	: .\App.Config.ps1xml
# Abstract   		: Read XML Config Document, store results into Global Variables
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

cls
write-Host "Setting up Environment Varibles..."

$currentDirectory = get-location
$currentDirectory = $currentDirectory.Path
$ParamaterPath = $currentDirectory + "\App.Config.ps1xml"

try
{
    [xml]$xmldocument = get-content -Path $ParamaterPath -ErrorAction Stop
}
Catch [System.IO.DirectoryNotFoundException],[System.IO.FileNotFoundException], [System.Management.Automation.ItemNotFoundException]
{
    #write-host $error[0].exception.gettype().fullname
    Write-Host "Unable to find Paramater File " $ParamaterPath ".Ensure the XML file is in the same directory as the script."
    Exit 1000
}
Catch
{
    Write-Host $PSItem.Exception.Message
    Exit $LastExitCode
}


$global:AWSRegion = $xmldocument.Config.Region.Name
$global:VPCID = $xmldocument.Config.VPC.Name
$global:SQLNode1SubNetID = $xmldocument.Config.VPC.SQLNode1SubNetID
$global:SQLNode2SubNetID = $xmldocument.Config.VPC.SQLNode2SubNetID
$global:SQLWitnessSubNetID = $xmldocument.Config.VPC.SQLWitnessSubNetID


$global:SQLNode1Tag = $xmldocument.Config.Instance[0].Tag
$global:SQLNode1InstanceType = $xmldocument.Config.Instance[0].Type
$global:SQLNode1CPUs = $xmldocument.Config.Instance[0].CPU
$global:SQLNode1SecurityGroups = $xmldocument.Config.Instance[0].SecurityGroups
$global:SQLNode1KeyPair = $xmldocument.Config.Instance[0].KeyPair
$global:SQLNode1AMIID = $xmldocument.Config.Instance[0].AMIID

$global:SQLNode2Tag = $xmldocument.Config.Instance[1].Tag
$global:SQLNode2InstanceType = $xmldocument.Config.Instance[1].Type
$global:SQLNode2CPUs = $xmldocument.Config.Instance[1].CPU
$global:SQLNode2SecurityGroups = $xmldocument.Config.Instance[1].SecurityGroups
$global:SQLNode2KeyPair = $xmldocument.Config.Instance[1].KeyPair
$global:SQLNode2AMIID = $xmldocument.Config.Instance[1].AMIID

$global:SQLAlwaysOnWitnessTag = $xmldocument.Config.Instance[2].Tag
$global:SQLAlwaysOnWitnessType = $xmldocument.Config.Instance[2].Type
$global:SQLAlwaysOnWitnessCPUs = $xmldocument.Config.Instance[2].CPU
$global:SQLAlwaysOnWitnessSecurityGroups = $xmldocument.Config.Instance[2].SecurityGroups
$global:SQLAlwaysOnWitnessKeyPair = $xmldocument.Config.Instance[2].KeyPair
$global:SQLAlwaysOnWitnessAMIID = $xmldocument.Config.Instance[2].AMIID

$global:DomainName = $xmldocument.Config.DomainJoin.Name
$global:KMSARN = $xmldocument.Config.KMSARN.Number
