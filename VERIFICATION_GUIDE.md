# Інструкція з перевірки виконання Лабораторної роботи №2

## Передумови

Перед перевіркою переконайтеся, що встановлено:
- Docker Desktop (запущений і активний)
- git
- PowerShell 5.1+ або bash (WSL)

---

## ЧАСТИНА 1 — Перевірка Python App (Дослідницька частина)

### Крок 1.1 — Перевірка структури файлів

```powershell
cd "c:\Users\ADMIN\OneDrive\Рабочий стол\учеба 2 курс\ТРПЗКС\lab2\lab-03-starter-project-python"
```

**Очікувані файли:**
```
Dockerfile                  ← базовий (неоптимальний)
Dockerfile.optimized        ← з правильним порядком шарів
Dockerfile.alpine           ← на базі alpine
Dockerfile.alpine-numpy     ← alpine + numpy
Dockerfile.debian-numpy     ← debian + numpy
requirements/
    backend.in              ← вихідний (назви без версій)
    backend.txt             ← pinned версії (pip freeze)
    backend-numpy.txt       ← pinned + numpy
build/
    index.html              ← має містити ім'я студента
spaceship/routers/
    api.py                  ← має містити /matrix endpoint
```

**Команда перевірки:**
```powershell
Get-ChildItem -Recurse -File | Where-Object {$_.Name -match "Dockerfile|backend.txt|backend-numpy"} | Select-Object FullName
```

---

### Крок 1.2 — Перевірка вмісту файлів

