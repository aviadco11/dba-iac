#Initialize and format volumes to 64 blocks
$driveCount = ((& 'C:\Program Files\Amazon\EC2Launch\tools\ebsnvme-id.exe' | Select-String -Pattern ("Device Name") | Measure-Object -Line).Lines - 1) 
if ($driveCount -lt 1) { return "No Additional Drives Detected"
}
foreach ($driveNumber in 1..$driveCount) { $driveName = "$(& 'C:\Program Files\Amazon\EC2Launch\tools\ebsnvme-id.exe' $driveNumber | Select-String -Pattern ("Device Name"))"
 $driveLetter = $driveName.Remove(0, ($driveName.Length - 1)).toUpper() 

 Initialize-Disk -Number $driveNumber -PartitionStyle GPT
 New-Partition -DiskNumber $driveNumber -UseMaximumSize -DriveLetter $driveLetter | format-volume -filesystem NTFS -newfilesystemlabel $driveLetter -AllocationUnitSize 65536 
}



# Define an array of drive letters and corresponding labels
$drives = @(
    @{ Letter = "D"; Label = "Data" },
    @{ Letter = "L"; Label = "Log" },
    @{ Letter = "T"; Label = "Temp" }
)

# Loop through each drive and label it
foreach ($drive in $drives) {
    $driveLetter = $drive["Letter"] + ":"
    $label = $drive["Label"]
    
    # Check if the drive exists and is NTFS
    $volume = Get-Volume -DriveLetter $drive["Letter"] -ErrorAction SilentlyContinue
    if ($volume -and $volume.FileSystem -eq "NTFS") {
        # Set the label for the NTFS volume
        Set-Volume -DriveLetter $drive["Letter"] -NewFileSystemLabel $label
        Write-Host "Labeled $driveLetter as '$label'"
    } else {
        Write-Host "Drive $driveLetter does not exist or is not NTFS."
    }
}


# Define the path for the new directory
$directoryPath = "L:\SQLJobsOutput\"

# Create the directory
New-Item -Path $directoryPath -ItemType Directory -Force

Write-Output "Directory created at $directoryPath"

Write-Host "Drive Prep done!" -ForegroundColor Yellow

