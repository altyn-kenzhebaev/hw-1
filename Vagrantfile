# -*- mode: ruby -*-
# vim: set ft=ruby :

# Описываем Виртуальные машины
MACHINES = {
  # Указываем имя ВМ "kernel update"
  :"kernel-update" => {
              #Какой vm box будем использовать
              :box_name => "altynkenzhebaev/centos8-kernel6",
              #Указываем box_version
              :box_version => "1.0",
              #Указываем количество ядер ВМ
              :cpus => 4,
              #Указываем количество ОЗУ в мегабайтах
              :memory => 4096,
            }
}

Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
    # Отключаем проброс общей папки в ВМ
    config.vm.synced_folder ".", "/vagrant", disabled: false
    config.disksize.size = '50GB'
    # Применяем конфигруацию ВМ
    config.vm.define boxname do |box|
      box.vm.box = boxconfig[:box_name]
      box.vm.box_version = boxconfig[:box_version]
      box.vm.host_name = boxname.to_s
      box.vm.provider "virtualbox" do |v|
        v.memory = boxconfig[:memory]
        v.cpus = boxconfig[:cpus]
      end
      box.vm.provision "shell", reboot: true, inline: <<-SHELL
	      echo -e 'Yes\n100%' | sudo parted ---pretend-input-tty /dev/sda resizepart 1 100%
        xfs_growfs /dev/sda1
	      /vagrant/kernel_update.sh
      SHELL
    end
  end
end
