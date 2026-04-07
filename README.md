# Автоматизоване розгортання Notes Service (Варіант 3)

Цей проєкт налаштовує веб-застосунок (Node.js), базу даних (PostgreSQL) та reverse-proxy (Nginx) на чистій віртуальній машині Ubuntu за допомогою єдиного bash-скрипта.

## 🚀 Інструкція з розгортання (для перевірки)

**Вимоги до середовища:**
* Чиста віртуальна машина з ОС **Ubuntu Server 22.04 / 24.04**.
* Підключення до інтернету.
* Користувач з правами `sudo`.

### Крок 1. Завантаження та запуск скрипта автоматизації
Зайдіть на віртуальну машину і виконайте наступну команду (вона завантажить скрипт з репозиторію, надасть йому права на виконання і запустить від імені root):

```bash
wget [https://raw.githubusercontent.com/vitkovskiiy/notes-service/main/setup.sh](https://raw.githubusercontent.com/vitkovskiiy/notes-service/main/setup.sh) -O setup.sh && chmod +x setup.sh && sudo ./setup.sh
```
### Крок 2.
