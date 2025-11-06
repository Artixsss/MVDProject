# Архитектура системы MVD Project

## 📐 Общая архитектура

```
┌─────────────────────────────────────────────────────────┐
│                    ПОЛЬЗОВАТЕЛИ                         │
├──────────────────┬──────────────────────────────────────┤
│   Граждане       │     Сотрудники МВД                   │
│   (публичный)    │     (авторизованные)                 │
└────────┬─────────┴──────────────┬──────────────────────┘
         │                        │
         └────────────┬───────────┘
                      │
         ┌────────────▼────────────┐
         │   FRONTEND (Flutter)    │
         │   - Web приложение      │
         │   - Material 3 UI       │
         │   - go_router           │
         │   - flutter_map         │
         └────────────┬────────────┘
                      │ HTTP/REST
         ┌────────────▼────────────┐
         │   BACKEND (ASP.NET)     │
         │   - Web API             │
         │   - Controllers         │
         │   - Services            │
         │   - Repositories        │
         └─────┬──────┬────────┬───┘
               │      │        │
       ┌───────┘      │        └────────┐
       │              │                 │
┌──────▼──────┐  ┌────▼────┐  ┌────────▼─────┐
│ PostgreSQL  │  │ Gemini  │  │  Nominatim   │
│ + PostGIS   │  │   API   │  │     OSM      │
│   (БД)      │  │  (AI)   │  │ (Геокодинг)  │
└─────────────┘  └─────────┘  └──────────────┘
```

## 🏗️ Архитектура бэкенда

### Слои приложения

```
┌────────────────────────────────────────┐
│         Presentation Layer             │
│  (Controllers, DTOs, Validators)       │
├────────────────────────────────────────┤
│          Business Logic Layer          │
│     (Services, Domain Logic)           │
├────────────────────────────────────────┤
│         Data Access Layer              │
│  (Repositories, EF Core Context)       │
├────────────────────────────────────────┤
│           Database Layer               │
│     (PostgreSQL + PostGIS)             │
└────────────────────────────────────────┘
```

### Основные компоненты

#### Controllers
- `AuthController` — авторизация
- `CitizenRequestsController` — управление обращениями
- `CitizensController` — управление гражданами
- `EmployeesController` — управление сотрудниками
- `CategoriesController` — категории обращений
- `RequestTypesController` — типы обращений
- `RequestStatusesController` — статусы
- `DistrictsController` — районы
- `AnalyticsController` — аналитика

#### Services
- `GeminiService` — интеграция с AI (анализ текста)
- `NominatimService` — геокодирование адресов
- `AuditService` — логирование изменений

#### Repositories
- `CitizenRequestRepository` — работа с обращениями
- `GenericRepository<T>` — базовый репозиторий

### База данных

#### Основные таблицы
- `Users` — пользователи системы
- `Roles` — роли пользователей
- `Employees` — сотрудники МВД
- `Citizens` — граждане
- `CitizenRequests` — обращения граждан
- `Categories` — категории обращений
- `RequestTypes` — типы обращений
- `RequestStatuses` — статусы
- `Districts` — районы
- `AuditLogs` — лог изменений

#### Геоданные
- Тип `geography(point)` для хранения координат
- PostGIS для геопространственных запросов

## 🎨 Архитектура фронтенда

### Структура приложения

```
┌──────────────────────────────────────────┐
│              UI Layer                    │
│   (Screens, Widgets, Themes)             │
├──────────────────────────────────────────┤
│           Business Logic                 │
│   (State Management, Validators)         │
├──────────────────────────────────────────┤
│         Data Layer                       │
│  (API Service, Models, DTOs)             │
├──────────────────────────────────────────┤
│      Platform Layer                      │
│   (HTTP, Storage, Platform APIs)         │
└──────────────────────────────────────────┘
```

### Основные компоненты

#### Screens
- `AuthScreen` — авторизация + публичные ссылки
- `CitizenComplaintScreen` — подача обращений (граждане)
- `CheckStatusScreen` — проверка статуса (граждане)
- `DashboardScreen` — дэшборд с картой (сотрудники)
- `RequestListScreen` — список обращений (сотрудники)
- `RequestDetailScreen` — детали обращения (сотрудники)
- `RequestNewScreen` — создание обращения (сотрудники)
- `AnalyticsScreen` — аналитика (сотрудники)
- `AdminScreen` — администрирование (Admin/Manager)

#### Services
- `ApiService` — клиент для работы с REST API

