Vagrant.configure("2") do |config|
  config.vm.box = "archlinux/archlinux"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
  end
  
  config.vm.define "archlinux" do |archlinux|
    archlinux.vm.hostname = "localhost"
  end

  config.vm.synced_folder "./", "/vagrant"

  # config.vm.provision "shell", path: "bootstrap.sh"

end

