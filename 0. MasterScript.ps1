# Copyright (c) 2019. Amazon Web Services UK LTD. All Rights Reserved.
# AWS Microsoft Solution Architecture Team
#
# Name	     		: SQL AlwaysOn
# Version    		: 0.0.1
# Encoded    		: No
# Paramaters   		: None
# Platform   		: Windows
# Associated Files	: .\App.Config.ps1xml
# Abstract   		: Deploy SQL ALways On Cluster into pre-existing VPC. Master File
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

[string]$global:currentDir = get-location
$FirstScript =  $currentDir+"\1.PreRequistsChecking.ps1"
If (Test-Path $FirstScript) {} Else {write-host  "Scripts not found, try changing directory or copying scripts to " $currentDir}

# Run Scripts

.\1.PreRequistsChecking.ps1      # Checks AWS CLI & AWS PowerShell is configured correctly
.\2.GlobalVariables.ps1          # Reads .\App.Config.ps1xml and loads configuration
.\3.InstanceLaunch.ps1           # Launches 3 x Windows Server 2019 VMs distributed into three avalibvilty Zones
.\4.ConfigureWindows.ps1         # Enable EC2 Systems Manager, Domain Join, Install Updates

# TO DO
#.\4-ConfigureEBS.ps1            # Create EBS Volumes, attach and Format
#.\5-COnfigureClustering.ps1     # Configures Windows Clustering
#.\6.InstallSQL.ps1              # Installs SQL
