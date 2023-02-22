$rg = 'RG-LAB-AFS-FTALIVE'

$disks = Get-AzDisk -ResourceGroupName $rg

foreach($disk in $disks) {
    $snapshot =  New-AzSnapshotConfig -SourceUri $disk.Id -Location $disk.Location -CreateOption copy
    $snapName = 'snp-' + $disk.Name
    Write-Output 'Creating snapshot ' + $snapName
    New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapName -ResourceGroupName $rg
}