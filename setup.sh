#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Будь ласка, запустіть скрипт з правами root (sudo ./setup.sh)"
  exit
fi

echo "=== Start to config server ==="

echo "Встановлення пакетів..."
apt-get update
#download all dependencies
apt-get install -y nginx nodejs npm postgresql


echo "Створення користувачів..."
#create users 
useradd -m -s /bin/bash student
useradd -m -s /bin/bash teacher
useradd -m -s /bin/bash operator

echo "student:student123" | chpasswd
echo "teacher:teacher123" | chpasswd
echo "operator:operator123" | chpasswd


echo "Створення файлу gradebook..."
echo "3" > /home/student/gradebook
chown student:student /home/student/gradebook
chmod 644 /home/student/gradebook

echo "Налаштування бази даних..."
sudo -u postgres psql -c "CREATE DATABASE web_platform;"
sudo -u postgres psql -c "CREATE USER student_db WITH PASSWORD 'db_password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE web_platform TO student_db;"


echo "Налаштування директорії застосунку..."
APP_DIR="/var/www/webapp"
mkdir -p $APP_DIR

cp -r ./src/* $APP_DIR/
cd $APP_DIR
npm install


chown -R student:student $APP_DIR

echo "Налаштування systemd..."
cat <<EOF > /etc/systemd/system/webapp.service
[Unit]
Description=My Express Web App
After=network.target

[Service]
Environment=NODE_ENV=production
Environment=PORT=3000
Type=simple
User=student
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/node server.js
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable webapp.service
systemctl start webapp.service


echo "Налаштування Nginx..."
cat <<EOF > /etc/nginx/sites-available/webapp
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

ln -s /etc/nginx/sites-available/webapp /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

echo "Блокування дефолтного користувача..."

DEFAULT_USER="ubuntu" 
if id "$DEFAULT_USER" &>/dev/null; then
    usermod -L $DEFAULT_USER 
    usermod -s /usr/sbin/nologin $DEFAULT_USER 
    echo "Користувач $DEFAULT_USER заблокований."
fi

echo "=== Налаштування завершено успішно! ==="