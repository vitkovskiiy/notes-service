#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Будь ласка, запустіть скрипт з правами root (sudo ./setup.sh)"
  exit 1
fi

echo "=== Початок налаштування сервера (Варіант N=3) ==="

echo "1. Встановлення пакетів..."
apt-get update
apt-get install -y nginx nodejs npm postgresql git openssl

echo "2. Створення користувачів..."
ENCRYPTED_PASS=$(openssl passwd -6 12345678)

id -u student &>/dev/null || useradd -m -s /bin/bash -p "$ENCRYPTED_PASS" student
id -u teacher &>/dev/null || useradd -m -s /bin/bash -p "$ENCRYPTED_PASS" teacher

getent group operator >/dev/null || groupadd operator
id -u operator &>/dev/null || useradd -m -s /bin/bash -p "$ENCRYPTED_PASS" -g operator operator

usermod -aG sudo student
usermod -aG sudo teacher

# Вимога: зміна пароля при першому вході
chage -d 0 student
chage -d 0 teacher
chage -d 0 operator

# Системний користувач mywebapp (згідно ТЗ)
id -u mywebapp &>/dev/null || useradd -r -s /usr/sbin/nologin mywebapp

echo "3. Налаштування sudo для operator..."
cat <<EOF > /etc/sudoers.d/operator
operator ALL=(ALL) NOPASSWD: /usr/bin/systemctl start mywebapp.service, /usr/bin/systemctl stop mywebapp.service, /usr/bin/systemctl restart mywebapp.service, /usr/bin/systemctl status mywebapp.service, /usr/bin/systemctl start mywebapp.socket, /usr/bin/systemctl stop mywebapp.socket, /usr/bin/systemctl restart mywebapp.socket, /usr/bin/systemctl status mywebapp.socket, /usr/bin/systemctl reload nginx
EOF
chmod 440 /etc/sudoers.d/operator

echo "4. Створення gradebook..."
mkdir -p /home/student
echo "3" > /home/student/gradebook
chown student:student /home/student/gradebook
chmod 644 /home/student/gradebook

echo "5. Налаштування PostgreSQL..."
sudo -u postgres psql -c "DROP DATABASE IF EXISTS mywebapp;" 2>/dev/null
sudo -u postgres psql -c "CREATE DATABASE mywebapp;"
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='student_db'" | grep -q 1 || \
sudo -u postgres psql -c "CREATE USER student_db WITH PASSWORD 'db_password';"
sudo -u postgres psql -c "ALTER DATABASE mywebapp OWNER TO student_db;"
sudo -u postgres psql -d mywebapp -c "GRANT ALL ON SCHEMA public TO student_db;"

echo "6. Завантаження коду застосунку..."
APP_DIR="/var/www/mywebapp"
mkdir -p $APP_DIR

# ТУТ ВАЖЛИВО: Замініть URL на ваш репозиторій з файлами Notes Service!
# git clone "https://github.com/vitkovskiiy/mywebapp.git" /tmp/repo
# cp -r /tmp/repo/* $APP_DIR/
# rm -rf /tmp/repo

# Для тестування можна просто скопіювати файли з поточної папки, якщо вони є:
cp -r ./* $APP_DIR/ 2>/dev/null || true

cd $APP_DIR
npm install

chown -R mywebapp:mywebapp $APP_DIR

echo "7. Конфігурація (V2=2)..."
CONFIG_DIR="/etc/mywebapp"
mkdir -p $CONFIG_DIR
echo 'DATABASE_URL="postgresql://student_db:db_password@localhost:5432/mywebapp?schema=public"' > $CONFIG_DIR/config.env
chown -R mywebapp:mywebapp $CONFIG_DIR
chmod 600 $CONFIG_DIR/config.env

echo "8. Налаштування Systemd Socket Activation..."
cat <<EOF > /etc/systemd/system/mywebapp.socket
[Unit]
Description=MyWebApp Socket

[Socket]
ListenStream=8000
NoDelay=true

[Install]
WantedBy=sockets.target
EOF

cat <<EOF > /etc/systemd/system/mywebapp.service
[Unit]
Description=MyWebApp Service (Notes)
After=network.target postgresql.service
Requires=mywebapp.socket

[Service]
Environment=NODE_ENV=production
EnvironmentFile=$CONFIG_DIR/config.env
Type=simple
User=mywebapp
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
systemctl restart mywebapp.service

echo "9. Налаштування Nginx..."
cat <<EOF > /etc/nginx/sites-available/mywebapp
server {
    listen 80;
    server_name _;

    access_log /var/log/nginx/mywebapp_access.log;
    error_log /var/log/nginx/mywebapp_error.log;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
    }
}
EOF

ln -sf /etc/nginx/sites-available/mywebapp /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

echo "10. Блокування дефолтного користувача..."
DEFAULT_USER=$(id -nu 1000 2>/dev/null)
if [ -n "$DEFAULT_USER" ]; then
    usermod -L "$DEFAULT_USER"
    usermod -s /usr/sbin/nologin "$DEFAULT_USER"
fi

echo "=== Готово! ==="