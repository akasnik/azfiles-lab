To update DSC Configurations:
1) make sure all modules (xNetworking, xStorage...) are available on computer with using 'Install-Module -Name xStorage' command.
1) After updating .ps1 configuration run 'Publish-AzVMDscConfiguration .\CreateADPDCdbg.ps1 -OutputArchivePath .\CreateADPDCdbg.ps1.zip' to get updated package
1) Make updated config publicaly available

