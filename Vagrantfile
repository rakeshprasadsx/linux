# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  # Build Server connects to this host to perform deployment
  config.vm.define 'target' do |target|
    # Oracle VirtualBox with private NAT has insecure deployer keys for desktop testing
    target.vm.provider 'virtualbox' do |virtualbox, override|
      override.vm.network 'private_network', ip: '172.16.17.102'
      override.vm.box = 'bento/centos-7.1'
      override.vm.network 'forwarded_port', guest: 22, host: 20022
      override.vm.network 'forwarded_port', guest: 80, host: 20080
      override.vm.provision 'shell', path: 'automation/provisioning/deployer.sh', args: 'target'
    end
    # Microsoft Hyper-V does not support NAT or setting hostname. vagrant up target --provider hyperv
    target.vm.provider 'hyperv' do |hyperv, override|
      override.vm.box = 'serveit/centos-7'
    end
    # Provisioninng is the same, regardless of provider
    target.vm.provision 'shell', path: 'automation/provisioning/addUser.sh', args: 'deployer'
    target.vm.provision 'shell', path: 'automation/provisioning/mkDirWithOwner.sh', args: '/opt/packages deployer'
  end
  
  # Build Server, fills the role of the build agent and delivers to the host above
  config.vm.define 'buildserver' do |buildserver|  
    # Oracle VirtualBox with private NAT has insecure deployer keys for desktop testing
    buildserver.vm.provider 'virtualbox' do |virtualbox, override|
      override.vm.network 'private_network', ip: '172.16.17.101'
      override.vm.box = 'bento/centos-7.1'
      override.vm.network 'forwarded_port', guest: 22, host: 10022
      override.vm.provision 'shell', path: 'automation/provisioning/addHOSTS.sh', args: "172.16.17.102 target.sky.net"
      override.vm.provision 'shell', path: 'automation/provisioning/setenv.sh', args: 'environmentDelivery VAGRANT'
      override.vm.provision 'shell', path: 'automation/provisioning/deployer.sh'
      override.vm.provision 'shell', path: 'automation/provisioning/CDAF.sh'
    end
    # Microsoft Hyper-V does not support NAT or setting hostname. vagrant up buildserver --provider hyperv
    buildserver.vm.provider 'hyperv' do |hyperv, override|
      override.vm.box = 'serveit/centos-7'
    end
    # Provisioninng is the same, regardless of provider
  end

end
