# Copyright (c) 2019. Amazon Web Services UK LTD. All Rights Reserved.
# AWS Microsoft Solution Architecture Team
#
# Name	     		: SQL AlwaysOn
# Version    		: 1.0.0
# Encoded    		: No
# Paramaters   		: None
# Platform   		: Windows
# Associated Files	: .\App.Config.ps1xml
# Abstract   		: Check for required Pre-Requisists such as Powershell Tools
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

# Checks Performed:
# 1.Check AWS PowerShell is installed, if missing download and install
# 2.Check that AWS CLI (aws.exe.) exists on the machine
# 3.Check AWS CLI is version 3.x or higher
# 4.Check AWS Default Region
# 5.Attempt to call an AWS API to check connectivcity and credentials

# Exit Codes
# 0        : Success
# 500      : AWS CLI not installed
# 1000     : AWS Paramater Store Paramaters domainName,domainJoinUserName or domainJoinPassword not found
# 2000     : Systems Managed JoinInstanceToDomain not found

cls
write-Host "Checking Environmental Requirments..."

$currentDirectory = get-location
$currentDirectory = $currentDirectory.Path
$ParamaterPath = $currentDirectory + "\App.Config.ps1xml"

try
{
    [xml]$xmldocument = get-content -Path $ParamaterPath -ErrorAction Stop
}
Catch [System.IO.DirectoryNotFoundException],[System.IO.FileNotFoundException], [System.Management.Automation.ItemNotFoundException]
{
    Write-Host "Unable to find Paramater File " $ParamaterPath ".Ensure the XML file is in the same directory as the script."
    Exit 1000
}
Catch
{
    Write-Host $PSItem.Exception.Message
    Exit $LastExitCode
}


$AWSRegion = $xmldocument.Config.Region.Name



################################ Powershell Check ########################################################################
# Check to see if AWS Powershell Tools are installed
##########################################################################################################################

try {
    $AWSModule = Get-AWSPowerShellVersion
}
catch {
    try {
        Write-Host "[+] Trying to import the AWS PowerShell module"
        Import-Module "AWSPowerShell"
        $testAWSModule = Get-AWSPowerShellVersion
    }
    catch {
        Write-Host "The AWS's PowerShell module is not available on your machine - the tool can install it for you:" -ForegroundColor Yellow
        $PowerShellVersion = $PSVersionTable.PSVersion.Major
        if ($PowerShellVersion -ge 5) {
            Write-Host "Installing AWSPowerShell module for the current user..."
            Install-Module AWSPowerShell -Scope CurrentUser -Force
            Import-Module "AWSPowerShell"
        }
        else {
            Write-Warning "You use PowerShell version $testAWSModule. PS could not automatically install the AWS module. Consider upgrade to PS version 5+ or download AWSPowerShell module from the officןal site:"
            Write-Warning "https://aws.amazon.com/powershell/"
            Return
        }
    }
    try {
        $testAWSModule = Get-AWSPowerShellVersion
        if ($testAWSModule) {
            Write-Host "[+] Good, AWS PowerShell module was loaded successfully"
        }
    }
    catch {
        Write-Host "Encountered an error with AWS's PowerShell module - please make sure it's indeed installed on your machine - and try again." -ForegroundColor red
        Write-Host "Check the official download page:`n    https://aws.amazon.com/powershell/`nOr use the direct download link:`n    http://sdk-for-net.amazonwebservices.com/latest/AWSToolsAndSDKForNet.msi" -ForegroundColor Yellow
        Return
    }
}

write-host "1. AWS Powershell Check   : Passed"

################################    CLI Check     ########################################################################
# Check to see if the Correct Version of the AWS CLI is installed
##########################################################################################################################

