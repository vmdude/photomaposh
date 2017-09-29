function New-FolderIfNotExist($rootPath)
{
    if ( !(test-path $rootPath) )
    {
        New-Item -ItemType Directory -Force -Path $rootPath | Out-Null
    }

}

function Get-HumanReadableDatetime($start, $finish)
{
    $prettyDatetime = ""
    $diffTime = New-Timespan -Start $start -End $finish
    if ($diffTime.Days -ne 0)
    {
        $prettyDatetime = [String]$diffTime.Days + " days"
    }
    if ($diffTime.Hours -ne 0)
    {
        $prettyDatetime = Add-Text $prettyDatetime ([String]$diffTime.Hours + " hours")
    }
    if ($diffTime.Minutes -ne 0)
    {
        $prettyDatetime = Add-Text $prettyDatetime ([String]$diffTime.Minutes + " minutes")
    }
    if ($diffTime.Seconds -ne 0)
    {
        $prettyDatetime = Add-Text $prettyDatetime ([String]$diffTime.Seconds + " seconds")
    }
    if ($diffTime.Milliseconds -ne 0)
    {
        $prettyDatetime = Add-Text $prettyDatetime ([String]$diffTime.Milliseconds + "ms")
    }
    else
    {
        $prettyDatetime = [String]([Math]::Round($diffTime.TotalMilliseconds, 0)) + "ms"
    }
    return $prettyDatetime
}

function Add-Text($source, $text)
{
    if ( $source.Length -eq 0 )
    {
        return $text
    }
    else
    {
        return "$source, $text"
    }
}

function Test-Date($date)
{
    return $true
}

function Test-TitleCase($text)
{
    if ( (Get-Culture).textinfo.totitlecase($text.tolower()) -ceq $text )
    {
        return $true
    }
    else
    {
        return $false
    }
}

function Get-ValidName($badName)
{
    $dateBadName = $badName.Split(" ")[0]
    return "$dateBadName " + (Get-Culture).textinfo.totitlecase($badName.split(" ", 2)[1].tolower())
}

function Get-FileMetaData([System.IO.FileSystemInfo]$file)
{
    $hResult = @{}
    $shell = New-Object -ComObject Shell.Application
    $folder = $shell.namespace($file.DirectoryName)
    $item = $folder.Items().Item($file.Name)
    for ($a = 0; $a -le 266; $a++) {
        if (!($hResult.ContainsKey($objFolder.getDetailsOf($objFolder.items, $a))))
        {
            $hResult.Add($objFolder.getDetailsOf($objFolder.items, $a), $folder.getdetailsof($item, $a))
        }
    }
    return $hResult
}

function Get-FileMetaDateTaken([System.IO.FileSystemInfo]$file)
{
    $shell = New-Object -ComObject Shell.Application
    $folder = $shell.namespace($file.DirectoryName)
    $item = $folder.Items().Item($file.Name)
    return ($folder.getdetailsof($item, 12) -Replace [char]8206) -Replace [char]8207
}

function Get-ValidNameFromFolder($badName)
{
    $dateName = $badName.Split(" ")[0].Replace("-", "")
    return $dateName + "_" + (Get-Culture).textinfo.totitlecase($badName.Split(" ", 2)[1]).Replace(" ", "").Replace(",", "").Replace("-", "")
}