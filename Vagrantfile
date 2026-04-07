Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.provider "virtualbox" do |vb|
    vb.name = "MyWebApp_Notes_Service"
    vb.memory = "1024"
    vb.cpus = 1
  end

  config.vm.provision "shell", inline: <<-SHELL
    echo "=== Запуск автоматичного розгортання ==="
    wget -q https://raw.githubusercontent.com/vitkovskiiy/notes-service/main/setup.sh -O /tmp/setup.sh
    chmod +x /tmp/setup.sh
    sudo /tmp/setup.sh
  SHELL
end