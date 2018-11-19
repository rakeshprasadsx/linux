#!/usr/bin/env bash
scriptName='AtlasImage.sh'
imageLog='/VagrantBox.txt'

function writeLog {
	echo "[$scriptName][$(date)] $1"
	sudo sh -c "echo '[$scriptName] $1' >> $imageLog"
}

function executeExpression {
	writeLog "$1"
	eval $1
	exitCode=$?
	# Check execution normal, anything other than 0 is an exception
	if [ "$exitCode" != "0" ]; then
		writeLog "$0 : Exception! $EXECUTABLESCRIPT returned $exitCode"
		exit $exitCode
	fi
}  

function executeIgnore {
	writeLog "$1"
	eval $1
	exitCode=$?
	# Check execution normal, warn if exception but do not fail
	if [ "$exitCode" != "0" ]; then
		writeLog "$0 : Warning! $EXECUTABLESCRIPT returned $exitCode"
	fi
}  

echo; writeLog "--- start ---"
hypervisor=$1
if [ -n "$hypervisor" ]; then
	if [ "$hypervisor" == 'virtualbox' ]; then
		vbadd='5.2.22'
		writeLog "  hypervisor   : $hypervisor (installing extension version ${vbadd})"
	else
		writeLog "  hypervisor   : $hypervisor"
	fi
else
	writeLog "  hypervisor   : (not passed, extension install will not be attempted)"
fi

if [[ $(whoami) != 'vagrant' ]];then
	writeLog "  HALT! Do Not Run as Root or any user other than vagrant, this will apply incorrect permission"; exit 773
else
	writeLog "  whoami       : $(whoami)"
fi

writeLog "As Vagrant user, trust the public key"
if [ -d "$HOME/.ssh" ]; then
	writeLog "Directory $HOME/.ssh already exists"
else
	executeExpression "mkdir $HOME/.ssh"
fi
executeExpression "chmod 0700 $HOME/.ssh"
executeExpression "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ==' > $HOME/.ssh/authorized_keys"
executeExpression "chmod 0600 $HOME/.ssh/authorized_keys"

test=$(sudo cat /etc/ssh/sshd_config | grep UseDNS)
if [ "$test" ]; then
writeLog "Configuration tweek already applied"
else
	writeLog "Configuration tweek"
	writeLog "  sudo sh -c 'echo \"UseDNS no\" >> /etc/ssh/sshd_config'"
	sudo sh -c 'echo "UseDNS no" >> /etc/ssh/sshd_config'
fi
executeExpression "sudo cat /etc/ssh/sshd_config | grep Use"

test=$(sudo cat /etc/sudoers | grep vagrant)
if [ "$test" ]; then
	writeLog "Vagrant sudo permissions already set"
else
	writeLog "Permission for Vagrant to perform provisioning"
	writeLog "  sudo sh -c 'echo \"vagrant ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers'"
	sudo sh -c 'echo "vagrant ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers'
fi
executeExpression "sudo cat /etc/sudoers | grep PASS"

test="`yum --version 2>&1`"
if [[ "$test" == *"not found"* ]]; then
	ubuntu=$(uname -a | grep ubuntu)
	if [ "$ubuntu" ]; then
		writeLog "  Debian based : $(uname -mrs)"
	else
		writeLog "  $(uname -a), Unknown distributation, exiting!"; exit 883
	fi
else
	centos=$(cat /etc/redhat-release | grep CentOS)
	if [ -z "$centos" ]; then
		echo "[$scriptName] Red Hat Enterprise Linux"
		rhel='yes'
	else
		echo "[$scriptName] CentOS Linux : $centos"
	fi
fi

if [ "$hypervisor" == 'hyperv' ]; then
	if [ "$centos" ]; then
		executeExpression "sudo yum update -y"
		sed --in-place --expression='s/^Defaults\s*requiretty/# &/' /etc/sudoers
		executeExpression "sudo cat /etc/sudoers"
	   	executeExpression "sudo yum install -y hyperv-daemons cifs-utils"
		executeExpression "sudo systemctl daemon-reload"
		executeExpression "sudo systemctl enable hypervkvpd"
	else # Ubuntu, from https://oitibs.com/hyper-v-lis-on-ubuntu-16/
		echo;writeLog "Ubuntu extensions are included (from 12.04), but require activation, list before and after"
		executeExpression "sudo cat /etc/initramfs-tools/modules"
		echo
		executeExpression 'sudo sh -c "echo \"hv_vmbus\" >> /etc/initramfs-tools/modules"'
		executeExpression 'sudo sh -c "echo \"hv_storvsc\" >> /etc/initramfs-tools/modules"'
		executeExpression 'sudo sh -c "echo \"hv_blkvsc\" >> /etc/initramfs-tools/modules"'
		executeExpression 'sudo sh -c "echo \"hv_netvsc\" >> /etc/initramfs-tools/modules"'
		echo
		executeExpression "sudo cat /etc/initramfs-tools/modules"
		echo
		executeExpression "sudo apt-get upgrade -y"
		executeExpression "sudo apt-get install -y --install-recommends linux-cloud-tools-$(uname -r)"
		executeExpression "sudo update-initramfs -u"
	fi
