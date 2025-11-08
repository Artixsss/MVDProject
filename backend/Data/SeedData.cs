using MvdBackend.Models;
using BCrypt.Net;

namespace MvdBackend.Data
{
    public static class SeedData
    {
        public static void Initialize(AppDbContext context)
        {
            // Очистка существующих данных (опционально)
            // context.Database.EnsureDeleted();
            // context.Database.EnsureCreated();

            // Статусы заявок
            if (!context.RequestStatuses.Any())
            {
                var statuses = new[]
                {
            new RequestStatus { Name = "Новое" },
            new RequestStatus { Name = "В работе" },
            new RequestStatus { Name = "На проверке" },
            new RequestStatus { Name = "Выполнено" },
            new RequestStatus { Name = "Отклонено" }
        };
                context.RequestStatuses.AddRange(statuses);
                context.SaveChanges();
            }

            // Типы обращений
            if (!context.RequestTypes.Any())
            {
                var types = new[]
                {
            new RequestType { Name = "Заявление о преступлении" },
            new RequestType { Name = "Жалоба на действия сотрудников" },
            new RequestType { Name = "Консультация по законодательству" },
            new RequestType { Name = "Запрос информации" },
            new RequestType { Name = "Обращение по ПДД" }
        };
                context.RequestTypes.AddRange(types);
                context.SaveChanges();
            }

            // Категории
            if (!context.Categories.Any())
            {
                var categories = new[]
                {
            new Category { Name = "Имущественные преступления", Description = "Кражи, грабежи, мошенничество" },
            new Category { Name = "Транспорт и ПДД", Description = "ДТП, нарушение ПДД" },
            new Category { Name = "Общественный порядок", Description = "Хулиганство, драки, шум" },
            new Category { Name = "Бытовые конфликты", Description = "Семейные ссоры, соседские конфликты" },
            new Category { Name = "Угрозы и безопасность", Description = "Угрозы жизни, насилие, вымогательство" },
            new Category { Name = "Киберпреступления", Description = "Мошенничество в интернете, взлом аккаунтов" },
            new Category { Name = "Наркотики", Description = "Незаконный оборот наркотиков" },
            new Category { Name = "Экология и животные", Description = "Жестокое обращение с животными, экологические нарушения" },
            new Category { Name = "Пропавшие люди", Description = "Розыск пропавших без вести" },
            new Category { Name = "Другое", Description = "Прочие обращения, не попадающие в основные категории" }
        };
                context.Categories.AddRange(categories);
                context.SaveChanges();
            }

            // Роли
            if (!context.Roles.Any())
            {
                var roles = new[]
                {
            new Role { Name = "Operator" },
            new Role { Name = "Manager" },
            new Role { Name = "Admin" }
        };
                context.Roles.AddRange(roles);
                context.SaveChanges();
            }

            // Сотрудники и пользователи
            if (!context.Employees.Any())
            {
                var employees = new[]
                {
            new Employee { LastName = "Козлов", FirstName = "Александр", Patronymic = "Сергеевич" },
            new Employee { LastName = "Никитина", FirstName = "Елена", Patronymic = "Дмитриевна" },
            new Employee { LastName = "Федоров", FirstName = "Максим", Patronymic = "Игоревич" }
        };
                context.Employees.AddRange(employees);
                context.SaveChanges();

                // Создаем пользователей после сохранения сотрудников
                var roles = context.Roles.ToList();
                var users = new[]
                {
            new User { Username = "operator", PasswordHash = BCrypt.Net.BCrypt.HashPassword("123"), EmployeeId = employees[0].Id, RoleId = roles[0].Id },
            new User { Username = "manager", PasswordHash = BCrypt.Net.BCrypt.HashPassword("123"), EmployeeId = employees[1].Id, RoleId = roles[1].Id },
            new User { Username = "admin", PasswordHash = BCrypt.Net.BCrypt.HashPassword("123"), EmployeeId = employees[2].Id, RoleId = roles[2].Id }
        };
                context.Users.AddRange(users);
                context.SaveChanges();
            }

            // Граждане
            if (!context.Citizens.Any())
            {
                var citizens = new[]
                {
            new Citizen { LastName = "Иванов", FirstName = "Иван", Patronymic = "Иванович", Phone = "+79131112233" },
            new Citizen { LastName = "Петров", FirstName = "Петр", Patronymic = "Петрович", Phone = "+79132223344" }
        };
                context.Citizens.AddRange(citizens);
                context.SaveChanges();
            }

            // Районы
            if (!context.Districts.Any())
            {
                var districts = new[]
                {
            new District { Name = "Центральный", Description = "Центральный район" },
            new District { Name = "Железнодорожный", Description = "Железнодорожный район" }
        };
                context.Districts.AddRange(districts);
                context.SaveChanges();
            }
        }
    }
}
