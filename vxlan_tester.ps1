param(
    $vcenters=@('vCenter01', 'vCenter02', 'vCenter03', 'vCenter04')
	)

$ROOT = split-path -Parent $PSScriptRoot
. "$ROOT\utils\util.ps1"

disconnectvcs
connectvcs $vcenters

$rpt = get-vmhost -location *zone* | sort -property connectionstate, name | % { 
	$dvswitch = get-vdswitch -name "*-1-dvSwitch1"
	$z = get-esxcli -VMHost $_
	$result = 'Success'
	try {
		$a = $z.network.vswitch.dvs.vmware.vxlan.vmknic.list($null, $dvswitch.name)
		if ($a.count -eq 0) {
			$result = 'No vxlan vmknic'
		} elseif ($a.ip.startswith('169')) {
			$result = 'Missing vtep ip address'
		}
	}
	catch {
		$result = $Error[0].exception.message
	}
	[PSCustomObject]@{	
		"vmhost"= $_.name;
		"connectionstate" = $_.connectionstate;
		"result" = $result;
	}
}

disconnectvcs
$rpt | ft -autosize
