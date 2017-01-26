param(
    [parameter(Mandatory=$true)] $vms,
    [parameter(Mandatory=$true)] $name
	)

$vms = get-vm -name $vms

foreach($vm in $vms) {
    write-host "creating snapshot $name for $vm.name"
    $snap = New-Snapshot -vm $vm -name $name -confirm:$false -runasync:$true
}
