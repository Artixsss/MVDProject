# Инструкция по развёртыванию MVD Frontend

## 🎯 Цель

Данное руководство поможет развернуть фронтенд-приложение MVD для работы с обращениями граждан.

---

## 📋 Предварительные требования

### Обязательное ПО
- **Flutter SDK** ≥ 3.8.0
  - Скачать: https://flutter.dev/docs/get-started/install
- **Dart SDK** ^3.8.1 (входит в Flutter)
- **Git** для клонирования репозитория
- **Браузер** (Chrome, Edge, Firefox или Safari)

### Бэкенд
- Запущенный **MvdBackend** на `http://localhost:5029`
- Инструкция по запуску бэкенда: см. репозиторий https://github.com/Attys192/MvdBackend

---

## 🚀 Установка и запуск

### 1. Клонирование репозитория

```bash
cd C:\Users\Artixs\source\repos\
git clone <URL-репозитория> mvd_frontend
cd mvd_frontend
```

Если репозиторий уже есть:
```bash
cd C:\Users\Artixs\source\repos\mvd_frontend
git pull
```

### 2. Проверка Flutter

```bash
flutter doctor
```

Убедитесь, что:
- ✅ Flutter установлен
- ✅ Dart SDK доступен
- ✅ Chrome или Edge настроен для веб-разработки

Если есть проблемы, исправьте их согласно рекомендациям `flutter doctor`.

### 3. Установка зависимостей

```bash
flutter pub get
```

Это установит все необходимые пакеты из `pubspec.yaml`:
- go_router
- flutter_map
- syncfusion_flutter_charts
- shared_preferences
- http
- shimmer
- form_validator
- и другие

### 4. Запуск бэкенда

**ВАЖНО:** Перед запуском фронтенда убедитесь, что бэкенд запущен!

```bash
cd C:\Users\Artixs\source\repos\MvdBackend
dotnet run
```

Бэкенд должен быть доступен по адресу: `http://localhost:5029`

Проверьте доступность:
```bash
curl http://localhost:5029/api/categories
```

### 5. Запуск фронтенда

#### Вариант A: Использование скриптов (рекомендуется)

**Windows PowerShell:**
```powershell
.\start.ps1
```

**Windows CMD:**
```cmd
start.bat
```

#### Вариант B: Командная строка Flutter

**Chrome (по умолчанию):**
```bash
flutter run -d chrome
```

**Edge:**
```bash
flutter run -d edge
```

**Конкретный порт:**
```bash
flutter run -d chrome --web-port=8080
```

### 6. Открытие приложения

После запуска автоматически откроется браузер по адресу:
```
http://localhost:<port>/
```

Обычно порт: `8080`, `8081` или другой свободный.

---

## 🛠️ Разработка

### Режим hot reload

При запуске через `flutter run` изменения в коде автоматически перезагружаются:
- Нажмите `r` в консоли для горячей перезагрузки
- Нажмите `R` для полной перезагрузки
- Нажмите `q` для выхода

### Отладка

```bash
# Включить режим отладки
flutter run -d chrome --debug

# Запустить с DevTools
flutter run -d chrome --dart-define=FLUTTER_WEB_USE_SKIA=true
```

### Анализ кода

```bash
# Проверка на ошибки и предупреждения
flutter analyze

# Форматирование кода
flutter format .
```

### Тестирование

```bash
# Запуск всех тестов
flutter test

# Запуск тестов с покрытием
flutter test --coverage
```

---

## 📦 Сборка для продакшена

### 1. Сборка веб-приложения

```bash
flutter build web --release
```

Собранные файлы будут в папке: `build/web/`

### 2. Оптимизация сборки

```bash
# С Tree Shaking (уменьшение размера)
flutter build web --release --tree-shake-icons

# С настройкой renderer
flutter build web --release --web-renderer canvaskit
```

### 3. Структура сборки

```
build/web/
├── assets/               # Статические ресурсы
├── canvaskit/           # WebAssembly для Canvas
├── index.html           # Главная страница
├── main.dart.js         # Скомпилированный Dart
├── flutter.js           # Flutter Engine
├── manifest.json        # PWA манифест
└── favicon.png          # Иконка
```

---

## 🌐 Развёртывание

### Вариант 1: Локальный веб-сервер

