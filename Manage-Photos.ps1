#Requires -Version 4

Param (
    [Parameter(Mandatory=$true)]
    [string]$startFolder,
    [switch]$nodryrun = $false
) # END Param

. .\Get-FileMetaDataReturnObject.ps1

# Validate root folder
if ( !(test-path $startFolder) )
{
    Write-Host -ForegroundColor Red -BackgroundColor Black "Mandatory root folder $startFolder doesn't exists, please check. Aborting..."
    Exit
}
Get-FileMetaData $startFolder
exit
myRootPath = "Y:\Download\A_TRIER_PHOTOS\"
myDeletePath = myRootPath + "todelete\"
myRawMovePath = myRootPath + "tomovePhotosRAW\"
myJpgMovePath = myRootPath + "tomovePhotos\"



If(!(test-path $path))
{
New-Item -ItemType Directory -Force -Path $path
}



# if not os.path.exists(myDeletePath):
# os.makedirs(myDeletePath)

# if not os.path.exists(myJpgMovePath):
# os.makedirs(myJpgMovePath)

# if not os.path.exists(myRawMovePath):
# os.makedirs(myRawMovePath)

# print(bcolors.HEADER + "> Starting photomapyc process on " + strftime("%Y-%m-%d %H:%M:%S", gmtime()) + 
