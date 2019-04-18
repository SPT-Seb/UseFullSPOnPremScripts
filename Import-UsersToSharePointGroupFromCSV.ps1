<#
.SYNOPSIS
    Import all users from a CSV file into SharePoint OnPremise group.
.DESCRIPTION
    Using current user permissions to reach SharePoint site collection (owner on groups or site collection admin permissions requested).
.NOTES
    File Name      : Import-UsersToSharePointGroupFromCSV.ps1
    Author         : Sebastien Paulet (@SP_twit) mainly reusing Juan Carlos Gonzalez's PS_AddUserToSharePointGroup_CSOM.ps1
    Prerequisite   : .Net v4 + Microsoft.SharePoint.Client.dll and Microsoft.SharePoint.Client.Runtime.dll
.PARAMETER SourceCSVFileFullPath
    Full path to the CSV filte containing data
.PARAMETER TargetSPSiteCollURL
    URL to the target site collection
.PARAMETER CSVDelimiter
    Delimiter used in CSV file (';' by default)
.PARAMETER CSVHeaderUserDomainLabel
    Label used file for column containing User Domain in CSV ('UserDomain' by default)
.PARAMETER CSVHeaderUserNameLabel
    Label used file for column containing User Name in CSV ('UserName' by default)
.PARAMETER CSVHeaderSPGroupNameLabel
    Label used file for column containing SharePoint Group Name in CSV ('SPGroupName' by default)
.PARAMETER CSOMDllPath ('.' by default)
    Folder path contaning CSOM dll
.EXAMPLE
    .\Import-UsersToSharePointGroupFromCSV.ps1 .\userToImport.csv "https://mysharepointdomain/sites/mycollection/"
#>
param(
    [Parameter(Mandatory = $true)]
    [String]$SourceCSVFileFullPath,
    [Parameter(Mandatory = $true)]
    [String]$TargetSPSiteCollURL,
    [String]$CSVDelimiter = ';',
	[String]$CSVHeaderUserDomainLabel = 'UserDomain',
	[String]$CSVHeaderUserNameLabel = 'UserName',
	[String]$CSVHeaderSPGroupNameLabel = 'SPGroupName',
	[String]$CSOMDllPath = '.'
)

#Load CSOM Assemblies        
Add-Type -Path "$CSOMDllPath\Microsoft.SharePoint.Client.dll"
Add-Type -Path "$CSOMDllPath\Microsoft.SharePoint.Client.Runtime.dll"

$spCtx = New-Object Microsoft.SharePoint.Client.ClientContext($TargetSPSiteCollURL)  
#Load site collection's  Groups                
$spGroups=$spCtx.Web.SiteGroups
$spCtx.Load($spGroups)    
 
Import-CSV -delimiter $CSVDelimiter -path $SourceCSVFileFullPath | foreach {
	try
    {
		$spGroup=$spGroups.GetByName($_.$CSVHeaderSPGroupNameLabel);
        $spCtx.Load($spGroup)   
        $spUser = $spCtx.Web.EnsureUser("i:0#.w|$($_.$CSVHeaderUserDomainLabel)\$($_.$CSVHeaderUserNameLabel)")
        $spCtx.Load($spUser)
        $spUserToAdd=$spGroup.Users.AddUser($spUser)
        $spCtx.Load($spUserToAdd)
        $spCtx.ExecuteQuery()   
		Write-Host "User $($_.$CSVHeaderUserDomainLabel)\$($_.$CSVHeaderUserNameLabel) imported in $($_.$CSVHeaderSPGroupNameLabel)" -foregroundcolor Green
    }
    catch
    {
        Write-Host $_.Exception.ToString() -foregroundcolor Red
    } 	
}

$spCtx.Dispose()