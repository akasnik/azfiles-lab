# Azure Files MicroHack (bicep)

## Introduction

The Azure Files MicroHack walks through the setup of Azure Files in an hybrid environment with Azure File Sync and related features (TBC - add AD integration etc.)

## Learning Objectives
We often see new customers onboarding to Azure Files or looking to run PoC to validate the service, try file server migration, tools, approach, etc. struggle with deployment and look for lab environment to play around the setup and tools. Azure Files MicroHack helps by providing an automated lab environment (using bicep) to mimic an on-prem environment with DC, File Servers (with Branch Site), DFS-N, dummy data and a hybrid setup with Azure (TBC)

1. Provision an on-premise environment (automated with DSC, bicep)
2. Set up Azure Files and File Sync service
3. Sync files data
4. Config Private Endpoint
5. Enable on-premises AD DS Auth
TBC - to be reviewed updated based on lab scenario around AD integration, feasibility etc.

:::image type="content" source="./media/1-architecture-diagram.png" alt-text="Architecture diagram illustrating an environment for Azure Files lab." border="false":::

## Challenges
1. Challenge 0: **[Deploy lab using template](bicep/)**
   - Deploy the base environment for the lab using Azure subscription. 
2. Challenge 1: **[Setup Azure Files and File Sync Service](Student/Challenge-01.md)**
   - Create Azure Files share, setup and config Storage Sync Service.
3. Challenge 2: **[Configure Server endpoint and Cloud tiering](Student/Challenge-02.md)**
   - Config HQ File Server endpoint and setup cloud tiering.
4. Challenge 3: **[Add Branch File Server as a new server endpoint](Student/Challenge-03.md)**
   - Config Branch File Server to replicate/sync the files from Azure Files.
5. Challenge 4: **[Enable Data Protection - Snapshot or Azure Backup](Student/Challenge-04.md)**
   - Review soft delete feature, manage snapshots, and configure Azure Backup.
6. Challenge 5: **[Secure Azure File Share with Private Endpoint](Student/Challenge-04.md)**
   - Configure storage firewall and enable private endpoint for secure access to Azure file share.

## Prerequisites
- Your own Azure subscription with Owner access
- Visual Studio Code
- Az PowerShell Module

## Challenge 0: Deploy lab bicep/arm template
Deploy the base environment for the lab using the bicep/arm template in your Azure subscription. This will deploy the following components:
- On-prem (HQ and Branch Site):
    - HQ Domain Controller (vm-hq-dc)
    - HQ File Server (vm-hq-fs-1)
    - Client Machine (vm-hq-client-1)
    - Branch File Server (vm-branch1-fs-1)
- Azure
    - Virtual Network (vnet-azhub)
- Azure Bastion

### Deploy lab template using templates

Steps to deploy Azure Files lab environment:

1. Replicate this GitHub repository to computer with latest Azure Powershell module or Azure CLI
1. Login to your Azure subscription using PowerShell or Azure CLI
    - AZ CLI: az login
1. Create resource group in Azure where lab environment will be deployed
    - AZ CLI:  az group create -n  'rg-lab-afs'
    - PowerShell:
1. (Optional) Modify parameter values within ./bicep/azfiles-lab.parameters.json file
1. Create resource group in Azure where lab environment will be deployed
    - AZ CLI:  az deployment group create -g 'rg-lab-afs' -f ..\bicep\azfiles-lab.json --parameters ..\bicep\azfiles-lab.parameters.json
    - Powershell:
1. Type password to be used for all accounts (including domain admin) in your lab environment. Be sure to remember that password as you will need it to log into lab environment.
1. Wait for deployment to finish, it should take around 30 minutes for deployment to finish.

### Validate Lab
Steps to check connectivity and validate DSC has done the required configurations for the base lab to start with.

## Challenge 1: Setup Azure Files and File Sync Service
Create Azure Files share, setup and config Storage Sync Service.

1. Create an Azure Storage account and file share
    - Follow https://docs.microsoft.com/en-us/azure/storage/files/storage-how-to-create-file-share?tabs=azure-portal

2. Deploy Storage Sync Service
    - Follow https://docs.microsoft.com/en-us/azure/storage/files/storage-sync-files-extend-servers#deploy-the-service

3. Deploy Azure File Sync Agent on HQ File Server (vm-hq-fs-1)
    - Use Azure Bastion to connect to the VM
    - Install Azure Az powershell module
    - Follow https://docs.microsoft.com/en-us/azure/storage/files/storage-sync-files-extend-servers#install-the-agent

4. Register HQ File Server with Storage Sync Service
    - Follow https://docs.microsoft.com/en-us/azure/storage/files/storage-sync-files-deployment-guide?tabs=azure-portal%2Cproactive-portal#register-windows-server-with-storage-sync-service

