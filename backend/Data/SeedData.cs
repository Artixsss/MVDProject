using MvdBackend.Models;
using BCrypt.Net;

namespace MvdBackend.Data
{
    public static class SeedData
    {
        public static void Initialize(AppDbContext context)
        {
            // Статусы 
            if (!context.RequestStatuses.Any())
            {
                context.RequestStatuses.AddRange(
                    new RequestStatus { Name = "Новое" },
                    new RequestStatus { Name = "В работе" },
                    new RequestStatus { Name = "На проверке" },
                    new RequestStatus { Name = "Выполнено" },
                    new RequestStatus { Name = "Отклонено" }
                );
                context.SaveChanges();
            }

            // Типы обращений 
            if (!context.RequestTypes.Any())
            {
                context.RequestTypes.AddRange(
                    new RequestType { Name = "Заявление о преступлении" },
                    new RequestType { Name = "Жалоба на действия сотрудников" },
                    new RequestType { Name = "Консультация по законодательству" },
                    new RequestType { Name = "Запрос информации" },
                    new RequestType { Name = "Обращение по ПДД" }
                );
                context.SaveChanges();
            }

            // Категории
            if (!context.Categories.Any())
            {
                context.Categories.AddRange(
                    new Category { Name = "Имущественные преступления", Description = "Кражи, грабежи, мошенничество, вымогательство, повреждение имущества" },
                    new Category { Name = "Транспорт и ПДД", Description = "ДТП, нарушение ПДД, опасное вождение, неправильная парковка" },
                    new Category { Name = "Общественный порядок", Description = "Хулиганство, драки, нарушение тишины, распитие алкоголя" },
                    new Category { Name = "Бытовые конфликты", Description = "Конфликты с соседями, шум, коммунальные проблемы" },
                    new Category { Name = "Угрозы и безопасность", Description = "Угрозы жизни, нападения, преследование, вымогательство" },
                    new Category { Name = "Киберпреступления", Description = "Интернет-мошенничество, взломы, кибербуллинг" },
                    new Category { Name = "Наркотики", Description = "Распространение, употребление наркотических веществ" },
                    new Category { Name = "Экология и животные", Description = "Свалки, загрязнение, жестокое обращение с животными" },
                    new Category { Name = "Пропавшие люди", Description = "Поиск пропавших без вести людей" },
                    new Category { Name = "Другое", Description = "Иные обращения, не вошедшие в категории" }
                );
                context.SaveChanges();
            }

            // Граждане
            if (!context.Citizens.Any())
            {
                context.Citizens.AddRange(
                    new Citizen { LastName = "Иванов", FirstName = "Иван", Patronymic = "Иванович", Phone = "+79131112233" },
                    new Citizen { LastName = "Петров", FirstName = "Петр", Patronymic = "Петрович", Phone = "+79132223344" },
                    new Citizen { LastName = "Сидорова", FirstName = "Анна", Patronymic = "Владимировна", Phone = "+79133334455" }
                );
                context.SaveChanges();
            }
            // Роли - создаем с явными ID для гарантии
            Role? operatorRole = null;
            Role? managerRole = null;
            Role? adminRole = null;
            
            if (!context.Roles.Any())
            {
                operatorRole = new Role { Name = "Operator" };
                managerRole = new Role { Name = "Manager" };
                adminRole = new Role { Name = "Admin" };
                
                context.Roles.AddRange(operatorRole, managerRole, adminRole);
                context.SaveChanges();
                
                // Перезагружаем для получения ID
                operatorRole = context.Roles.FirstOrDefault(r => r.Name == "Operator");
                managerRole = context.Roles.FirstOrDefault(r => r.Name == "Manager");
                adminRole = context.Roles.FirstOrDefault(r => r.Name == "Admin");
            }
            else
            {
                operatorRole = context.Roles.FirstOrDefault(r => r.Name == "Operator");
                managerRole = context.Roles.FirstOrDefault(r => r.Name == "Manager");
                adminRole = context.Roles.FirstOrDefault(r => r.Name == "Admin");
            }
            
            // Сотрудники - создаем с явными ID для гарантии
            int employee1Id = 0;
            int employee2Id = 0;
            int employee3Id = 0;
            
            if (!context.Employees.Any())
            {
                var emp1 = new Employee { LastName = "Козлов", FirstName = "Александр", Patronymic = "Сергеевич" };
                var emp2 = new Employee { LastName = "Никитина", FirstName = "Елена", Patronymic = "Дмитриевна" };
                var emp3 = new Employee { LastName = "Федоров", FirstName = "Максим", Patronymic = "Игоревич" };
                
                context.Employees.AddRange(emp1, emp2, emp3);
                context.SaveChanges();
                
                // Сохраняем ID сразу после создания
                employee1Id = emp1.Id;
                employee2Id = emp2.Id;
                employee3Id = emp3.Id;
            }
            else
            {
                // Получаем ID существующих сотрудников через простой LINQ запрос (только ID, без Phone)
                employee1Id = context.Employees
                    .Where(e => e.LastName == "Козлов" && e.FirstName == "Александр")
                    .Select(e => e.Id)
                    .FirstOrDefault();
                employee2Id = context.Employees
                    .Where(e => e.LastName == "Никитина" && e.FirstName == "Елена")
                    .Select(e => e.Id)
                    .FirstOrDefault();
                employee3Id = context.Employees
                    .Where(e => e.LastName == "Федоров" && e.FirstName == "Максим")
                    .Select(e => e.Id)
                    .FirstOrDefault();
            }
            
            // Пользователи (учетные записи) - используем реальные ID
            if (!context.Users.Any())
            {
                if (operatorRole != null && employee1Id > 0)
                {
                    context.Users.Add(new User 
                    { 
                        Username = "kozlova", 
                        PasswordHash = BCrypt.Net.BCrypt.HashPassword("operator123"), 
                        EmployeeId = employee1Id, 
                        RoleId = operatorRole.Id 
                    });
                }
                
                if (managerRole != null && employee2Id > 0)
                {
                    context.Users.Add(new User 
                    { 
                        Username = "nikitina", 
                        PasswordHash = BCrypt.Net.BCrypt.HashPassword("manager123"), 
                        EmployeeId = employee2Id, 
                        RoleId = managerRole.Id 
                    });
                }
                
                if (adminRole != null && employee3Id > 0)
                {
                    context.Users.Add(new User 
                    { 
                        Username = "fedorov", 
                        PasswordHash = BCrypt.Net.BCrypt.HashPassword("admin123"), 
                        EmployeeId = employee3Id, 
                        RoleId = adminRole.Id 
                    });
                }
                
                context.SaveChanges();
            }
            // Районы
            if (!context.Districts.Any())
            {
                context.Districts.AddRange(
                    new District { Name = "Центральный", Description = "Центральный район" },
                    new District { Name = "Железнодорожный", Description = "Железнодорожный район" },
                    new District { Name = "Заельцовский", Description = "Заельцовский район" },
                    new District { Name = "Калининский", Description = "Калининский район" },
                    new District { Name = "Кировский", Description = "Кировский район" },
                    new District { Name = "Ленинский", Description = "Ленинский район" },
                    new District { Name = "Октябрьский", Description = "Октябрьский район" },
                    new District { Name = "Первомайский", Description = "Первомайский район" },
                    new District { Name = "Советский", Description = "Советский район" },
                    new District { Name = "Дзержинский", Description = "Дзержинский район" }
                );
                context.SaveChanges();
            }
           

        }
    }
}
