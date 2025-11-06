# MVD Frontend - Employee Version

Интерфейс для сотрудников МВД России.

## Описание

Этот проект предоставляет полный функционал для сотрудников МВД: управление обращениями, аналитика, администрирование.

## Экраны

- `/` - Авторизация
- `/dashboard` - Главная панель с картой и KPI
- `/requests` - Список обращений с фильтрами
- `/requests/:id` - Детали обращения
- `/analytics` - Аналитика
- `/admin` - Администрирование (только Admin/Manager)

## Запуск

```bash
flutter pub get
flutter run -d chrome --web-port=4000
```

Или используйте скрипт:
- `start.bat` (Windows)

## Тестовые данные

- Логин: `kozlova` / Пароль: `operator123` (Operator)
- Логин: `nikitina` / Пароль: `manager123` (Manager)
- Логин: `fedorov` / Пароль: `admin123` (Admin)

## Документация

Полная документация проекта: `../PROJECT_DOCUMENTATION.md`
