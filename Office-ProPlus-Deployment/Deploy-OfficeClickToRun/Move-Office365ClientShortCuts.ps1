function Get-CurrentLineNumber {
    $MyInvocation.ScriptLineNumber
}


function Get-CurrentFileName{
    $MyInvocation.ScriptName.Substring($MyInvocation.ScriptName.LastIndexOf("\")+1)
}

function Get-CurrentFunctionName {
    (Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name;
}






            Function WriteToLogFile() {
    param( 
      [Parameter(Mandatory=$true)]
      [string]$LNumber,
      [Parameter(Mandatory=$true)]
      [string]$FName,
      [Parameter(Mandatory=$true)]
      [string]$ActionError
   )
   try{
   $headerString = "Time".PadRight(30, ' ') + "Line Number".PadRight(15,' ') + "FileName".PadRight(60,' ') + "Action"
$stringToWrite = $(Get-Date -Format G).PadRight(30, ' ') + $($LNumber).PadRight(15, ' ') + $($FName).PadRight(60,' ') + $ActionError
   #check if file exists, create if it doesn't
   if(Test-Path C:\Windows\Temp\OfficeAutoScriptLog.txt){#if exists, append
   
        Add-Content C:\Windows\Temp\OfficeAutoScriptLog.txt $stringToWrite
   }
   else{#if not exists, create new
        Add-Content C:\Windows\Temp\OfficeAutoScriptLog.txt $headerString
        Add-Content C:\Windows\Temp\OfficeAutoScriptLog.txt $stringToWrite
   }
   } catch [Exception]{
   Write-Host $_
   }
}

function Move-Office365ClientShortCuts {
    [CmdletBinding()]
    Param(
       [Parameter(ValueFromPipelineByPropertyName=$true, Position=0)]
       [string]$FolderName = "Microsoft Office 2016",
       
       [Parameter(ValueFromPipelineByPropertyName=$true, Position=1)]
       [bool]$MoveToolsFolder = $false                                                                        
    )

    $sh = New-Object -COM WScript.Shell
    $programsPath = $sh.SpecialFolders.Item("AllUsersStartMenu")

    #Create new subfolder                                                                       
    if(!(Test-Path -Path "$programsPath\Programs\$FolderName")){
        New-Item -ItemType directory -Path "$programsPath\Programs\$FolderName"  -ErrorAction Stop | Out-Null
    }    

    if ($MoveToolsFolder) {
        $toolsPath = "$programsPath\Programs\Microsoft Office 2016 Tools"
        if(Test-Path -Path $toolsPath){
            Move-Item -Path $toolsPath -Destination "$programsPath\Programs\$FolderName\Microsoft Office 2016 Tools"  -ErrorAction Stop | Out-Null
        }    
    }
    
    $items = Get-ChildItem -Path "$programsPath\Programs"

    $OfficeInstallPath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun" -Name "InstallPath").InstallPath
    
    $itemsToMove = $false
    foreach ($item in $items) {
       if ($item.Name -like "*.lnk") {

           $itemName = $item.Name
           
           $targetPath = $sh.CreateShortcut($item.fullname).TargetPath

           if ($targetPath -like "$OfficeInstallPath\root\*") {
              $itemsToMove = $true
              $movePath = "$programsPath\Programs\$FolderName\$itemName"

              Move-Item -Path $item.FullName -Destination $movePath -Force -ErrorAction Stop

              Write-Host "$itemName Moved"
              <# write log#>
                $lineNum = Get-CurrentLineNumber    
                $filName = Get-CurrentFileName 
                WriteToLogFile -LNumber $lineNum -FName $filName -ActionError "$itemName Moved"
           }
       }
    }    

    if (!($itemsToMove)) {
       Write-Host "There are no Office 365 ProPlus client ShortCuts to Move"
       <# write log#>
        $lineNum = Get-CurrentLineNumber    
        $filName = Get-CurrentFileName 
        WriteToLogFile -LNumber $lineNum -FName $filName -ActionError "There are no Office 365 ProPlus client ShortCuts to Move"
    }
}

