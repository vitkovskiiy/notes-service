#!/bin/bash
# Встановлення Docker та Nginx на Target Node
apt-get update
apt-get install -y docker.io nginx postgresql

# Налаштування БД
sudo -u postgres psql -c "CREATE DATABASE mywebapp;" || true
sudo -u postgres psql -c "CREATE USER student_db WITH PASSWORD 'db_password';" || true
sudo -u postgres psql -c "ALTER DATABASE mywebapp OWNER TO student_db;" || true

# Systemd Unit для Docker-контейнера
cat <<EOF > /etc/systemd/system/mywebapp-container.service
[Unit]
Description=MyWebApp Docker Container
After=docker.service
Requires=docker.service

[Service]
Restart=always
ExecStartPre=-/usr/bin/docker stop mywebapp
ExecStartPre=-/usr/bin/docker rm mywebapp
# Підтягніть ваш образ з ghcr.io (змініть на ваш репо!)
ExecStart=/usr/bin/docker run --name mywebapp -p 8000:8000 --env DATABASE_URL="postgresql://student_db:db_password@host.docker.internal:5432/mywebapp?schema=public" --add-host=host.docker.internal:host-gateway ghcr.io/vitkovskiiy/notes-service:latest
ExecStop=/usr/bin/docker stop mywebapp

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mywebapp-container.service