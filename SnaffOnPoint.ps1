<#
.SYNOPSIS
Searches through On-Prem SharePoint for sensitive files and data
#>

param (
    [string] $Domain
)
# Check required params
if ([string]::IsNullOrEmpty($required_param)) {
    Write-Host "Set the Sharepoint domain `n"
    Write-Host "Usage: .\SnaffOnPoint.ps1 DOMAIN"
    exit 1;
}



$Keywords = "id_rsa","id_dsa","id_ecdsa","id_ed25519", ".bash_history",".zsh_history",".sh_history","zhistory",".irb_history","ConsoleHost_History.txt", "database.yml",".secret_token.rb","knife.rb","carrerwave.rb","omiauth.rb", "mobaxterm.ini","mobaxterm backup.zip","confCons.xml", "mysql.connector.connect","psycopg2.connect", "-SecureString","-AsPlainText","Net.NetworkCredential", "mysql_connect","mysql_pconnect","mysql_change_user","pg_connect","pg_pconnect", "running-config.cfg","startup-config.cfg","running-config","startup-config", "NVRAM config last updated","simple-bind authenticated encrypt","pac key","snmp-server community", "MEMORY.DMP","hiberfil.sys","lsass.dmp","lsass.exe.dmp", "credentials.xml","jenkins.plugins.publish_over_ssh.BapSshPublisherPlugin.xml","getConnection*", "jdbc:", ".git-credentials", "recentservers.xml","sftp-config.json", "SqlStudio.bin",".mysql_history",".psql_history",".pgpass",".dbeaver-data-sources.xml","credentials-config.json","dbvis.xml","robomongo.json", "connectionstring*", "passw*","password","pass","passw","passwd","secret","key","credential", "user","username","login", "schtasks", "X-Amz-Credential", "aws_key", "awskey", "aws.key", "aws-key", "*aws*", "AKIA*", "AGPA*", "AIPA*", "AROA*", "ANPA*", "ANVA*", "ASIA*", "CF-Access-Client-Secret"
foreach ($Keyword in $Keywords) {
    # Get all Results for the Keyword
    $link = "https://" + $Domain + "/_api/search/query?querytext=%27" + $Keyword + "%27&rowlimit=1000&selectproperties=%27Path,HitHighlightedSummary%27"
    $Results = (iwr -uri $link -UseDefaultCredentials).Content
    $Formatted_Results = Format-XmlToText $Results

    $patternPath = '<d:Key>Path<\/d:Key>\s*<d:Value>(.*?)<\/d:Value>'
    $patternHighlight = '<d:Key>HitHighlightedSummary<\/d:Key>\s*<d:Value(?: xml:space="preserve")?>((?:\s|.)*?)<\/d:Value>'
    # Extract the values using regex
    $Pathmatches = [regex]::Matches($Formatted_Results, $patternPath)
    $Hightlightmatches = [regex]::Matches($Formatted_Results, $patternHighlight)
    
    if ($Hightlightmatches.Count -ne $Pathmatches.Count) {
        throw "Sharepoint fucked something up"
    }


    for ($i = 0; $i -lt $Pathmatches.Count; $i++) {
        $firstValue = $Pathmatches[$i].Groups[1].Value
        $secondValue = $Hightlightmatches[$i].Groups[1].Value

        # Show the Location and the highlighted sentence
        Write-Host "----------------------------------------------------------"
        Write-Host "Found $Keyword at: $firstValue `n" -ForegroundColor Green
        Write-Host "Hightlight: $secondValue" -ForegroundColor Red
        Write-Host "----------------------------------------------------------"
    }
}
