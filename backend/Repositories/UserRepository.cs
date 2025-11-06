using MvdBackend.Data;
using MvdBackend.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace MvdBackend.Repositories
{
    public class UserRepository : Repository<User>, IUserRepository
    {
        private readonly ILogger<UserRepository>? _logger;

        public UserRepository(AppDbContext context, ILogger<UserRepository>? logger = null) : base(context) 
        {
            _logger = logger;
        }

        public async Task<User?> GetByUsernameAsync(string username)
        {
            try
            {
                // Загружаем User с Role (без Employee, чтобы избежать загрузки Phone)
                var user = await _context.Users
                    .Include(u => u.Role)
                    .FirstOrDefaultAsync(u => u.Username == username);
                
                if (user != null)
                {
                    _logger?.LogInformation("User loaded | userId: {UserId} | employeeId: {EmpId} | roleId: {RoleId} | hasRole: {HasRole}",
                        user.Id, user.EmployeeId, user.RoleId, user.Role != null);
                    
                    // Загружаем Role если не загружен
                    if (user.Role == null && user.RoleId > 0)
                    {
                        user.Role = await _context.Roles.FirstOrDefaultAsync(r => r.Id == user.RoleId);
                        _logger?.LogWarning("Role loaded separately | userId: {UserId} | roleId: {RoleId}", user.Id, user.RoleId);
                    }
                    
                    // Загружаем Employee БЕЗ Phone (используем Select для явного указания полей)
                    if (user.EmployeeId > 0)
                    {
                        var employeeData = await _context.Employees
                            .Where(e => e.Id == user.EmployeeId)
                            .Select(e => new { e.Id, e.LastName, e.FirstName, e.Patronymic })
                            .FirstOrDefaultAsync();
                        
                        if (employeeData != null)
                        {
                            // Создаем объект Employee только с нужными полями (без Phone)
                            user.Employee = new Employee
                            {
                                Id = employeeData.Id,
                                LastName = employeeData.LastName,
                                FirstName = employeeData.FirstName,
                                Patronymic = employeeData.Patronymic
                            };
                            _logger?.LogInformation("Employee loaded separately | userId: {UserId} | employeeId: {EmpId}", user.Id, user.EmployeeId);
                        }
                    }
                }
                
                return user;
            }
            catch (Exception ex)
            {
                _logger?.LogError(ex, "Error loading user | username: {Username}", username);
                throw;
            }
        }

        public async Task<User?> GetWithDetailsAsync(int id)
        {
            // Загружаем User с Role (без Employee, чтобы избежать загрузки Phone)
            var user = await _context.Users
                .Include(u => u.Role)
                .FirstOrDefaultAsync(u => u.Id == id);
            
            // Загружаем Employee БЕЗ Phone
            if (user != null && user.EmployeeId > 0)
            {
                var employeeData = await _context.Employees
                    .Where(e => e.Id == user.EmployeeId)
                    .Select(e => new { e.Id, e.LastName, e.FirstName, e.Patronymic })
                    .FirstOrDefaultAsync();
                
                if (employeeData != null)
                {
                    user.Employee = new Employee
                    {
                        Id = employeeData.Id,
                        LastName = employeeData.LastName,
                        FirstName = employeeData.FirstName,
                        Patronymic = employeeData.Patronymic
                    };
                }
            }
            
            return user;
        }

        public async Task<bool> UsernameExistsAsync(string username)
        {
            return await _context.Users.AnyAsync(u => u.Username == username);
        }
    }
}
