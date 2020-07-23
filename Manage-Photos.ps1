#Requires -Version 4

# .\Manage-Photos.ps1 -startFolder Y:\Download\TODOPHOTOS
Param (
    [Parameter(Mandatory=$true)]
    [string]$startFolder,
    [switch]$nodryrun = $false
) # END Param

if ($startFolder.endswith("/")) {
    $startFolder = $startFolder -replace ".$"
}
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
$myDeletePath = $myRootPath + "todelete"
$myRawMovePath = $myRootPath + "tomovePhotosRAW"
$myJpgMovePath = $myRootPath + "tomovePhotos"

New-FolderIfNotExist($myDeletePath)
New-FolderIfNotExist($myRawMovePath)
New-FolderIfNotExist($myJpgMovePath)

Write-Host -ForegroundColor Magenta "> Starting photomapyc process on" (Get-Date -Format G)
Write-Host -ForegroundColor Magenta "> Selected root folder is $startFolder"

# First step is directory naming check
$step1start = Get-Date
$Activity = "Managing Photos Awesomeness"
$Id       = 1
$TotalSteps = 5
$Step       = 1
$StepText   = "Directory Naming Check"
Write-Progress -Id $Id -Activity $Activity -Status "Step $Step of $TotalSteps | $StepText" -PercentComplete ($Step / $TotalSteps * 100)

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
            Rename-Item -Path $needFixDirectory.FullName -NewName "tmp_$newName" -PassThru | Rename-Item -NewName $newName
        }
        else
        {
            Write-Host -ForegroundColor Red -BackgroundColor Black "Cannot find better name for '" $needFixDirectory.FullName "', this could be caused by wrong date, please fix it before going further, aborting..."
            Exit
        }
    }
}

# Pre-step : rename jpeg to jpg files
Write-Host -ForegroundColor Cyan ">> Step 1.5: Rename jpeg files"
foreach ($jpeg_file in Get-ChildItem -File "*.jpeg" -Recurse $startFolder | Sort-Object -Property Name)
{
    $jpeg_file | Rename-Item -NewName { [io.path]::ChangeExtension($_.name, "jpg") }
    Write-Host -ForegroundColor Green "   Rename extension for $($jpeg_file.FullName)"
}


$step1finish = Get-Date
Write-Host -ForegroundColor Cyan ">> Step 1 completed successfully in"  (Get-HumanReadableDatetime $step1start $step1finish)


# Second step is finding orphan files and removing them
$step2start = Get-Date
$Step       = 2
$StepText   = "Finding orphan files and removing them"
Write-Progress -Id $Id -Activity $Activity -Status "Step $Step of $TotalSteps | $StepText" -PercentComplete ($Step / $TotalSteps * 100)

$jpgFiles = New-Object System.Collections.ArrayList
$rawFiles = New-Object System.Collections.ArrayList
$videoFiles = New-Object System.Collections.ArrayList
$orphansRawFiles = New-Object System.Collections.ArrayList

Write-Host -ForegroundColor Cyan ">> Step 2: Finding orphans RAW files"

foreach ($photoFile in Get-ChildItem -Path $startFolder -Recurse -Include *.jpg, *.cr2, *.dng, *.heic, *.mov -Exclude '.DS_Store')
{
    if ($photoFile.Extension -match ".jpg|.heic")
    {
        $jpgFiles.Add($photoFile) | Out-Null
    }
    elseif ($photoFile.Extension -match ".mov")
    {
        $videoFiles.Add($photoFile) | Out-Null
    }
    else
    {
        $rawFiles.Add($photoFile) | Out-Null
    }
}

$counter = 1
foreach ($rawFile in $rawFiles)
{
    Write-Progress -Id ($Id+1) -Activity " " -Status ("RAW File $counter of $($rawFiles.Count) | $($rawFile.Name)") -PercentComplete ($counter / ($rawFiles.Count) * 100) -ParentId $Id

    if (!(Test-Path ($rawFile.FullName -ireplace(".cr2",".jpg"))))
    {
        $orphanRawFileDirectory = $rawFile.DirectoryName.replace($startFolder, $myDeletePath)
        New-FolderIfNotExist($orphanRawFileDirectory)
        $orphansRawFiles.Add($rawFile) | Out-Null
        Move-Item -Path $rawFile.FullName -Destination $orphanRawFileDirectory
        Write-Host -ForegroundColor Green "   Orphan file moved:" $rawFile.Name
    }
    $counter++
}

foreach ($orphanRawFile in $orphansRawFiles)
{
    $rawFiles.Remove($orphanRawFile)
}

