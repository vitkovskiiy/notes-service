Vagrant.configure("2") do |config|
  # Використовуємо офіційний базовий образ Ubuntu 24.04 LTS
  config.vm.box = "ubuntu/jammy64"

  # Прокидаємо 80-й порт (Nginx) зсередини ВМ на порт 8080 вашого хоста
  # Це дозволить вам тестувати сервіс прямо у браузері через http://localhost:8080
  config.vm.network "forwarded_port", guest: 80, host: 8080

  # Налаштування ресурсів для VirtualBox
  config.vm.provider "virtualbox" do |vb|
    vb.name = "MyWebApp_Notes_Service"
    vb.memory = "1024"
    vb.cpus = 1
  end

  # Автоматичне розгортання: завантажуємо і запускаємо ваш setup.sh з GitHub
  config.vm.provision "shell", inline: <<-SHELL
    echo "=== Запуск автоматичного розгортання ==="
    # Важливо: якщо у вас інша гілка, замініть main на master
    wget -q https://raw.githubusercontent.com/vitkovskiiy/notes-service/main/setup.sh -O /tmp/setup.sh
    chmod +x /tmp/setup.sh
    sudo /tmp/setup.sh
  SHELL
end