$AWSCLIInstalled = Test-Path -Path "C:\Program Files\Amazon\AWSCLI\bin\aws.exe"
If ($AWSCLIInstalled -eq "True")
{
    $CLIVersion = Get-WmiObject Win32_Product -Filter "Name like 'AWS Tools for Windows'" | Select-Object -ExpandProperty Version
    if ($CLIVersion -lt 3)
    {
        write-warning "AWS CLI below minimum Version" 
        $input = Read-Host "Download and Install AWS CLI Now?"
        if($input -eq "y" -or $input -eq "yes")
        {
            $url = "https://s3.amazonaws.com/aws-cli/AWSCLI64PY3.msi"
            $currentDirectory = get-location
            $currentDirectory = $currentDirectory.Path
            $output = "$currentDirectory\AWSCLI64PY3.msi"
            Invoke-WebRequest -Uri $url -OutFile $output
            $Args = "/I " + $output + " /qb" 
            Start-Process msiexec.exe -Wait -ArgumentList $Arg
        }
        Else 
        {
            Write-Warning "AWS CLI Check: Failed, install AWS CLI from here https://docs.aws.amazon.com/cli/latest/userguide/install-windows.html" 
            Read-Host -prompt "Press any key to quit"
            Exit 500
        }

    }
    write-host "2. AWS CLI Check          : Passed"
    write-host "3. AWS CLI Verison        :"$CLIVersion
    }
Else 
{
    write-warning "AWS CLI is not installed." 
    $input = Read-Host "Download and Install AWS CLI Now?"
    if($input -eq "y" -or $input -eq "yes")
    {
        $url = "https://s3.amazonaws.com/aws-cli/AWSCLI64PY3.msi"
        $currentDirectory = get-location
        $currentDirectory = $currentDirectory.Path
        $output = "$currentDirectory\AWSCLI64PY3.msi"
        Invoke-WebRequest -Uri $url -OutFile $output
        $Args = "/I " + $output + " /qb" 
        write-host $Args
        Start-Process msiexec.exe -Wait -ArgumentList $Args
        
    }
    Else 
    {
        Write-Warning "AWS CLI Check: Failed, install AWS CLI from here https://docs.aws.amazon.com/cli/latest/userguide/install-windows.html" 
        Read-Host -prompt "Press any key to quit"
        Exit $LastExitCode
    }
}

################################    AWS Profile     ########################################################################
# Check to Ensure AWS Powershell Profile is configured 
############################################################################################################################
Try 
{
    Initialize-AWSDefaultConfiguration

}
Catch
{
    write-warning "Warning: No AWS Powershell profile exists."
    write-warning "See https://aws.amazon.com/powershell/ for further information on configuring powershell"
    Read-Host -prompt "Press any key to quit"
    Exit
} 

write-Host "4. AWS Profile Check      : Passed"


################################    Domain Join Paramaters ##################################################################
# Check to ensure AWS Paramater Store Domain Join Pramaters are created. These Paramaters used to Join a system to the Domain.
#############################################################################################################################

