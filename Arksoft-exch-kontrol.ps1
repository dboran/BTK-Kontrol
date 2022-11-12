#written by boran@arksoft.com.tr on 25.10.2022
#ARksoft musterileri icin USom'un exchange webshell sızıntıları icin uyarı epostasına istinaden yazıldı.

Write-host "Bu script exchange binary'leri icinde potansiyel webshell arayacaktır!" -foregroundcolor Green
Write-host "Keyword ve dosya isimleri usom epostasindan alinmistir!" -ForegroundColor Green
Write-Host "Destek icin destek@arksoft.com.tr" -ForegroundColor Green
Write-host ""
Write-Host "Aranacak klasor ve dosya sayıları" -ForegroundColor Yellow

$malfiles=Get-Content ".\usomlist.txt" #usomun gonderdigi potansiyel malware listesi
$report=@()
$bulunanlar=@()

#region extension
$extensions=@()
Foreach($path in $malfiles) {
    [string]$ext="*." + ($path.Split("."))[-1] 
    $extensions+=$ext 
}
$extensions = $extensions | select -Unique
#endregion


#region find files in exchanageinstallpath
$rootFolderPath = $env:ExchangeInstallPath
$iisrootpath="$env:SystemDrive\inetpub\wwwroot"
$folders=@("Bin","ClientAccess","FrontEnd")
$farray=@()

Foreach($folder in $folders) {
    $path = $rootFolderPath +"\" + "$folder"
    If(Test-Path -Path $path) {
        $flist= Get-ChildItem $path -Recurse  -Include $extensions -File
        Write-host `t $folder `t $flist.count -ForegroundColor Yellow
        $farray+= $flist
    }
}
#endregion

#region add inetpub files
$path = $iisrootpath
$flist= Get-ChildItem $path -Recurse -Include $extensions -File 
        Write-host `t $path `t $flist.count -ForegroundColor Yellow
$farray+= $flist
#endregion

#region arama
#region dosya isminine gore arama
#burada panik yapmayin, bazi dosya isimleri exchange'in dosya isimleri.
Write-host "USOM dosya isimleri araniyor" -ForegroundColor Yellow
Foreach($file in $malfiles) {
    $filename=($file.Split("/"))[-1]
    IF ($filename -in $farray.name ) {
        Write-host `t $filename " isimli dosya mevcut" -ForegroundColor Yellow
        $bulgu=$farray | Where {$_.NAme -eq $filename}
        $bulunanlar+=$bulgu

    } 
    Else {
        #Write-Host $file " bulunamadi" -ForegroundColor Green
     }
}

#endregion

#region keyword arama
#burada bulgu cikarsa panik yapin
#usom'un gonderdigi keyword'lerdir
Write-Host "Bulunan dosyalar icinde keyword'ler arasitiriliyor.. " -ForegroundColor Yellow

$arast=@("%eval",
    "{eval",
    "Request.Item[",
    "Request.Form[",
    'StartInfo.FileName="cmd.exe";',
    'StartInfo.FileName= "cmd" + "." + "exe"'
    )

Foreach($bulgu in $bulunanlar) 
 {
        Foreach($arastring in $arast) {
        #Write-Host $arastring " araniyor" -ForegroundColor Yellow
        $sonuc =  findstr /c:"$arastring" $bulgu.FullName

        IF($sonuc) {
        Write-Host `t $sonuc
        Write-Host `t $bulgu.FullName `t $arastring " bulundu" -ForegroundColor red
        $ent="" | select DosyaAdi,BulunanString
        $ent.DosyaAdi=$bulgu.FullName
        $ent.BulunanString=$arastring
        $report+=$ent


  }
  }

}
#endregion
#endregion

IF($report) {
$report | Export-Csv .\USOM-Bulgu-Kurumadi.csv -Encoding UTF8
Write-Host " Kontak USOM Acil!!" -ForegroundColor red -BackgroundColor Yellow
Write-host " Bulgular .\USOM-Bulgu-Kurumadi.csv dosyasina cikarildi" -ForegroundColor red -BackgroundColor Yellow

}
Else {
Write-host "Herhangi bir USOM bulgusu bulunamadi! Ama gene de tetikte ol!!" -ForegroundColor Green
 }


