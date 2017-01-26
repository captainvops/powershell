param(
    [parameter(Mandatory=$true)] $vms,
    [parameter(Mandatory=$true)] $name
	)

$vms = get-vm -name $vms

foreach($vm in $vms) {
    $snap = get-Snapshot -vm $vm -name $name
    write-host "removing snapshot $snap.name for $vm.name"
    remove-snapshot -snapshot $snap -confirm:$false -runasync:$true
}