Try  
{
    Get-SSMParameter -Name "DomainName" -Region $AWSRegion
    Get-SSMParameter -Name "DomainJoinUserName" -Region $AWSRegion
    Get-SSMParameter -Name "DomainJoinPassword" -Region $AWSRegion
}
Catch
{
    
    $Form = New-Object System.Windows.Forms.Form
    $Form.Width = 600
    $Form.Height = 300
    $Form.AutoScroll = $True
    $Form.AutoSize = $True
    $Form.StartPosition = "CenterScreen"
    $Icon = New-Object system.drawing.icon ($currentDir + "\Amazon.ico")
    $Form.Icon = $Icon
    $Form.Text = "AWS Systems Manager Parameters"
    $Font = New-Object System.Drawing.Font("Times New Roman",12)
    $Form.Font = $Font

    $Label = New-Object System.Windows.Forms.Label
    $Label.Text = "Username for Domain Joins:"
    $Label.AutoSize = $True
    $Label.Left = 15
    $Label.Top = 10
    $Form.Controls.Add($Label)

    $Label2 = New-Object System.Windows.Forms.Label
    $Label2.Text = "Password for Domain Joins:"
    $Label2.AutoSize = $True
    $Label2.Left = 15
    $Label2.Top = 90
    $Form.Controls.Add($Label2)


    $MaskedTextBox = New-Object System.Windows.Forms.Textbox
    $MaskedTextBox.Top = 45
    $MaskedTextBox.Left = 15
    $MaskedTextBox.Height = 300;
    $MaskedTextBox.Width = 380;
    $MaskedTextBox.Text = "username@mydomain"
    $Form.Controls.Add($MaskedTextBox)

    $MaskedTextBox2 = New-Object System.Windows.Forms.maskedTextbox
    $MaskedTextBox2.PasswordChar = '*'
    $MaskedTextBox2.Top = 120
    $MaskedTextBox2.Left = 15
    $MaskedTextBox2.Height = 300;
    $MaskedTextBox2.Width = 380;
    $Form.Controls.Add($MaskedTextBox2)

    # BUTTON 
    # Create Button and set text and location
    $button = New-Object Windows.Forms.Button
    $button.text = "OK"
    $button.Location = New-Object Drawing.Point 15,200
    $button.Width = 100
    $form.controls.add($button)

    # BUTTON 
    # Create Button and set text and location
    $button2 = New-Object Windows.Forms.Button
    $button2.text = "Cancel"
    $button2.Location = New-Object Drawing.Point 120,200
    $button2.Width = 100
    $form.controls.add($button2)


    $button.add_click(
    {

        $global:username = $MaskedTextBox.Text
        $global:password = $MaskedTextBox2.Text

        $form.Close()

    })

    $button2.add_click(
    {
       $form.Close()
    })
    $Form.ShowDialog()


    Write-SSMParameter -Name "DomainJoinUserName" -Value $username -Type String -Overwrite $true -ErrorAction Stop
    aws ssm put-parameter --name DomainJoinPassword --value $password --type SecureString
    Write-SSMParameter -Name "DomainName" -Value $xmldocument.Config.DomainJoin.Name -Type string -Overwrite $true -ErrorAction Stop
}

 write-host "5. AWS SSM Check          : Passed"
 ################################    Domain Join Paramaters ##################################################################
# Check to ensure AWS Systems Managed Domain Join Document Exists. This is used to Join a System to the Domain
#############################################################################################################################
try
{
    Get-SSMDocument -Name JoinInstanceToDomain -Region $AWSRegion
}
catch
{
    write-Host "6. Domain Join Document   : Missing. Creating new"
    $JoinInstanceToDomain = '{
                            "schemaVersion": "2.2",
                            "description": "Run a PowerShell script to securely domain-join a Windows instance",
                            "mainSteps": [
                                {
                                    "action": "aws:runPowerShellScript",
                                    "name": "runPowerShellWithSecureString",
                                    "precondition": {
                                        "StringEquals": [
                                            "platformType",
                                            "Windows"
                                        ]
                                    },
                                    "inputs": {
                                        "runCommand": [
                                            "$domain = (Get-SSMParameterValue -Name DomainName).Parameters[0].Value",
                                            "$username = (Get-SSMParameterValue -Name DomainJoinUserName).Parameters[0].Value",
                                            "$password = (Get-SSMParameterValue -Name DomainJoinPassword -WithDecryption $True).Parameters[0].Value | ConvertTo-SecureString -asPlainText -Force",
                                            "$credential = New-Object System.Management.Automation.PSCredential($username,$password)",
                                            "Add-Computer -DomainName $domain -Credential $credential -ErrorAction Stop",
                                            "Restart-Computer -force"
                                        ]
                                    }
                                }
                            ]
                        }' 


        try
            {
                New-SSMDocument -Name JoinInstanceToDomain -Content $JoinInstanceToDomain -DocumentType Command
            }
            Catch [System.InvalidOperationException] 
            {
                Write-Warning "Unable to SSM Domain Join Document create document, check that the SSM document does not exist already. If it does exist, check that it is correct, if incorrect delete the document and run this script again "
                Exit 1000
            }

            Catch
            {
                Write-Host $PSItem.Exception.Message
                Exit $LastExitCode
            }

            }

Read-host "All Checks Passed, Press any key to start installation"