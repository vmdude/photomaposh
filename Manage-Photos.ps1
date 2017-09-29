#Requires -Version 4

Param (
    [Parameter(Mandatory=$true)]
    [string]$startFolder,
    [switch]$nodryrun = $false
) # END Param

# Include required files
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
try {
    . ("$ScriptDirectory\photomaposh.functions.ps1")
}
catch {
    Write-Host -ForegroundColor Red -BackgroundColor Black "Error while loading supporting PowerShell Scripts"
    Exit
}
# END Include

# Validate root folder
if ( !(test-path $startFolder) )
{
    Write-Host -ForegroundColor Red -BackgroundColor Black "Mandatory root folder $startFolder doesn't exists, please check. Aborting..."
    Exit
}
#Get-FileMetaData $startFolder

$start = Get-Date
$myRootPath = "Y:\Download\A_TRIER_PHOTOS\"
$myDeletePath = $myRootPath + "todelete\"
$myRawMovePath = $myRootPath + "tomovePhotosRAW\"
$myJpgMovePath = $myRootPath + "tomovePhotos\"

New-FolderIfNotExist($myDeletePath)
New-FolderIfNotExist($myRawMovePath)
New-FolderIfNotExist($myJpgMovePath)

Write-Host -ForegroundColor Magenta "> Starting photomapyc process on" (Get-Date -Format G)
Write-Host -ForegroundColor Magenta "> Selected root folder is $startFolder"

# First step is directory naming check
$step1start = Get-Date
$needFixDirectories = New-Object System.Collections.ArrayList
$cleanDirectories = New-Object System.Collections.ArrayList

Write-Host -ForegroundColor Cyan ">> Step 1: Directory naming check"

foreach ($folder in Get-ChildItem -Directory $startFolder | Sort-Object -Property Name)
{
    if ( (Test-Date $folder.Name.Split(" ")[0]) -And (Test-TitleCase $folder.Name.Split(" ", 2)[1]) )
    {
        Write-Host -ForegroundColor Green "   $folder"
        $cleanDirectories.Add($folder) | Out-Null
    }
    else
    {
        Write-Host -ForegroundColor Red "   $folder"
        $needFixDirectories.Add($folder) | Out-Null
    }
}

if ($needFixDirectories.Count -gt 0)
{
    foreach ($needFixDirectory in $needFixDirectories)
    {
        $newName = Get-ValidName $needFixDirectory.Name
        if ($newName -cne $needFixDirectory.Name)
        {
            Rename-Item -Path $needFixDirectory.FullName -NewName $newName -WhatIf
        }
        else
        {
            Write-Host -ForegroundColor Red -BackgroundColor Black "Cannot find better name for '" $needFixDirectory.FullName "', this could be caused by wrong date, please fix it before going further, aborting..."
            Exit
        }
    }
}

$step1finish = Get-Date
Write-Host -ForegroundColor Cyan ">> Step 1 completed successfully in"  (Get-HumanReadableDatetime $step1start $step1finish)


# Second step is finding orphan files and removing them
$step2start = Get-Date
$jpgFiles = New-Object System.Collections.ArrayList
$rawFiles = New-Object System.Collections.ArrayList
$orphansRawFiles = New-Object System.Collections.ArrayList

Write-Host -ForegroundColor Cyan ">> Step 2: Finding orphans RAW files"

foreach ($photoFile in Get-ChildItem -Path $startFolder -Recurse -Include *.jpg, *.cr2 -Exclude '.DS_Store')
{
    if ($photoFile.Extension -match ".jpg")
    {
        $jpgFiles.Add($photoFile) | Out-Null
    }
    else
    {
        $rawFiles.Add($photoFile) | Out-Null
    }
}

foreach ($rawFile in $rawFiles)
{
    if (!(Test-Path ($rawFile.FullName -ireplace(".cr2",".jpg"))))
    {
        $orphanRawFileDirectory = $rawFile.DirectoryName.replace($startFolder, $myDeletePath)
        New-FolderIfNotExist($orphanRawFileDirectory)
        $orphansRawFiles.Add($rawFile) | Out-Null
        Move-Item -Path $rawFile.FullName -Destination $orphanRawFileDirectory -WhatIf
        Write-Host -ForegroundColor Green "   Orphan file moved:" $rawFile.Name
    }
}

foreach ($orphanRawFile in $orphansRawFiles)
{
    $rawFiles.Remove($orphanRawFile)
}

$step2finish = Get-Date
Write-Host -ForegroundColor Cyan ">> Step 2 completed successfully in"  (Get-HumanReadableDatetime $step2start $step2finish)

if ($jpgFiles.Count -ne $rawFiles.Count)
{
    Write-Host -ForegroundColor Red -BackgroundColor Black "Mismatch between JPG count ("$jpgFiles.Count") and RAW count ("$rawFiles.Count")! Aborting..."
    exit
}



# Thirs step is renaming photo based on EXIF tags
# rename_photo_exif()

# Fourth step is separating JPG files from RAW files
# separating_raw_files()
$finish = Get-Date
Write-Host -ForegroundColor Magenta "> Completed in" (Get-HumanReadableDatetime $start $finish)

