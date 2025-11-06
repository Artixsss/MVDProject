# Руководство разработчика — MVD Project

## 🛠️ Настройка окружения

### Требования
- **Windows 10/11** (или Linux/macOS)
- **.NET SDK 8.0+**
- **PostgreSQL 16** с PostGIS
- **Flutter SDK 3.8+**
- **Git**
- **VS Code** или **Visual Studio 2022**

### Установка зависимостей

#### 1. Backend
```bash
cd backend
dotnet restore
dotnet ef database update
```

#### 2. Frontend
```bash
cd frontend
flutter pub get
```

## 🏃 Запуск проекта

### Вариант 1: Автоматический запуск
```bash
# Windows CMD
start-all.bat

# Windows PowerShell
.\start-all.ps1
```

### Вариант 2: Ручной запуск

**Терминал 1 — Backend:**
```bash
cd backend
dotnet run
# или для hot reload:
dotnet watch run
```

**Терминал 2 — Frontend:**
```bash
cd frontend
flutter run -d chrome
```

## 📁 Структура проекта

### Backend
```
backend/
├── Controllers/       # REST API контроллеры
├── Models/           # Модели данных (сущности)
├── DTOs/             # Data Transfer Objects
├── Services/         # Бизнес-логика, внешние API
├── Repositories/     # Работа с БД
├── Data/             # DbContext, миграции
├── Program.cs        # Точка входа
└── appsettings.json  # Конфигурация
```

### Frontend
```
frontend/
├── lib/
│   ├── main.dart             # Точка входа
│   ├── app_router.dart       # Маршрутизация
│   ├── screens/              # Экраны приложения
│   ├── widgets/              # Переиспользуемые виджеты
│   ├── models/               # Модели данных
│   ├── services/             # API клиент
│   └── utils/                # Утилиты, константы
├── web/                      # Web-специфичные файлы
└── pubspec.yaml              # Зависимости
```

## 🔄 Workflow разработки

### 1. Создание новой ветки
```bash
git checkout develop
git pull
git checkout -b feature/my-new-feature
```

### 2. Разработка

#### Backend — добавление нового эндпоинта

1. **Создать DTO (если нужно):**
```csharp
// DTOs/MyDto.cs
public class MyDto
{
    public int Id { get; set; }
    public string Name { get; set; }
}
```

2. **Создать/обновить Controller:**
```csharp
// Controllers/MyController.cs
[ApiController]
[Route("api/[controller]")]
public class MyController : ControllerBase
{
    [HttpGet]
    public ActionResult<IEnumerable<MyDto>> GetAll()
    {
        // логика
        return Ok(results);
    }
}
```

3. **Создать/обновить Service (если нужна бизнес-логика):**
```csharp
// Services/MyService.cs
public class MyService
{
    public async Task<List<MyDto>> GetDataAsync()
    {
        // логика
    }
}
```

4. **Тестирование:**
```bash
dotnet test
# или вручную через Postman/curl
curl http://localhost:5029/api/my
```

#### Frontend — добавление нового экрана

1. **Создать модель (если нужна):**
```dart
// lib/models/my_model.dart
class MyModel {
  final int id;
  final String name;
  
  MyModel({required this.id, required this.name});
  
  factory MyModel.fromJson(Map<String, dynamic> json) {
    return MyModel(
      id: json['id'],
      name: json['name'],
    );
  }
}
```

2. **Добавить метод в ApiService:**
```dart
// lib/services/api_service.dart
Future<List<MyModel>> getMyData() async {
  final res = await http.get(Uri.parse('$baseUrl/api/my'));
  if (res.statusCode == 200) {
    final list = jsonDecode(res.body) as List;
    return list.map((e) => MyModel.fromJson(e)).toList();
  }
  throw Exception('Failed');
}
```

3. **Создать экран:**
```dart
// lib/screens/my_screen.dart
class MyScreen extends StatefulWidget {
  const MyScreen({super.key});
  
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final _api = const ApiService();
  List<MyModel> _data = [];
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _load();
  }
  
  Future<void> _load() async {
    final data = await _api.getMyData();
    setState(() {
      _data = data;
      _loading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Screen')),
      body: _loading
        ? const CircularProgressIndicator()
        : ListView.builder(
            itemCount: _data.length,
            itemBuilder: (ctx, i) => ListTile(
              title: Text(_data[i].name),
            ),
          ),
    );
  }
}
```

