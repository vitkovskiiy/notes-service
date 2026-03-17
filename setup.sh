#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Будь ласка, запустіть скрипт з правами root (sudo ./setup.sh)"
  exit 1
fi

echo "=== Початок налаштування сервера за ТЗ ==="


echo "Встановлення пакетів..."
apt-get update
apt-get install -y nginx nodejs npm postgresql git openssl


echo "Створення користувачів та налаштування прав..."
ENCRYPTED_PASS=$(openssl passwd -6 12345678)


useradd -m -s /bin/bash -p "$ENCRYPTED_PASS" student
useradd -m -s /bin/bash -p "$ENCRYPTED_PASS" teacher
useradd -m -s /bin/bash -p "$ENCRYPTED_PASS" operator


usermod -aG sudo student
usermod -aG sudo teacher


chage -d 0 student
chage -d 0 teacher
chage -d 0 operator


useradd -r -s /usr/sbin/nologin app


echo "Налаштування обмеженого sudo для operator..."
cat <<EOF > /etc/sudoers.d/operator
operator ALL=(ALL) /usr/bin/systemctl start mywebapp.service, /usr/bin/systemctl stop mywebapp.service, /usr/bin/systemctl restart mywebapp.service, /usr/bin/systemctl status mywebapp.service, /usr/bin/systemctl start mywebapp.socket, /usr/bin/systemctl stop mywebapp.socket, /usr/bin/systemctl restart mywebapp.socket, /usr/bin/systemctl status mywebapp.socket, /usr/bin/systemctl reload nginx
EOF
chmod 440 /etc/sudoers.d/operator


echo "Налаштування PostgreSQL..."
sudo -u postgres psql -c "CREATE DATABASE mywebapp;"
sudo -u postgres psql -c "CREATE USER student_db WITH PASSWORD 'db_password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE mywebapp TO student_db;"


echo "Клонування репозиторію та встановлення залежностей..."
APP_DIR="/var/www/webapp"
mkdir -p $APP_DIR

git clone "https://github.com/vitkovskiiy/task-tracker.git" /tmp/repo
cp -r /tmp/repo/* $APP_DIR/
rm -rf /tmp/repo

cd $APP_DIR


echo 'DATABASE_URL="postgresql://student_db:db_password@localhost:5432/mywebapp?schema=public"' > .env


npm config set fetch-retry-mintimeout 20000
npm config set fetch-retry-maxtimeout 120000
npm config set registry http://registry.npmjs.org/

npm install

chown -R app:app $APP_DIR


echo "Налаштування Systemd"

cat <<EOF > /etc/systemd/system/mywebapp.socket
[Unit]
Description=MyWebApp Socket

[Socket]
ListenStream=8000

[Install]
WantedBy=sockets.target
EOF

cat <<EOF > /etc/systemd/system/mywebapp.service
[Unit]
Description=MyWebApp Service
After=network.target
Requires=mywebapp.socket

[Service]
Environment=NODE_ENV=production
Environment=PORT=8000
Type=simple
User=app
WorkingDirectory=$APP_DIR

ExecStartPre=/usr/bin/npx prisma generate
ExecStartPre=/usr/bin/npx prisma db push --accept-data-loss

ExecStart=/usr/bin/node server.js
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now mywebapp.socket

echo "Налаштування Nginx..."
cat <<EOF > /etc/nginx/sites-available/mywebapp
server {
    listen 80;
    server_name _;

    access_log /var/log/nginx/mywebapp_access.log;
    error_log /var/log/nginx/mywebapp_error.log;

    location = / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
    }

    location /tasks {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
    }

}
EOF

ln -s /etc/nginx/sites-available/mywebapp /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

echo "Блокування ..."
if id "app" &>/dev/null; then
    usermod -L app
    usermod -s /usr/sbin/nologin app
fi

echo "=== Налаштування успішно завершено! ==="