**Перевірка index.html (має містити ім'я студента):**
```powershell
Get-Content build\index.html
```
✅ Очікується: рядок з іменем та прізвищем студента

**Перевірка api.py (має бути /matrix endpoint):**
```powershell
Get-Content spaceship\routers\api.py
```
✅ Очікується:
- `import numpy as np`
- `@router.get('/matrix')`
- `np.random.randint(0, 100, (10, 10))`
- `np.dot(a, b)`
- Повертає dict з ключами `matrix_a`, `matrix_b`, `product`

**Перевірка backend.txt (має бути з версіями):**
```powershell
Get-Content requirements\backend.txt
```
✅ Очікується: рядки виду `fastapi==X.Y.Z` (з конкретними версіями)

---

### Крок 1.3 — Перевірка Dockerfile (структура шарів)

**Базовий Dockerfile — має бути НЕОПТИМАЛЬНИМ:**
```powershell
Get-Content Dockerfile
```
✅ Очікується: `COPY . .` стоїть ПЕРЕД `RUN pip install`

**Оптимізований Dockerfile — правильний порядок:**
```powershell
Get-Content Dockerfile.optimized
```
✅ Очікується:
1. `COPY requirements/backend.txt ...`
2. `RUN pip install ...`
3. `COPY . .`

---

### Крок 1.4 — Збірка та вимірювання образів

> ⚠️ **Переконайтеся, що Docker Desktop запущений!**

**Завантажте базові образи (НЕ рахується в часі збірки):**
```powershell
docker pull python:3.13-bookworm
docker pull python:3.13-alpine
```

**Збірка та вимірювання:**
```powershell
# Базовий (неоптимальний)
Measure-Command { docker build --no-cache -f Dockerfile -t spaceship:debian-basic . } | Select-Object TotalSeconds
docker images spaceship:debian-basic --format "Size: {{.Size}}"

# Оптимізований
Measure-Command { docker build --no-cache -f Dockerfile.optimized -t spaceship:debian-opt . } | Select-Object TotalSeconds
docker images spaceship:debian-opt --format "Size: {{.Size}}"

# Симуляція зміни коду — rebuild без --no-cache
Measure-Command { docker build -f Dockerfile -t spaceship:debian-basic . } | Select-Object TotalSeconds
Measure-Command { docker build -f Dockerfile.optimized -t spaceship:debian-opt . } | Select-Object TotalSeconds

# Alpine
Measure-Command { docker build --no-cache -f Dockerfile.alpine -t spaceship:alpine . } | Select-Object TotalSeconds
docker images spaceship:alpine --format "Size: {{.Size}}"

# Debian + numpy
Measure-Command { docker build --no-cache -f Dockerfile.debian-numpy -t spaceship:debian-numpy . } | Select-Object TotalSeconds
docker images spaceship:debian-numpy --format "Size: {{.Size}}"
```

**✅ Очікувані результати:**

| Образ | Перша збірка | Rebuild | Розмір |
|-------|-------------|---------|--------|
| debian-basic | ~90-100 с | ~85-95 с (без кешу) | ~1.3-1.5 ГБ |
| debian-opt | ~90-100 с | **~2-5 с** (з кешем) | ~1.3-1.5 ГБ |
| alpine | ~100-120 с | ~3-5 с | **~150-250 МБ** |
| debian-numpy | ~95-110 с | ~3-5 с | ~1.5-1.7 ГБ |

---

### Крок 1.5 — Перевірка запуску застосунку

**Запустіть образ та перевірте ендпоінти:**
```powershell
docker run -d -p 8000:8000 -e APP_DEBUG=true spaceship:debian-numpy
# Зачекайте 2-3 секунди
Start-Sleep 3

# Перевірка базового ендпоінту
Invoke-RestMethod http://localhost:8000/api

# Перевірка matrix ендпоінту
Invoke-RestMethod http://localhost:8000/api/matrix
```

**✅ Очікуваний результат для /api:**
```json
{"msg": "Hello, World! — ..."}
```

**✅ Очікуваний результат для /api/matrix:**
```json
{
  "matrix_a": [[...10 рядків по 10 чисел...]],
  "matrix_b": [[...10 рядків по 10 чисел...]],
  "product": [[...10 рядків по 10 чисел...]]
}
```

**Зупинка контейнера:**
```powershell
docker ps
docker stop <CONTAINER_ID>
```

---

## ЧАСТИНА 2 — Перевірка Docker Compose (Практична частина)

### Крок 2.1 — Структура файлів mywebapp-docker

```powershell
cd "c:\Users\ADMIN\OneDrive\Рабочий стол\учеба 2 курс\ТРПЗКС\lab2\mywebapp-docker"
```

**Очікувані файли:**
```
docker-compose.yml    ← основний файл
Dockerfile            ← для Node.js застосунку
nginx/
    nginx.conf        ← конфіг nginx reverse proxy
```

---

### Крок 2.2 — Перевірка docker-compose.yml

```powershell
Get-Content docker-compose.yml
```

**✅ Перевіряємо:**

1. **3 сервіси:** `db`, `webapp`, `nginx`
2. **Кастомна мережа** (НЕ default):
   ```yaml
   networks:
     webapp_network:
       driver: bridge
   ```
3. **Named volume для БД:**
   ```yaml
   volumes:
     postgres_data:
   services:
     db:
       volumes:
         - postgres_data:/var/lib/postgresql/data
   ```
4. **Healthcheck для DB:**
   ```yaml
   healthcheck:
     test: ["CMD-SHELL", "pg_isready -U dbuser -d notesdb"]
   ```
5. **depends_on з condition:**
   ```yaml
   webapp:
     depends_on:
       db:
         condition: service_healthy
   ```
6. **Nginx публічний порт, webapp — тільки expose:**
   ```yaml
   nginx:
     ports:
       - "80:80"
   webapp:
     expose:
       - "5000"
   ```

---

### Крок 2.3 — Скопіюйте файли з репозиторію Lab1

> Для повноцінного тестування скопіюйте файли з репозиторію mywebapp в папку mywebapp-docker:
```powershell
# Клонування Lab1 репозиторію (якщо не зроблено)
git clone https://github.com/Anasstassik/mywebapp.git mywebapp-src

# Копіювання файлів у папку з docker-compose
Copy-Item mywebapp-src\server.js mywebapp-docker\
Copy-Item mywebapp-src\package.json mywebapp-docker\
Copy-Item mywebapp-src\package-lock.json mywebapp-docker\
Copy-Item mywebapp-src\config.json mywebapp-docker\
Copy-Item -Recurse mywebapp-src\prisma mywebapp-docker\
```

---

### Крок 2.4 — Запуск Docker Compose

```powershell
cd mywebapp-docker

# Збірка та запуск
docker compose up -d

# Перевірка статусу (всі 3 мають бути "running")
docker compose ps
```

**✅ Очікуваний результат docker compose ps:**
```
NAME                    SERVICE   STATUS    PORTS
mywebapp-docker-db-1      db        running
mywebapp-docker-webapp-1  webapp    running
mywebapp-docker-nginx-1   nginx     running   0.0.0.0:80->80/tcp
```

---

### Крок 2.5 — Перевірка функціональності

```powershell
# Головна сторінка через Nginx
Invoke-WebRequest http://localhost | Select-Object StatusCode, Content

# Список нотаток (має бути порожньою таблицею)
Invoke-WebRequest http://localhost/notes | Select-Object StatusCode

# Створення нотатки
Invoke-RestMethod -Method Post -Uri http://localhost/notes `
  -ContentType "application/json" `
  -Body '{"title":"Test Note","content":"Testing Docker Compose"}'

# Перегляд списку (має бути 1 нотатка)
Invoke-RestMethod -Uri http://localhost/notes -Headers @{Accept="application/json"}
```

**✅ Очікуваний результат останнього запиту:**
```json
[{"id": 1, "title": "Test Note"}]
```

---

### Крок 2.6 — Перевірка стійкості даних

```powershell
# Зупинка контейнерів (БЕЗ -v, volume залишається)
docker compose down

# Перевірка що volume існує
docker volume ls | Select-String "postgres_data"

# Запуск знову
docker compose up -d
Start-Sleep -Seconds 10

# Перевірка що дані збереглися
Invoke-RestMethod -Uri http://localhost/notes -Headers @{Accept="application/json"}
```

**✅ Очікуваний результат:** дані (нотатка "Test Note") збереглися після перезапуску.

---

### Крок 2.7 — Перевірка ізоляції мережі

```powershell
# Список мереж
docker network ls

# Деталі мережі (перевірте що db та webapp не мають публічних портів)
docker inspect mywebapp-docker-webapp-1 --format "{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}"
```

**✅ Очікується:** webapp та db підключені лише до `webapp_network`, без bridge до host.

---

### Крок 2.8 — Перевірка що БД недоступна ззовні

```powershell
# Спроба підключення до PostgreSQL напряму (має ПРОВАЛИТИСЯ)
Test-NetConnection -ComputerName localhost -Port 5432
```

**✅ Очікуваний результат:** `TcpTestSucceeded: False` — PostgreSQL недоступний ззовні (тільки через webapp_network).

---

## ЧАСТИНА 3 — Фінальна перевірка звіту

### Крок 3.1 — Перевірка .docx

Відкрийте файл `Звіт_Лабораторна_2_Docker.docx` і переконайтеся що він містить:

- [ ] Таблицю з реальними вимірами часу збірки та розмірів образів
- [ ] Опис відмінності базового та оптимізованого Dockerfile
- [ ] Порівняння Alpine vs Debian
- [ ] Результати DNS-тесту (musl vs glibc)
- [ ] Опис docker-compose.yml
- [ ] Розділ "Аналіз та Рекомендації"
- [ ] Висновки

---

## Типові проблеми

| Проблема | Причина | Рішення |
|----------|---------|---------|
| Docker не відповідає | Docker Desktop не запущений | Запустити Docker Desktop і зачекати ~1 хв |
| `docker compose up` — prisma migrate fail | БД ще не готова | Healthcheck вирішує це автоматично |
| Port 80 зайнятий | Запущений IIS або інший сервер | `netstat -ano \| findstr :80`, зупинити конфліктуючий сервіс |
| Alpine + numpy build зупинився | Компіляція займає 15+ хв | Нормальна ситуація, чекайте |
| `access denied` при pip install | Відсутні права на запис | Запустити PowerShell від імені адміністратора |