$step2finish = Get-Date
Write-Host -ForegroundColor Cyan ">> Step 2 completed successfully in"  (Get-HumanReadableDatetime $step2start $step2finish)

# if ($jpgFiles.Count -ne $rawFiles.Count)
# {
#     Write-Host -ForegroundColor Red -BackgroundColor Black "Mismatch between JPG count ("$jpgFiles.Count") and RAW count ("$rawFiles.Count")! Aborting..."
#     # exit
# }


# Third step is renaming photo based on EXIF tags
$step3start = Get-Date
$Step       = 3
$StepText   = "Renaming photo based on EXIF tags"
Write-Progress -Id $Id -Activity $Activity -Status "Step $Step of $TotalSteps | $StepText" -PercentComplete ($Step / $TotalSteps * 100)
Write-Host -ForegroundColor Cyan ">> Step 3: Renaming files based on EXIF infos"

$counter = 1
foreach ($groupFiles in $jpgFiles | Group-Object Directory)
{
    $hFile = @()
    foreach ($photoGroupFile in $groupFiles.Group) {
        try {
            $hFile += @( @{"CreatedDate" = [Math]::Floor([decimal](Get-Date(Get-Date(Get-FileMetaDateTaken $photoGroupFile)).ToUniversalTime()-uformat "%s")); "PhotoFile" = $photoGroupFile} )
        } catch {
            $hFile += @( @{"CreatedDate" = [Math]::Floor([decimal](Get-Date(Get-Date($photoGroupFile.CreationTime)).ToUniversalTime()-uformat "%s")); "PhotoFile" = $photoGroupFile} )
        }
    }
    $filePos = 1
    foreach ($fileToRename in $hFile | Sort-Object {$_.CreatedDate} | %{$_.PhotoFile})
    {
        Write-Progress -Id ($Id+1) -Activity " " -Status ("Photo File $counter of $($jpgFiles.Count) | $($fileToRename.Name)") -PercentComplete ($counter / ($jpgFiles.Count) * 100) -ParentId $Id

        $newName = (Get-ValidNameFromFolder ($fileToRename.DirectoryName | Split-Path -Leaf)) + "_" + $filePos.ToString("000") + "-" + $fileToRename.BaseName
        $newNameJPG = "$newName$($fileToRename.Extension)"
        $newNameRAW = $newName.Insert($newName.IndexOf("_"),"-RAW")
        Rename-Item -Path $fileToRename.FullName -NewName $newNameJPG
        Write-Host -ForegroundColor Green "   Renamed file" $fileToRename.Name "to" $newNameJPG
        if (Test-Path "$($fileToRename.DirectoryName)\$($fileToRename.BaseName).cr2") {
            Rename-Item -Path ($fileToRename.FullName -ireplace(".jpg",".cr2")) -NewName "$newNameRAW.cr2"
            Write-Host -ForegroundColor Green "   Renamed RAW file" ($fileToRename.Name -ireplace(".jpg",".cr2")) "to" "$newNameRAW.cr2"
        } elseif (Test-Path "$($fileToRename.DirectoryName)\$($fileToRename.BaseName).dng") {
            Rename-Item -Path ($fileToRename.FullName -ireplace(".jpg",".dng")) -NewName "$newNameRAW.dng"
            Write-Host -ForegroundColor Green "   Renamed RAW file" ($fileToRename.Name -ireplace(".jpg",".dng")) "to" "$newNameRAW.dng"
        }
        $filePos++
        $counter++
    }
}
foreach ($groupFiles in $videoFiles | Group-Object Directory)
{
    $hFile = @()
    foreach ($photoGroupFile in $groupFiles.Group) {
        $hFile += @( @{"CreatedDate" = ""; "PhotoFile" = $photoGroupFile} )
    }
    foreach ($fileToRename in $hFile | %{$_.PhotoFile})
    {
        $newName = (Get-ValidNameFromFolder ($fileToRename.DirectoryName | Split-Path -Leaf)) + "_000-" + $fileToRename.BaseName
        $newNameMOV = "$newName$($fileToRename.Extension)"
        Rename-Item -Path $fileToRename.FullName -NewName $newNameMOV
        Write-Host -ForegroundColor Green "   Renamed video file" $fileToRename.Name "to" $newNameMOV
    }
}

$step3finish = Get-Date
Write-Host -ForegroundColor Cyan ">> Step 3 completed successfully in"  (Get-HumanReadableDatetime $step3start $step3finish)


