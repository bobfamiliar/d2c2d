<#
.Synopsis 
    This PowerShell script provisions a Stream Analytics Job
.Description 
    This PowerShell script provisions a Stream Analytics Job
.Notes 
    File Name  : Provision-SAJob-2.ps1
    Author     : Bob Familiar
    Requires   : PowerShell V4 or above, PowerShell / ISE Elevated

    Please do not forget to ensure you have the proper local PowerShell Execution Policy set:

        Example:  Set-ExecutionPolicy Unrestricted 

    NEED HELP?

    Get-Help .\Provision-SAJob-2.ps1 [Null], [-Full], [-Detailed], [-Examples]

.Link   
    https://msdn.microsoft.com/en-us/library/azure/dn835015.aspx
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0, HelpMessage="The storage account name.")]
    [string]$Subscription,
    [Parameter(Mandatory=$True, Position=1, HelpMessage="The resource group name.")]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$True, Position=2, HelpMessage="The Azure Service Bus Name Space.")]
    [string]$AzureLocation,
    [Parameter(Mandatory=$True, Position=3, HelpMessage="The prefix for naming standards.")]
    [string]$Prefix,
    [Parameter(Mandatory=$True, Position=4, HelpMessage="The suffix for naming standards.")]
    [string]$Suffix
)

##########################################################################################
# F U N C T I O N S
##########################################################################################

Function Select-Subscription()
{
    Param([String] $Subscription)

    Try
    {
        Set-AzureRmContext  -SubscriptionName $Subscription -ErrorAction Stop
    }
    Catch
    {
        Write-Verbose -Message $Error[0].Exception.Message
    }
}

Function Create-SAJob()
{
    param (
    [string]$SAJobName,
    [string]$SAJobQuery,
    [string]$iothubshortname,
    [string]$IoTHubKeyName,
    [string]$IoTHubKey,
    [String]$AzureLocation, 
    [string]$SBNamespace, 
    [string]$SBQueueName, 
    [string]$SBPolicyName, 
    [string]$SBPolicyKey)

    $CreatedDate = Get-Date -Format u

    $JSON = @"
    {  
       "location":"$AzureLocation",
       "properties":{  
          "sku":{  
             "name":"standard"
          },
          "outputStartTime":"$CreatedDate",
          "outputStartMode":"CustomTime",
          "eventsOutOfOrderPolicy":"drop",
          "eventsOutOfOrderMaxDelayInSeconds":10,
          "inputs":[  
             {  
                "name":"iothub",
                "properties":{  
                   "type":"stream",
                   "serialization":{  
                      "type":"JSON",
                      "properties":{  
                         "encoding":"UTF8"
                      }
                   },
                   "datasource":{  
                      "type":"Microsoft.Devices/IotHubs",
                      "properties":{  
                        "iotHubNamespace": "$iothubshortname",
                        "sharedAccessPolicyKey": "$IotHubKey",
                        "sharedAccessPolicyName": "$IotHubKeyName"
                      }
                   }
                }
             },
             {  
                "name":"refdata",
                "properties":{  
                   "type":"referencedata",
                   "serialization":{  
                      "type":"JSON",
                      "properties":{  
                         "encoding":"UTF8"
                      }
                   },
                   "datasource":{  
                      "type":"Microsoft.Storage/Blob",
                      "storageAccounts": [
                      "$StorageAccountName"
                       ],
                      "properties": {
                        "accountName": "$StorageAccountName",
                        "accountKey": "$SAKeyPrimary",
                        "container": "$StorageContainer",
                        "pathPattern": "devicerules.json"
                      }
                   }
                }
             }
          ],
          "transformation":{  
             "name":"$SAJobName",
             "properties":{  
                "streamingUnits":6,
                "query": "$SAJobQuery"
             }
          },
        "outputs": [
          {
            "name": "queue",
            "properties": {
              "type": "stream",
              "serialization": {
                "type": "JSON",
                "properties": {
                  "encoding": "UTF8"
                }
              },
              "datasource": {
                "type": "Microsoft.ServiceBus/Queue",
                "properties": {
                    "serviceBusNamespace":"$SBNameSpace",
                    "sharedAccessPolicyName":"$SBPolicyName",
                    "sharedAccessPolicyKey":"$SBPolicyKey",
                    "queueName":"$SBQueueName"
                }
              }
            }
          }
        ]
      }
  }
"@

    $Path = ".\SAJobs\$SAJobName.json"

    $JSON | Set-Content -Path $Path

    Start-Sleep -Seconds 10
    Return $Path
}

#######################################################################################
# S E T  P A T H
#######################################################################################

$Path = Split-Path -parent $PSCommandPath
$Path = Split-Path -parent $path

#######################################################################################
# V A R I A B L E S
#######################################################################################

$sbnamespace = $prefix + "sbname" + $suffix

$IoTHubKeyName = "iothubowner"

$sajobname2 = "$prefix-send2queue-refdata-$suffix"

$SAJobQuery2 = "SELECT
    Stream.Id, 
    Stream.DeviceId, 
    Stream.MessageType, 
    Stream.Longitude, 
    Stream.Latitude, 
    Stream.[Timestamp], 
    Stream.Temperature, 
    Stream.Humidity
INTO
    alarmqueue
FROM
    iothub as Stream
JOIN refdata Ref on Stream.MessageType = Ref.MessageType
WHERE
    (Ref.Temperature IS NOT NULL) AND (Stream.Temperature > Ref.Temperature)"

$iothubname = $prefix + "iothub" + $suffix

#######################################################################################
# M A I N
#######################################################################################

# Mark the start time.
$StartTime = Get-Date

$includePath = $Path + "\Automation\Include-ConnectionStrings.ps1"
."$includePath"

# create a storage container
$storagename = $Prefix + "storage" + $Suffix
New-AzureRmStorageAccount -StorageAccountName $storagename -Location $AzureLocation -ResourceGroupName $ResourceGroup -Type Standard_GRS
$storageKey = Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroup -AccountName $storagename
$StorageContext = New-AzureStorageContext -StorageAccountName $storagename -StorageAccountKey $storageKey.Key1
New-AzureStorageContainer -Context $StorageContext -Name "refdata" -Permission Off

# Upload the rules file to blob storage
$refdata = $path + "\automation\deploy\rules\devicerules.json"
Set-AzureStorageBlobContent -Context $StorageContext -Container "refdata" -File $refdata

# get the service bus connection string information
$AzureSBNS = Get-AzureSBNamespace $sbnamespace
$Rule = Get-AzureSBAuthorizationRule -Namespace $sbnamespace 
$SBPolicyName = $Rule.Name
$SBPolicyKey = $Rule.Rule.PrimaryKey

# create the stream analytics job
$SAJobPath = Create-SAJob -SAJobName $sajobname2 -SAJobQuery $SAJobQuery2 -IoTHubShortName $IoTHubName -IoTHubKeyName $IoTHubKeyName -IoTHubKey $iothubkey -AzureLocation $AzureLocation -SBNamespace $sbnamespace -SBQueueName messagedrop -SBPolicyName $SBPolicyName -SBPolicyKey $SBPolicyKey
New-AzureRmStreamAnalyticsJob -ResourceGroupName $ResourceGroupName -Name $sajobname2 -File $SAJobPath -Force
Start-AzureRmStreamAnalyticsJob -ResourceGroupName $ResourceGroupName -Name $sajobname2

# Mark the finish time.
$FinishTime = Get-Date

#Console output
$TotalTime = ($FinishTime - $StartTime).TotalSeconds
Write-Verbose -Message "Elapse Time (Seconds): $TotalTime" -Verbose