5. Create a Sync Group and Cloud Endpoint
    - Follow https://docs.microsoft.com/en-us/azure/storage/files/storage-sync-files-deployment-guide?tabs=azure-portal%2Cproactive-portal#create-a-sync-group-and-a-cloud-endpoint

## Challenge 2: Configure Server endpoint and Cloud tiering
Create HQ File Server endpoint and configure cloud tiering.

1. Create a Server Endpoint for HQ File Server using data path 'F:\Share1' which has pre-created dummy data files.
    - Follow https://docs.microsoft.com/en-us/azure/storage/files/storage-sync-files-deployment-guide?tabs=azure-portal%2Cproactive-portal#create-a-server-endpoint
    - Let file sync do the full upload to the Azure file share (cloud endpoint).
    - Azure File Sync runs a process to detect the files in the cloud before starting the initial sync. The time taken to complete this process varies depending on the various factors like network speed, available bandwidth, and number of files and folders. For the rough estimation in the preview release, detection process runs approximately at 10 files/sec. Hence, even if pre-seeding runs fast, the overall time to get a fully running system may be significantly longer when data is pre-seeded in the cloud.

2. Go to Sync group, select the server endpoint to see the status of the last completed sync sessions. A green Health column and a Files Not Syncing value of 0 indicate that sync is working as expected. 
    - If this is not the case, refer the troubleshooting article https://docs.microsoft.com/en-us/azure/storage/files/storage-sync-files-troubleshoot?tabs=portal1%2Cazure-portal to check common sync errors and how to handle files that are not syncing.

3. Go to Azure File Share and see whether the data on F:\Share1 is listed. Navigate through the folder structure and access the files.

4. Modify files (add or change content on a .txt file for example) on HQ File Server under Share1 folder and check whether the changes have synchronized on Azure File share by downloading the file from the portal.

More info on Cloud tiering policies: https://docs.microsoft.com/en-us/azure/storage/files/storage-sync-cloud-tiering-overview


## Challenge 3: Add Branch File Server as a new server endpoint
Config Branch File Server (no file shares) to replicate/sync the files from Azure Files. The idea is to have a local cache of often/recently accessed (hot) files in branch file server for branch users. Configure cloud tiering policy.

1. Create a folder 'F:\BR-Share1' in Branch File Server (vm-branch1-fs-1)

2. Deploy Azure File Sync Agent

3. Register Branch File Server with Storage Sync Service

4. Add Branch File Server 'F:\BR-Share1' as new server endpoint to existing Sync Group.
    - Follow https://docs.microsoft.com/en-us/azure/storage/files/storage-sync-files-server-endpoint
    - Config desired cloud tiering policy



## Challenge 4: Enable Data Protection - Snapshot or Azure Backup
Create snapshots, and configure Azure Backup.

1. Snapshot Management

2. Enable backup for file share using Azure Backup
    - Follow steps here below to create a Recovery Services Vault and configure backup.
    - Steps: https://docs.microsoft.com/en-us/azure/backup/backup-afs?toc=/azure/storage/files/toc.json

3. Run an on-demand backup job (Backup Now)
    - Follow https://docs.microsoft.com/en-us/azure/backup/backup-afs?toc=/azure/storage/files/toc.json#run-an-on-demand-backup-job

4. Once backup job is complete, delete few files/folders from HQ File Server.

5. Restore files to original location using Azure Backup - Restore operation.
    - You can do a full share recovery to original location or another location and also perform item-level recovery.
    - Follow https://docs.microsoft.com/en-us/azure/backup/restore-afs?toc=/azure/storage/files/toc.json

## Challenge 5: Secure Azure File Share with Private Endpoint
Configure storage firewall (restrict public endpoint) and enable private endpoint for secure access to Azure file share.

TBD: Expand on this lab scenario. More prescriptive guidance to be added.

1. Create Private endpoint
    - Follow https://docs.microsoft.com/en-us/azure/storage/files/storage-files-networking-endpoints?tabs=azure-portal

2. Restrict Public endpoint access
    - Follow https://docs.microsoft.com/en-us/azure/storage/files/storage-files-networking-endpoints?tabs=azure-portal#restrict-public-endpoint-access


## Monitor Azure File Sync
To view health of the File sync deployment and sync status: https://docs.microsoft.com/en-us/azure/storage/files/storage-sync-files-monitoring 

## More Info on Azure Files and File Sync

- **[Planning for an Azure Files Deployment](https://docs.microsoft.com/en-us/azure/storage/files/storage-files-planning)**
- **[Planning for an Azure File Sync Deployment](https://docs.microsoft.com/en-us/azure/storage/files/storage-sync-files-planning)**
- Recommended Sessions:
    - https://www.youtube.com/watch?v=H04e9AgbcSc
    - https://www.youtube.com/watch?v=m5_-GsKv4-o

## Delete your lab
- When you are finished or you want to redeploy the lab, delete the resource group "rg-afs-lab"

## Contributors
- Andrej Kasnik
- Jithin P P