else
	if [ "$hypervisor" == 'virtualbox' ]; then
		if [ "$centos" ]; then
			echo;writeLog "Install prerequisites"
			executeExpression "sudo yum update -y"
			sudo sed --in-place --expression='s/^Defaults\s*requiretty/# &/' /etc/sudoers
			executeExpression "sudo cat /etc/sudoers"
			executeExpression "sudo yum groupinstall -y 'Development Tools'"
			executeExpression "sudo yum install -y gcc dkms make bzip2 perl"
			executeExpression "sudo yum install -y kernel-devel-$(uname -r)"
			executeExpression "sudo yum install -y kernel-headers"
			executeExpression "KERN_DIR=/usr/src/kernels/$(uname -r)"
			executeExpression "export KERN_DIR"
			executeExpression "ls $KERN_DIR"
		
		else # Ubuntu
			echo;writeLog "Install prerequisites"
			executeExpression "sudo apt-get upgrade -y"
			executeExpression "sudo apt-get install -y linux-headers-$(uname -r) build-essential dkms"
		fi
		if [ "$centos" ]; then
			echo;writeLog "Fake install for CentOS to try and get this to work"; echo
			fakeadd='5.1.10'
			executeExpression "curl -O http://download.virtualbox.org/virtualbox/${fakeadd}/VBoxGuestAdditions_${fakeadd}.iso"
			executeExpression "sudo mkdir /media/VBoxGuestAdditions"
			executeExpression "sudo mount -o loop,ro VBoxGuestAdditions_${fakeadd}.iso /media/VBoxGuestAdditions"
				
			echo;writeLog "This is normal for server install ..."
			writeLog "  Could not find the X.Org or XFree86 Window System, skipping."; echo
			
			executeExpression "sudo sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run"
			executeExpression "rm VBoxGuestAdditions_${fakeadd}.iso"
			executeExpression "sudo umount /media/VBoxGuestAdditions"
			executeExpression "sudo rmdir /media/VBoxGuestAdditions"
			
		fi
		echo;writeLog "Download and install VirtualBox extensions version $vbadd"; echo
		executeExpression "curl -O http://download.virtualbox.org/virtualbox/${vbadd}/VBoxGuestAdditions_${vbadd}.iso"
		executeExpression "sudo mkdir /media/VBoxGuestAdditions"
		executeExpression "sudo mount -o loop,ro VBoxGuestAdditions_${vbadd}.iso /media/VBoxGuestAdditions"
		executeExpression "sudo sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run"
		executeExpression "rm VBoxGuestAdditions_${vbadd}.iso"
		executeExpression "sudo umount /media/VBoxGuestAdditions"
		executeExpression "sudo rmdir /media/VBoxGuestAdditions"
	fi
fi

if [ "$centos" ]; then
	writeLog "Cleanup"
	executeExpression "sudo yum clean all"
	executeExpression "sudo rm -rf /var/cache/yum"
	executeExpression "sudo rm -rf /tmp/*"
	executeExpression "sudo rm -f /var/log/wtmp /var/log/btmp"
	executeIgnore "sudo dd if=/dev/zero of=/EMPTY bs=1M"
	executeExpression "sudo rm -f /EMPTY"
	executeExpression "sudo sync"
	executeExpression "history -c"
else # Ubuntu
	executeExpression "sudo apt-get autoremove && sudo apt-get clean && sudo apt-get autoclean" 
	executeExpression "sudo rm -r /var/log/*"
	executeExpression "sudo telinit 1"
	executeExpression "sudo mount -o remount,ro /dev/sda1"
	executeExpression "sudo zerofree -v /dev/sda1" 
fi

writeLog "Image complete, shutdown VM"
executeExpression "sudo shutdown -h now"

writeLog "--- end ---"
exit 0
