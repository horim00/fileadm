using namespace System.Collections.Generic
using namespace System.Management.Automation

#parameter
param(# Parameter help description
[Parameter(Mandatory=$true)]
    [string] $list,
[Parameter(Mandatory=$false)]
[Int32] $kubun=0,
[Parameter(Mandatory=$false)]
[Int32] $start=1,
[Parameter(Mandatory=$false)]
[Int32] $verboselevel=0
)

function checkFileStatus($filePath)
    {
        if  ($verboselevel -eq 3)
        {   
             write-host  "[ACTION][FILECHECK] Checking if" $filePath "is locked"
        }
        $fileInfo = New-Object System.IO.FileInfo $filePath

        try 
        {
            $fileStream = $fileInfo.Open( [System.IO.FileMode]::Open, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read )
            if ($verboselevel -eq 3)
            {
                write-host  "[ACTION][FILEAVAILABLE]" $filePath
            }
            $fileStream.Close()
            return $true
        }
        catch
        {
            write-host  "[ACTION][FILELOCKED] $filePath is locked"
            if ($verboselevel -eq 3)
            {
                write-host $_
            }
            return $false
        }
    }
#

$objlist = [List[PSCustomObject]]::new()
#Hash {Directive,how many times the directive occurres: [A, 0][B, 4]C,2]
$DirectiveHash =@{}
#count target file , start from 1
$TargetFileNumHash=@{}
#Start number for TargetFile
# if TargetFileNumBaseHash{"A"" is 4
#then the number goes 04_A, 05_A
$TargetFileNumBaseHash=@{}
$DirectiveOrder=[List[string]]::new()

$my_file = Get-Content $list
#read file and store
Foreach ($my_string  in $my_file) {
    #split into variable 
    $one, $two,$three = $my_string.split(",").trim()
    # if Directive is "asis", use filename trunk as Directive 
    if ($two -eq "asis")
    {
        if ($one -match "^\d\d_(.*)\.pdf$")
        {
            $two = $Matches.1
        }
        elseif ($one -match "^(.*)\.pdf$")
        {
            $two = $Matches.1
        }
        else {
            $two = $one
        }
    }

    $objlist.Add([pscustomobject]@{FName=$one
        Directive=$two
        RelFName=""
        AbsFName=""
        TargetFile=""
        } )
        #

        #GetUnresolvedProviderPathFromPSPath

    if ($DirectiveHash.ContainsKey($two))
    {
        $DirectiveHash[$two]++
    }
    else {
        $DirectiveHash.Add($two, 0)
        $DirectiveOrder.Add($two)
    }

}

#for each object
foreach ($obj in $objlist)
{
    $obj.RelFName = ".\" + $obj.FName
    $obj.absFName = Convert-path -path $obj.RelFName
    Write-Host $obj.FName
    Write-Host $obj.RelFName
    Write-Host $obj.Directive
}
Write-Host $DirectiveHash
Write-Host "‹æ•ª $kubun"
Write-Host "ŠJŽn $start"

if ($start -le 1)
{
    $count = 0
}
else 
{
    $count = $start - 1
}

$filename=""
foreach ($obj in $objlist)
{
     if ($obj.FName  -match "_’ñŽ¦•¶Œ£ \d+_(.*)$")
    {
        #pick filename from dd_’ñŽ¦•¶Œ£n_filename 
        #        $filename =   ($obj.FName -split "_")[-1]
        $filename = $Matches.1
     }
     elseif ($obj.FName -match "^\d+_(.*)$")
     {
        #pick filename \dd_filename
        $filename = $Matches.1
     }
     else
    {
        $filename = $obj.FName
    } 

    # if directive appears once, no need to generate directive number string
    if ($DirectiveHash[$obj.Directive] -eq 0)
    {
        $count++
#        $countString = $count.ToString("00")
        if (($kubun -eq 8 ) -and  ($obj.Directive  -match "’ñŽ¦•¶Œ£"))
        {
            #kubun 8 only: dd_Directive_filename
            $obj.TargetFile = ".\" + $count.ToString("00")+ "_" + $obj.Directive+"_"+$filename    
        }
        else {
            #otherwise dd_Directive
            $obj.TargetFile = ".\" + $count.ToString("00")+ "_" + $obj.Directive+".pdf"
        }
    }
    else {
        #count up Directive
        if ($TargetFileNumHash.ContainsKey($obj.Directive))
        {
            #the Directive occurres more than once,
            #count up target file number for the directive
            $TargetFileNumHash[$obj.Directive]++
        }
        else {
            #set number for the Directive to 1
            $TargetFileNumHash.Add($obj.Directive, 1)
            $count++
            $TargetFileNumBaseHash.Add($obj.Directive, $count)
            #increment the number by the number of directive occrrence
            $count = $count  + $DirectiveHash[$obj.Directive] 
        }

        # total number = base + count for the directive
        $totalnum = $TargetFileNumBaseHash[$obj.Directive] + $TargetFileNumHash[$obj.Directive] - 1
        
        if (($kubun -eq 8 ) -and  ($obj.Directive  -match "’ñŽ¦•¶Œ£"))
        {
            #pachinko only: dd_DirectiveN_filename
            $obj.TargetFile = ".\" + $totalnum.ToString("00")  + "_"  + $obj.Directive + $TargetFileNumHash[$obj.Directive].ToString()+"_"+$filename
        }
        else {
            # \d\d_DirectiveN.pdf
            $obj.TargetFile = ".\" + $totalnum.ToString("00")  + "_"  + $obj.Directive + $TargetFileNumHash[$obj.Directive].ToString()+".pdf"
        }
    }
}

#test file is available
$errcount = 0
foreach($obj in $objlist)
{
#    if (-not (checkFileStatus($obj.TargetFile)))
#    {
#        Write-Host "Error Path: $obj.TargetFile"
#        $errcount++
#    }

    if (-not (checkFileStatus($obj.AbsFName )))
    {
        Write-Host "Error Path  Source file:" $obj.AbsFName
        $errcount++
    }
}

if ($errcount  -gt  0)
{
    #error and exit
    return $errcount
}

foreach ($obj in $objlist)
{
    try {
        if ($verboselevel -eq 3)
        {
           Write-Host  "rename file From:"  $obj.RelFName  " To: "  $obj.TargetFile 
        }
       Move-Item -Path $obj.RelFName -Destination $obj.TargetFile
    }
    catch {
        Write-Host "rename file failed From:" $obj.RelFName " To: ",$obj.TargetFile
        Write-Host $_
    }
}