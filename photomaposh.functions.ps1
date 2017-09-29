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

function Get-FileMetaData($filePath)
{
    $folder = $filePath
    foreach($sFolder in $folder)
     {
      $a = 0
      $objShell = New-Object -ComObject Shell.Application
      $objFolder = $objShell.namespace($sFolder)
   
      foreach ($File in $objFolder.items())
       { 
        $FileMetaData = New-Object PSOBJECT
         for ($a ; $a  -le 266; $a++)
          { 
            if($objFolder.getDetailsOf($File, $a))
              {
                $hash += @{$($objFolder.getDetailsOf($objFolder.items, $a))  =
                      $($objFolder.getDetailsOf($File, $a)) }
               $FileMetaData | Add-Member $hash
               $hash.clear() 
              } #end if
          } #end for 
        $a=0
        $FileMetaData
       } #end foreach $file
     } #end foreach $sfolder
}