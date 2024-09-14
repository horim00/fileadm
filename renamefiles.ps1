using namespace System.Collections.Generic
#tab  split
#parameter
param(# Parameter help description
[Parameter(Mandatory=$true)]
    [string] $listfile,
[Parameter(Mandatory=$false)]
[Int32] $kubun=0
)
    
$list = [List[PSCustomObject]]::new()
#Hash {Directive,how many times the directive occurres}like {書誌,0][提示文献,2][図面,0]]
$DirectiveHash =@{}
#count target file , start from 1
$TargetFileNumHash=@{}
#Start number for TargetFile
# if TargetFileNumBaseHash{"提示文献"} is 4
#then the number goes 04_提示文献,05_提示文献,,,,,
$TargetFileNumBaseHash=@{}
$DirectiveOrder=[List[string]]::new()

$my_file = Get-Content $listfile
#read file and store
Foreach ($my_string  in $my_file) {
    #split into variable 
    $one, $two,$three = $my_string.split(",")
    $list.Add([pscustomobject]@{FName=$one
        Directive=$two
        TargetFile=""
        } )
        #
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
foreach ($obj in $list)
{
    Write-Host $obj.FName
    Write-Host $obj.Directive
}
Write-Host $DirectiveHash
Write-Host "区分 $kubun"

$count = 0
$filename=""
foreach ($obj in $list)
{
    if ($kubun -eq 8)
    {
        if ($obj.FName  -match "_")
        {
            $filename =     ($obj.FName -split "_")[-1]
        }
        else
        {
            $filename = $obj.FName
        } 
    }

    # if directive appears once, no need to generate directive number string
    if ($DirectiveHash[$obj.Directive] -eq 0)
    {
        $count++
#        $countString = $count.ToString("00")
        if (($kubun -eq 8 ) -and  ($obj.Directive  -match "提示文献"))
        {
            $obj.TargetFile = $count.ToString("00")+ "_" + $obj.Directive+"_"+$filename    
        }
        else {
            $obj.TargetFile = $count.ToString("00")+ "_" + $obj.Directive+".pdf"
        }
    }
    else {
        if ($TargetFileNumHash.ContainsKey($obj.Directive))
        {
            #count up target file number for the directive
            $TargetFileNumHash[$obj.Directive]++
        }
        else {
            #set number for the directive to "1"
            $TargetFileNumHash.Add($obj.Directive, 1)
            $count++
            $TargetFileNumBaseHash.Add($obj.Directive, $count)
            #increment the number by the number of directive occrrence
            $count = $count  + $DirectiveHash[$obj.Directive] 
        }
        # total number = base + count for the directive
        $totalnum = $TargetFileNumBaseHash[$obj.Directive] + $TargetFileNumHash[$obj.Directive] - 1
        if (($kubun -eq 8 ) -and  ($obj.Directive  -match "提示文献"))
        {
            $obj.TargetFile = $totalnum.ToString("00")  + "_"  + $obj.Directive + $TargetFileNumHash[$obj.Directive].ToString()+"_"+$filename
        }
        else {
            $obj.TargetFile = $totalnum.ToString("00")  + "_"  + $obj.Directive + $TargetFileNumHash[$obj.Directive].ToString()+".pdf"
        }
    }
}

foreach ($obj in $list)
{

    Rename-Item -Path $obj.FName -NewName $obj.TargetFile

    Write-Host "rename  $obj"
#    Write-Host $obj.FName
 #   Write-Host $obj.Directive
 #   Write-Host $obj.TargetFile
}