# Fourth step is separating JPG files from RAW files
$step4start = Get-Date
$Step       = 4
$StepText   = "Separating JPG files from RAW files"
Write-Progress -Id $Id -Activity $Activity -Status "Step $Step of $TotalSteps | $StepText" -PercentComplete ($Step / $TotalSteps * 100)

$jpgFiles = New-Object System.Collections.ArrayList
$rawFiles = New-Object System.Collections.ArrayList
$videoFiles = New-Object System.Collections.ArrayList

Write-Host -ForegroundColor Cyan ">> Step 4: Separating photos JPG<>RAW"

foreach ($photoFile in Get-ChildItem -Path $startFolder -Recurse -Include *.jpg, *.cr2, *.dng, *.heic, *.mov -Exclude '.DS_Store')
{
    if ($photoFile.Extension -match ".jpg$|.heic$") {
        $jpgFiles.Add($photoFile) | Out-Null
    }
    elseif ($photoFile.Extension -match ".mov")
    {
        $videoFiles.Add($photoFile) | Out-Null
    }
    else {
        $rawFiles.Add($photoFile) | Out-Null
    }
}

$counter = 1
foreach ($jpgFile in $jpgFiles)
{
    Write-Progress -Id ($Id+1) -Activity " " -Status ("Photo File $counter of $($jpgFiles.Count + $rawFiles.Count) | $($jpgFile.Name)") -PercentComplete ($counter / ($jpgFiles.Count + $rawFiles.Count) * 100) -ParentId $Id

    $newJpgFileDirectory = $jpgFile.DirectoryName.replace($startFolder, $myJpgMovePath)
    New-FolderIfNotExist($newJpgFileDirectory)
    Move-Item -Path $jpgFile.FullName -Destination $newJpgFileDirectory
    Write-Host -ForegroundColor Green "   Photo file moved:" $jpgFile.Name "to" $newJpgFileDirectory
    $counter++
}

foreach ($videoFile in $videoFiles)
{
    $newVideoFileDirectory = $videoFile.DirectoryName.replace($startFolder, $myJpgMovePath)
    New-FolderIfNotExist($newVideoFileDirectory)
    Move-Item -Path $videoFile.FullName -Destination $newVideoFileDirectory
    Write-Host -ForegroundColor Green "   Video file moved:" $videoFile.Name "to" $newVideoFileDirectory
}

foreach ($rawFile in $rawFiles)
{
    Write-Progress -Id ($Id+1) -Activity " " -Status ("Photo File $counter of $($jpgFiles.Count + $rawFiles.Count) | $($rawFile.Name)") -PercentComplete ($counter / ($jpgFiles.Count + $rawFiles.Count) * 100) -ParentId $Id

    $newRawFileDirectory = Join-Path $myRawMovePath (($rawFile.DirectoryName | Split-Path -Leaf).Split(" ", 2)[0] + "-RAW " + ($rawFile.DirectoryName | Split-Path -Leaf).Split(" ", 2)[1])
    New-FolderIfNotExist($newRawFileDirectory)
    Move-Item -Path $rawFile.FullName -Destination $newRawFileDirectory
    Write-Host -ForegroundColor Green "   RAW Photo file moved:" $rawFile.Name "to" $newRawFileDirectory
    $counter++
}

$step4finish = Get-Date
Write-Host -ForegroundColor Cyan ">> Step 4 completed successfully in"  (Get-HumanReadableDatetime $step4start $step4finish)



# Last step is cleaning
$step5start = Get-Date
$Step       = 5
$StepText   = "Cleaning"
Write-Progress -Id $Id -Activity $Activity -Status "Step $Step of $TotalSteps | $StepText" -PercentComplete ($Step / $TotalSteps * 100)

Write-Host -ForegroundColor Cyan ">> Step 5: Purge files"

if ((Get-ChildItem -File -Recurse $startFolder -Exclude '.DS_Store').Count -eq 0)
{
    Try {
        Remove-Item $startFolder -Force -Confirm:$false -Recurse -ErrorAction SilentlyContinue
    } Catch {
        Write-Host -ForegroundColor Red -BackgroundColor Black "Error deleting folder $startFolder, please check..."
    }
}
else
{
    Write-Host -ForegroundColor Red -BackgroundColor Black "There are still some files under $startFolder, please check..."
}

$step5finish = Get-Date
Write-Host -ForegroundColor Cyan ">> Step 5 completed successfully in"  (Get-HumanReadableDatetime $step5start $step5finish)


$finish = Get-Date
Write-Host -ForegroundColor Magenta "> Completed in" (Get-HumanReadableDatetime $start $finish)

