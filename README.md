# 📝 Notes Service

> Автоматизоване розгортання веб-застосунку з базою даних і reverse-proxy на Ubuntu за допомогою єдиного bash-скрипта або Docker Compose.

---

## 📋 Зміст

- [Вимоги](#-вимоги)
- [Холодний старт (Bootstrapping)](#-холодний-старт-bootstrapping)
- [Налаштування інфраструктури](#️-налаштування-інфраструктури)
- [GitHub Secrets](#️-github-secrets)
- [CI/CD Пайплайни](#-cicd-пайплайни)
- [Розгортання](#-розгортання)
- [Верифікація](#-верифікація-розгортання)
- [Звітність](#-звітність)

---

## 📦 Вимоги

### 🐳 Метод 1 — Docker Compose

| Вимога | Деталі |
|---|---|
| ОС | Будь-яка (Linux, macOS, Windows + WSL2) |
| Docker Engine | Встановлений |
| Docker Compose | Встановлений (плагін) |
| Git | Для клонування репозиторію |
| Порти | `80` (Nginx), `5432` (БД) — мають бути вільні |

### 🖥️ Метод 2 — Bash скрипт

| Вимога | Деталі |
|---|---|
| ОС | Ubuntu Server **22.04** або **24.04** (чиста інсталяція) |
| CPU / RAM | Мінімум 1 vCPU / 1 GB RAM (рекомендовано 2 GB) |
| Доступ | Користувач із правами `sudo` |
| Мережа | Стабільне підключення до інтернету |

---

## 🏁 Холодний старт (Bootstrapping)

Якщо ви запускаєте проєкт на **абсолютно чистій системі** (хост-машині або керуючій ВМ), де немає нічого, крім терміналу, виконайте команди нижче для автоматичного встановлення базових інструментів розгортання (`Git`, `Docker`, `Multipass`).

### 1. Підготовка керуючої машини (Ubuntu/Debian)

```bash
# Оновлення індексу пакетів системи
sudo apt update && sudo apt upgrade -y

# Встановлення базових утиліт та Git
sudo apt install -y curl wget git software-properties-common

# Встановлення Multipass (для створення нод)
sudo snap install multipass

# Встановлення Docker та Docker Compose (якщо хост виступає в ролі target/runner)
sudo apt install -y docker.io docker-compose-v2
sudo usermod -aG docker $USER
```

> **Примітка:** Після додавання користувача до групи `docker` необхідно перелогінитися в терміналі (`su - $USER`).

### 2. Генерація SSH-ключів (Критично для автоматизації нод)

Для того, щоб Runner та скрипти мали доступ до нод без паролей, згенеруйте SSH-ключ:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

### 3. Клонування проєкту

```bash
git clone https://github.com/vitkovskiiy/notes-service.git
cd notes-service
```

---

## 🛠️ Налаштування інфраструктури

### 1. Підготовка Target Node

На віртуальній машині, де буде працювати проєкт, виконайте скрипт початкового налаштування:

```bash
# Зайти на target-node
multipass shell target-node

# Надати права та запустити скрипт
chmod +x scripts/setup-node.sh
sudo ./scripts/setup-node.sh
```

Скрипт встановить: **Docker**, **Nginx** та налаштує необхідні права доступу.

### 2. Налаштування GitHub Runner

Розгортання відбувається через окрему машину-раннер для забезпечення безпеки.

1. Створіть VM `runner-node` (Ubuntu 24.04)
2. У GitHub: **Settings → Actions → Runners → New self-hosted runner**
3. Виконайте команди інсталяції, що надає GitHub
4. Переконайтеся, що раннер має SSH-доступ до `target-node`

---

## ⚙️ GitHub Secrets

Додайте наступні секрети в репозиторій (**Settings → Secrets and variables → Actions**):

| Secret | Опис |
|---|---|
| `SSH_PRIVATE_KEY` | Приватний SSH-ключ для доступу з раннера на target-node |
| `TARGET_HOST` | IP-адреса вашої target-node |
| `TARGET_USER` | Ім'я користувача на сервері (наприклад, `ubuntu`) |
| `DATABASE_URL` | Рядок підключення до БД для тестів та міграцій |

---

## 🔄 CI/CD Пайплайни

### 🔍 CI — Перевірка коду

Пайплайн запускається автоматично при:

- Створенні Pull Request у гілку `main`
- Будь-якому Push у гілку `main`

Що включає:

- Static analysis (ESLint, Hadolint)
- Unit tests (Jest)
- Coverage report

### 📦 CD — Розгортання

Деплой нової версії запускається автоматично при створенні анотованого тегу:

```bash
# Створити нову версію
git tag -a v1.0.0 -m "Release description"

# Запушити тег
git push origin v1.0.0
```

---

## 🚀 Розгортання

### 🐳 Метод 1 — Docker Compose (рекомендовано)

Розгортає систему в ізольованих контейнерах без змін у хост-системі.

```bash
docker compose up -d --build
```

### 🖥️ Метод 2 — Bash скрипт

**Крок 1.** Завантаження та запуск скрипта:

```bash
wget https://raw.githubusercontent.com/vitkovskiiy/notes-service/main/setup.sh \
  -O setup.sh && chmod +x setup.sh && sudo ./setup.sh
```

Після завершення має з'явитися повідомлення:

```
=== Готово! Сервіс успішно розгорнуто. ===
```

**Крок 2.** Перевірка працездатності:

```bash
# Health-статус
curl http://localhost/health/alive   # → OK
curl http://localhost/health/ready   # → OK

# Створити тестову нотатку
curl -X POST -H "Content-Type: application/json" \
  -d '{"title":"Test Note","content":"This is a test"}' \
  http://localhost/notes

# Отримати список усіх нотаток
curl -H "Accept: application/json" http://localhost/notes
```

---

## ✅ Верифікація розгортання

Після завершення CD-пайплайну система автоматично запускає `verify.sh` на раннері, який перевіряє:

| Перевірка | Опис |
|---|---|
| Status | Чи активний системний юніт `notes-service` |
| Container | Чи запущено Docker-контейнер |
| Endpoint | Чи відповідає Nginx на порту 80 (200 OK) |

Для ручної перевірки перейдіть за адресою:

```
http://<TARGET_NODE_IP>/health/alive
```

### 🔐 Перевірка користувачів та прав

**Файл оцінювання:**

```bash
cat /home/student/gradebook
# Очікуваний вивід: 3
```

**Обмежені права оператора:**

Зайдіть під користувачем `operator` (пароль за замовчуванням: `12345678`; при першому вході система попросить змінити):

```bash
su - operator
```

Дозволені команди без пароля:

```bash
sudo systemctl status mywebapp.service
sudo systemctl restart mywebapp.service
sudo systemctl reload nginx
```

Заблоковані команди:

```bash
sudo journalctl -u mywebapp.service  # ✗ Буде відхилено
```

> ⚠️ **Примітка:** Під час виконання скрипта дефолтний системний користувач (`vagrant`, `ubuntu` тощо) блокується згідно з вимогами безпеки. Подальше адміністрування виконується через `student` або `teacher`.

---

## 📊 Звітність

| Метрика | Значення |
|---|---|
| Результати тестів | Завантажуються в Artifacts кожного успішного CI-білду |
| Мінімальне покриття | 40% |
| Поточне покриття | ~90% |