```bash
# Python 3
cd build/web
python -m http.server 8080

# Node.js (http-server)
npx http-server build/web -p 8080
```

Откройте: `http://localhost:8080`

### Вариант 2: IIS (Windows)

1. Установите IIS через "Программы и компоненты"
2. Скопируйте содержимое `build/web/` в `C:\inetpub\wwwroot\mvd\`
3. Создайте приложение в IIS Manager
4. Настройте `web.config`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <system.webServer>
        <rewrite>
            <rules>
                <rule name="Flutter SPA">
                    <match url=".*" />
                    <conditions logicalGrouping="MatchAll">
                        <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
                    </conditions>
                    <action type="Rewrite" url="/" />
                </rule>
            </rules>
        </rewrite>
    </system.webServer>
</configuration>
```

### Вариант 3: Nginx

Конфигурация `nginx.conf`:

```nginx
server {
    listen 80;
    server_name mvd.local;
    root /var/www/mvd;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://localhost:5029;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Вариант 4: Apache

Конфигурация `.htaccess`:

```apache
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase /
    RewriteRule ^index\.html$ - [L]
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule . /index.html [L]
</IfModule>
```

### Вариант 5: Облачные платформы

#### Firebase Hosting
```bash
npm install -g firebase-tools
firebase login
firebase init hosting
firebase deploy
```

#### GitHub Pages
```bash
# Скопируйте build/web в gh-pages ветку
git checkout -b gh-pages
cp -r build/web/* .
git add .
git commit -m "Deploy"
git push origin gh-pages
```

#### Vercel
```bash
npm install -g vercel
vercel --prod
```

---

## ⚙️ Конфигурация

### Изменение базового URL API

Откройте `lib/utils/constants.dart`:

```dart
// Локальная разработка
const String baseUrl = 'http://localhost:5029';

// Продакшен
// const String baseUrl = 'https://api.mvd.example.com';
```

### Изменение порта разработки

Откройте `web/flutter_dev_server.config`:

```json
{
  "port": 8080
}
```

---

## 🐛 Устранение проблем

### Проблема: Не запускается Flutter

**Решение:**
```bash
flutter doctor -v
flutter upgrade
flutter pub get
```

### Проблема: CORS ошибки

**Решение:**  
Настройте CORS в бэкенде (`Program.cs`):

```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", builder =>
    {
        builder.AllowAnyOrigin()
               .AllowAnyMethod()
               .AllowAnyHeader();
    });
});

app.UseCors("AllowAll");
```

### Проблема: Бэкенд недоступен

**Проверка:**
```bash
curl http://localhost:5029/api/categories
```

**Решение:**
- Запустите бэкенд: `cd MvdBackend && dotnet run`
- Проверьте firewall
- Проверьте порт 5029

### Проблема: Ошибки компиляции

**Решение:**
```bash
flutter clean
flutter pub get
flutter run
```

### Проблема: Не загружаются карты

**Причина:** Нет интернета или заблокирован OpenStreetMap

**Решение:**
- Проверьте интернет-соединение
- Используйте VPN если OSM заблокирован

---

## 📊 Мониторинг

### Логи приложения

В режиме разработки логи выводятся в консоль:
```bash
flutter run -d chrome --verbose
```

### Анализ производительности

```bash
# Включить DevTools
flutter run --observatory-port=8888

# Открыть DevTools
flutter pub global run devtools
```

---

## 🔄 Обновление

### Обновление зависимостей

```bash
# Обновить все пакеты
flutter pub upgrade

# Обновить конкретный пакет
flutter pub upgrade go_router
```

### Обновление Flutter

```bash
flutter upgrade
```

---

## 📚 Дополнительные ресурсы

- **Flutter документация:** https://flutter.dev/docs
- **Flutter Web:** https://flutter.dev/web
- **go_router:** https://pub.dev/packages/go_router
- **flutter_map:** https://pub.dev/packages/flutter_map

---

## 📞 Поддержка

При возникновении проблем:
1. Проверьте `flutter doctor`
2. Убедитесь что бэкенд запущен
3. Очистите кэш: `flutter clean`
4. Обратитесь к руководителю практики

---

**Версия:** 1.0.0  
**Последнее обновление:** 6 ноября 2025

