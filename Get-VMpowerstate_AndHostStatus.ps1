
<#
Script name: Get-VMpowerstate_AndHostStatus.ps1
Created on: 09/18/2016
Author: Cory Barker, aka CaptainvOps, @corybark3r
Description: Collects powerstate of VMs, which host they are running on, the VM IP and cluster.  Writes output to CSV. Creates WIN system event log based on completion, and will delete said CSV after 7 days. This was designed to be an automated task.
===Tested Against Environment====
vSphere Version: 5.5.0.2442329
PowerCLI Version: PowerCLI 5.8
PowerShell Version: 5.8
OS Version: Windows 10/2008R2
#>

#variables
$vCenter = @()
$sites = @("vcenter01","vcenter02","vcenter03","vcenter04")

#get array of sites and establishes connections to vcenters
foreach ($site in $sites) {
  	$vCenter = $site + ".domainname.net"
	
  	Connect-VIServer $vCenter 

	$vmhosts=get-view -ViewType hostsystem -Property name,parent
	$hostshash=@{}
	$vmhosts|%{$hostshash.Add($_.moref.toString(),$_.name)}
	$clusters=get-view -viewtype ClusterComputeResource -Property name
	$clustershash=@{}
	$clusters|%{$clustershash.Add($_.moref.toString(),$_.name)}
	$hoststoclusterhash=@{}
	$vmhosts|%{$hoststoclusterhash.add($_.moref.toString(),$clustershash.($_.Parent.ToString()))}
	$vms=get-view -viewtype virtualmachine -property name, runtime.host, runtime.powerstate, guest.hostname, guest.net
	$report = $vms | % {
	 $ips = @()
	 $_.guest.net.ipaddress | % {
	   if ($_) {
	     $ips += $_
	   }
	 }

	 [PSCustomObject]@{
	   "Host" = $hostshash.($_.Runtime.Host.ToString())
	   "Cluster" = $hoststoclusterhash.($_.Runtime.Host.ToString())
	   "Name" = $_.name
	   "DNS Host Name" = $_.guest.hostname
	   "Power State" = $_.runtime.powerstate
	   "Ip Addresses" = $ips -join ', '
	 }
	}
	#send output to csv and disconnect from vcenter
	$report | sort Host | export-csv -path "C:\path\to\output\$site $((Get-Date).ToString('MM-dd-yyyy_hhmm')).csv" -NoTypeInformation -UseCulture
	
	Disconnect-VIServer -Force -Confirm:$false -Server $c_vCenter
	
	<#
	Write event log on completetion per site.  
	note: if running for first time you will need to run powershell as administrator and run command 'Write-EventLog -LogName Application -Get-VMpowerstate_AndHostStatus -EventId ### -EntryType Information -Message "Get-VMpowerstate_AndHostStatus for vCenter $site completed successfully." ' Change ### to a number that suits your needs.
	#>
	
	Write-EventLog -LogName Application -Source name_of_script -EventId ### -EntryType Information -Message "Get-VMpowerstate_AndHostStatus for vCenter $site completed successfully."
}

#Cleanup old csv after 7 days.  Delete files older than the limit
$limit = (Get-Date).AddDays(-7)
$path = "c:\path\to\output\"
Get-ChildItem -Path $path -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force
