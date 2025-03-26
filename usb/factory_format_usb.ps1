# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run this script as an administrator."
    exit
}

# Get all physical disks with BusType "USB"
$usbPhysicalDisks = Get-PhysicalDisk | Where-Object { $_.BusType -eq "USB" }

if ($usbPhysicalDisks.Count -eq 0) {
    Write-Host "No USB disks found."
    exit
}

# Get the corresponding disks
$diskNumbers = $usbPhysicalDisks | ForEach-Object { $_.DeviceId }
$disks = Get-Disk | Where-Object { $diskNumbers -contains $_.Number }

# Display the list of USB disks
Write-Host "Available USB disks:"
$disks | ForEach-Object {
    Write-Host "Disk $($_.Number): $($_.FriendlyName) - $([math]::Round($_.Size / 1GB, 2)) GB"
}

# Ask the user to select the disk number
$diskNumber = Read-Host "Enter the disk number of the USB drive to reset"

# Validate the input
if ($disks.Number -notcontains $diskNumber) {
    Write-Host "Invalid disk number."
    exit
}

# Display warning and ask for confirmation
Write-Host "Warning: This will erase all data on disk $diskNumber. Ensure the drive is not in use."
$confirm = Read-Host "Are you sure you want to proceed? (Y/N)"

if ($confirm -ne "Y") {
    Write-Host "Operation cancelled."
    exit
}

# Perform the reset
try {
    Clear-Disk -Number $diskNumber -RemoveData -RemoveOEM -Confirm:$false
    $partition = New-Partition -DiskNumber $diskNumber -UseMaximumSize -AssignDriveLetter
    Format-Volume -Partition $partition -FileSystem NTFS -NewFileSystemLabel "USB Drive" -Confirm:$false
    Write-Host "USB drive has been reset successfully."
} catch {
    Write-Host "An error occurred: $_"
}