using namespace System.Collections.Generic
#tab  split
#parameter
param(# Parameter help description
[Parameter(Mandatory=$true)]
    [string] $list,
[Parameter(Mandatory=$false)]
[Int32] $kubun=0,
[Parameter(Mandatory=$false)]
[Int32] $start=0
)

$objlist = [List[PSCustomObject]]::new()
#Hash {Directive,how many times the directive occurres}like {書誌,0][提示文献,2][図面,0]]
$DirectiveHash =@{}
#count target file , start from 1
$TargetFileNumHash=@{}
#Start number for TargetFile
# if TargetFileNumBaseHash{"提示文献"} is 4
#then the number goes 04_提示文献,05_提示文献,,,,,
$TargetFileNumBaseHash=@{}
$DirectiveOrder=[List[string]]::new()

$my_file = Get-Content $list
#read file and store
Foreach ($my_string  in $my_file) {
    #split into variable 
    $one, $two,$three = $my_string.split(",")
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
foreach ($obj in $objlist)
{
    Write-Host $obj.FName
    Write-Host $obj.Directive
}
Write-Host $DirectiveHash
Write-Host "区分 $kubun"
Write-Host "開始 $start"

$count = $start
$filename=""
foreach ($obj in $objlist)
{
     if ($obj.FName  -match "_提示文献 \d+_(.*)$")
    {
        #pick filename from dd_提示文献n_filename 
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
            if (($kubun -eq 8 ) -and  ($obj.Directive  -match "提示文献"))
        {
            #kubun 8 only:  dd_提示文献_filename
            $obj.TargetFile = $count.ToString("00")+ "_" + $obj.Directive+"_"+$filename    
        }
        else {
            #otherwise dd_提示文献n
            $obj.TargetFile = $count.ToString("00")+ "_" + $obj.Directive+".pdf"
        }
    }
    else {
        #count up Directive eg, 提示文献1, 提示文献2
        if ($TargetFileNumHash.ContainsKey($obj.Directive))
        {
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
        
        if (($kubun -eq 8 ) -and  ($obj.Directive  -match "提示文献"))
        {
            #区分８アミューズメント仕様  \d\d_提示文献N_文献番号.pdf
            $obj.TargetFile = $totalnum.ToString("00")  + "_"  + $obj.Directive + $TargetFileNumHash[$obj.Directive].ToString()+"_"+$filename
        }
        else {
            # \d\d_DirectiveN.pdf
            $obj.TargetFile = $totalnum.ToString("00")  + "_"  + $obj.Directive + $TargetFileNumHash[$obj.Directive].ToString()+".pdf"
        }
    }
}

foreach ($obj in $objlist)
{
    try {
       Move-Item -Path $obj.FName -Destination $obj.TargetFile  -Force
    }
    catch {
        Write-Host "rename file failed"
        Write-Host $_
    }
}