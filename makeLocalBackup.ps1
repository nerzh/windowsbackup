$date = Get-Date
$fdate = $((Get-Date).ToString('yyyy-MM-dd'))
$logs = "D:\backup\$env:COMPUTERNAME_WEEKLYBACKUP$fdate.txt"
Start-Transcript -path $logs

Import-Module WebAdministration

Write-Host "Start backup"
$localPath = "D:\backup\data\net\"
$localPathIss = "D:\backup\data\iis\"

if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) {echo "7ZIP needed"}
set-alias sz "$env:ProgramFiles\7-Zip\7z.exe"

$NETDIR="D:\net\"

Remove-Item -path D:\backup\data\net\net.zip
Remove-Item -path D:\backup\data\net\iis.zip

#Here you can delete old archive instead of deleting D-1 backup (erase two previous lines, and uncomment three next lines)
#$limit = (Get-Date).AddDays(-8)
#Write-Host "Deleting old files"
#Get-ChildItem -Path $localPath -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force


#Début de l'archivage des données et des sites IIS
$f = "IIS" + $fdate
$dest = $Path2
Backup-WebConfiguration -Name $f
Copy-Item $env:windir\system32\inetsrv\backup\$f $dest -recurse
Copy-Item $env:windir\system32\inetsrv\backup\$f $localPathIss -recurse

Write-Host "IIS and Website data"
$d2 = $localPath + "net.zip"
$d3= $localPath + "iis.zip"

sz a $d2 -mm=Copy -xr!"excludedFolder" -mx0 -r $NETDIR
sz a $d3 -mm=Copy -mx0 -r $localPathIss

#Sending mail
Write-Host "Sending mail"

$SMTPServer = "smtp.mysmtp.com"
$SMTPPort = "587"
$Username = "mymail@mydomain.com"
$Password = Get-Content "D:\Security\password.txt"
$to = "targetmail@mydomain.com"

$style = "<style> 
			body {font-family: Century Gothic; font-size: 10pt;} 
			TABLE{border: 2px solid black; border-collapse: collapse;} 
			TH{border: 2px solid black; background: #4246CA; padding: 15px;} 
			TD{border: 2px solid black; padding: 15px;} 
		</style>"

Function Get-FormattedNumber($size)
{
  IF($size -ge 1GB)
   {
      "{0:n2}" -f  ($size / 1GB) + "GB"
   }
 ELSEIF($size -ge 1MB)
    {
      "{0:n2}" -f  ($size / 1MB) + "MB"
    }
 ELSE
    {
      "{0:n2}" -f  ($size / 1KB) + "KB"
    }
}
		
if(test-path $localPath){
	$i = (Get-CHildItem $localPath | Measure-Object).Count;
	$arch = Get-ChildItem $localPath | where {! $_.PSIsContainer}| Select-Object Name, {Get-FormattedNumber($_.Length)}, Lastwritetime | ConvertTo-Html -head $style
	
		$subject = "[Backup FOLDER - myserver] data type backup"
		$body = $arch
}
else {
	$subject = "[Backup FOLDER - myserver] data type backup"
	$body = "Done : $date Path incorrect : $localPath"
}


$message = New-Object System.Net.Mail.MailMessage
$message.subject = $subject
$message.body = $body
$message.IsBodyHTML = $true
$message.to.add($to)
$message.from = $username

$smtp = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort);
$smtp.EnableSSL = $true
$smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password);
$smtp.send($message)

Write-Host "End of backup, check your mail"

Stop-Transcript