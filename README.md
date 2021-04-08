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

TBC - diagram of the final environment setup

## Challenges
1. Challenge 0: **[Deploy lab bicep/arm template](Student/Challenge-00.md)**
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

### Deploy the base environment for the lab using Azure subscription. 



## Challenge 1: Setup Azure Files and File Sync Service
   
### Create Azure Files share, setup and config Storage Sync Service.



## Challenge 2: Configure Server endpoint and Cloud tiering

### Config HQ File Server endpoint and setup cloud tiering.



## Challenge 3: Add Branch File Server as a new server endpoint

### Config Branch File Server to replicate/sync the files from Azure Files.



## Challenge 4: Enable Data Protection - Snapshot or Azure Backup

### Review soft delete feature, manage snapshots, and configure Azure Backup.




## Challenge 5: Secure Azure File Share with Private Endpoint

### Configure storage firewall and enable private endpoint for secure access to Azure file share.





## Delete your lab
- When you are finished or you want to redeploy the lab, delete the resource group "rg-afs-lab"

## Contributors
- Andrej Kasnik
- Jithin P P