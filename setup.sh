#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Будь ласка, запустіть скрипт з правами root (sudo ./setup.sh)"
  exit
fi

echo "=== Start to config server ==="

echo "Downloads packages..."
apt-get update
apt-get install -y nginx nodejs npm postgresql git


echo "Creating users..."

ENCRYPTED_PASS=$(openssl passwd -6 12345678)
useradd -m -s /bin/bash -p "$ENCRYPTED_PASS" student
useradd -m -s /bin/bash -p "$ENCRYPTED_PASS" teacher
useradd -m -s /bin/bash -p "$ENCRYPTED_PASS" operator

chage -d 0 student
chage -d 0 teacher
chage -d 0 operator

echo "Create gradebook..."
echo "3" > /home/student/gradebook
chown student:student /home/student/gradebook
chmod 644 /home/student/gradebook

echo "Налаштування бази даних..."
sudo -u postgres psql -c "CREATE DATABASE mywebapp;"
sudo -u postgres psql -c "CREATE USER student_db WITH PASSWORD 'db_password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE mywebapp TO student_db;"


echo "Налаштування директорії застосунку..."
APP_DIR="/var/www/webapp"
mkdir -p $APP_DIR
git clone "https://github.com/vitkovskiiy/task-tracker.git" /tmp/repo
cp -r /tmp/repo/* $APP_DIR/
rm -rf /tmp/repo
cd $APP_DIR
npm install
chown -R student:student $APP_DIR

echo "Налаштування systemd..."
cat <<EOF > /etc/systemd/system/mywebapp.service
[Unit]
Description=MyWebApp
After=network.target

[Service]
Environment=NODE_ENV=production
Environment=PORT=8000
Type=simple
User=student
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/node server.js
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mywebapp.service
systemctl start mywebapp.service


echo "Налаштування Nginx..."
cat <<EOF > /etc/nginx/sites-available/mywebapp
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

ln -s /etc/nginx/sites-available/mywebapp /etc/nginx/sites-enabled/
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