#### Models
- `CitizenRequestDto` — модель обращения
- `CreateCitizenRequestDto` — DTO для создания
- `UserSession` — модель сессии пользователя

#### Navigation
- `AppRouter` — конфигурация маршрутов (go_router)
- Role-based access control
- Deep linking support

## 🔐 Безопасность

### Текущая реализация
- Временное хранение сессии в `SharedPreferences`
- Проверка авторизации на уровне роутинга
- Разделение публичных и защищённых маршрутов
- Role-based access для администрирования

### Планируется
- JWT токены
- Refresh tokens
- HTTPS в продакшене
- CORS настройка
- Rate limiting

## 🔄 Потоки данных

### 1. Подача обращения гражданином

```
Гражданин → Frontend → Backend → Nominatim (геокодинг)
                          ↓
                     PostgreSQL (сохранение)
                          ↓
                     Gemini API (AI-анализ в фоне)
                          ↓
                     PostgreSQL (обновление AI-полей)
                          ↓
                     Frontend ← Backend (номер обращения)
```

### 2. Просмотр обращения сотрудником

```
Сотрудник → Frontend → Backend → PostgreSQL
                          ↓
                     Frontend ← (обращение + AI-данные)
```

### 3. Изменение статуса

```
Сотрудник → Frontend → Backend → PostgreSQL (обновление)
                          ↓
                     AuditService (лог изменений)
                          ↓
                     Frontend ← (подтверждение)
```

## 🗺️ Геоданные

### Поток геокодирования

```
Адрес (текст) → Nominatim API → Координаты (lat, lon)
                                      ↓
                              Backend → PostgreSQL
                                      ↓
                              PostGIS (geography point)
```

### Использование
- Хранение: `geography(point)` в PostgreSQL
- Запросы: пространственные функции PostGIS
- Визуализация: `flutter_map` + OpenStreetMap

## 🤖 AI Integration

### Поток AI-анализа

```
Описание обращения → Backend → Gemini API
                                    ↓
                          Анализ (JSON response):
                          - Категория
                          - Приоритет
                          - Тональность
                          - Резюме
                          - Рекомендуемое действие
                                    ↓
                          PostgreSQL (сохранение)
                                    ↓
                          Frontend ← (отображение)
```

### Коррекция AI
- Сотрудник может скорректировать категорию
- Флаг `IsAiCorrected = true`
- `FinalCategory` сохраняет правильную категорию

## 📊 Аналитика

### Виды аналитики
1. **По районам:**
   - Количество обращений
   - Средний приоритет
   - Распределение по категориям

2. **По категориям:**
   - Количество обращений
   - Процентное соотношение

3. **AI-статистика:**
   - Покрытие (% проанализированных)
   - Коррекции (% исправленных)
   - Распределение по приоритетам

## 🚀 Масштабирование

### Текущие ограничения
- Однопоточный бэкенд (один процесс)
- Локальная база данных
- Синхронные запросы к внешним API

### Рекомендации для продакшена
1. **Backend:**
   - Load balancing (несколько инстансов)
   - Redis для кэширования
   - Message queue для фоновых задач (RabbitMQ/Azure Service Bus)
   - Асинхронные вызовы AI API

2. **Database:**
   - Репликация (master-slave)
   - Индексы на часто используемых полях
   - Партиционирование больших таблиц

3. **Frontend:**
   - CDN для статических файлов
   - Service Worker для офлайн-режима
   - Lazy loading компонентов

4. **Infrastructure:**
   - Kubernetes для оркестрации
   - CI/CD pipeline
   - Мониторинг (Prometheus + Grafana)
   - Централизованное логирование (ELK Stack)

## 📈 Performance

### Оптимизации
- EF Core: Include для eager loading
- API: Pagination для больших списков
- Frontend: Виртуализация списков
- Карта: Кластеризация маркеров (планируется)

## 🔧 Зависимости

### Backend
- ASP.NET Core 8
- Entity Framework Core 8
- Npgsql.EntityFrameworkCore.PostgreSQL
- NetTopologySuite (PostGIS)

### Frontend
- Flutter SDK 3.8+
- go_router 14.0.0
- flutter_map 6.0.0
- syncfusion_flutter_charts 31.1.19
- http 1.2.2

### Внешние сервисы
- Google Gemini API (AI)
- Nominatim OpenStreetMap (геокодинг)
- OpenStreetMap tiles (карты)

---

**Версия:** 1.0  
**Последнее обновление:** Ноябрь 2025