4. **Добавить маршрут:**
```dart
// lib/app_router.dart
GoRoute(
  path: '/my',
  builder: (context, state) => const MyScreen(),
),
```

### 3. Тестирование

#### Backend
```bash
cd backend
dotnet test
```

#### Frontend
```bash
cd frontend
flutter test
flutter analyze
```

### 4. Commit & Push
```bash
git add .
git commit -m "feat: add my new feature"
git push origin feature/my-new-feature
```

### 5. Pull Request
Создайте PR в GitHub/GitLab с описанием изменений.

## 🧪 Тестирование

### Backend — Unit тесты
```csharp
// Tests/MyServiceTests.cs
[Fact]
public async Task GetData_ReturnsCorrectData()
{
    // Arrange
    var service = new MyService();
    
    // Act
    var result = await service.GetDataAsync();
    
    // Assert
    Assert.NotNull(result);
    Assert.NotEmpty(result);
}
```

### Frontend — Widget тесты
```dart
// test/my_screen_test.dart
testWidgets('MyScreen displays data', (WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: MyScreen()));
  await tester.pumpAndSettle();
  
  expect(find.text('My Screen'), findsOneWidget);
});
```

## 🔍 Отладка

### Backend
```bash
# Запуск с отладкой
dotnet run --configuration Debug

# VS Code: F5 (с настроенным launch.json)
```

### Frontend
```bash
# Запуск с DevTools
flutter run -d chrome --dart-define=FLUTTER_WEB_USE_SKIA=true

# Открыть DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

## 📊 Производительность

### Backend — профилирование
```bash
dotnet trace collect --process-id <PID>
```

### Frontend — профилирование
```bash
flutter run --profile -d chrome
# Откройте DevTools и перейдите во вкладку Performance
```

## 🐛 Типичные проблемы

### Backend

**Проблема:** Миграции не применяются
```bash
# Решение:
dotnet ef migrations add InitialCreate
dotnet ef database update
```

**Проблема:** CORS ошибки
```csharp
// Решение в Program.cs:
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", builder =>
        builder.AllowAnyOrigin()
               .AllowAnyMethod()
               .AllowAnyHeader());
});
app.UseCors("AllowAll");
```

### Frontend

**Проблема:** Пакеты не установлены
```bash
# Решение:
flutter clean
flutter pub get
```

**Проблема:** Web не поддерживается
```bash
# Решение:
flutter config --enable-web
```

## 🎨 Code Style

### Backend (C#)
- Следовать [Microsoft C# Coding Conventions](https://docs.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions)
- PascalCase для классов и методов
- camelCase для переменных
- Префикс `_` для приватных полей

### Frontend (Dart)
- Следовать [Effective Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- camelCase для переменных и методов
- PascalCase для классов
- Префикс `_` для приватных членов

## 📚 Полезные команды

### Backend
```bash
# Создать миграцию
dotnet ef migrations add MigrationName

# Откатить миграцию
dotnet ef database update PreviousMigration

# Удалить последнюю миграцию
dotnet ef migrations remove

# Обновить БД
dotnet ef database update

# Сборка
dotnet build

# Публикация
dotnet publish -c Release
```

### Frontend
```bash
# Обновить зависимости
flutter pub upgrade

# Анализ кода
flutter analyze

# Форматирование
flutter format .

# Сборка для Web
flutter build web --release

# Очистка
flutter clean

# Проверка доступных устройств
flutter devices

# Запуск на конкретном устройстве
flutter run -d chrome
```

## 🔐 Секреты и конфигурация

### Backend
Не коммитить файлы с секретами:
- `appsettings.Development.json`
- `appsettings.Local.json`

Использовать User Secrets для разработки:
```bash
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "your_connection_string"
```

### Frontend
Не коммитить:
- API ключи в коде
- Файлы `.env`

Использовать константы или environment variables:
```dart
// lib/utils/constants.dart
const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:5029');
```

## 📖 Дополнительные ресурсы

### Backend
- [ASP.NET Core Docs](https://docs.microsoft.com/en-us/aspnet/core/)
- [Entity Framework Core](https://docs.microsoft.com/en-us/ef/core/)
- [PostGIS Documentation](https://postgis.net/documentation/)

### Frontend
- [Flutter Documentation](https://flutter.dev/docs)
- [Flutter Web](https://flutter.dev/web)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [go_router Package](https://pub.dev/packages/go_router)

---

**Happy Coding!** 🚀

