using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MvdBackend.Models;
using MvdBackend.Repositories;
using MvdBackend.DTOs;
using MvdBackend.Data;
using BCrypt.Net;

namespace MvdBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AdminController : ControllerBase
    {
        private readonly IRepository<Employee> _employeeRepository;
        private readonly IUserRepository _userRepository;
        private readonly IRoleRepository _roleRepository;
        private readonly AppDbContext _context;
        private readonly ILogger<AdminController> _logger;

        public AdminController(
            IRepository<Employee> employeeRepository,
            IUserRepository userRepository,
            IRoleRepository roleRepository,
            AppDbContext context,
            ILogger<AdminController> logger)
        {
            _employeeRepository = employeeRepository;
            _userRepository = userRepository;
            _roleRepository = roleRepository;
            _context = context;
            _logger = logger;
        }

        // GET: api/Admin/employees - Получить всех сотрудников с деталями (только для Админа)
        [HttpGet("employees")]
        public async Task<ActionResult<IEnumerable<EmployeeDetailsDto>>> GetAllEmployees()
        {
            try
            {
                // Получаем всех сотрудников БЕЗ Phone, чтобы избежать ошибки если столбец не существует
                // Используем явный Select без Phone
                var employees = await _context.Employees
                    .Select(e => new
                    {
                        e.Id,
                        e.FirstName,
                        e.LastName,
                        e.Patronymic
                    })
                    .ToListAsync();

                // Получаем счетчики запросов отдельно
                var acceptedCounts = await _context.CitizenRequests
                    .GroupBy(r => r.AcceptedById)
                    .Select(g => new { EmployeeId = g.Key, Count = g.Count() })
                    .ToDictionaryAsync(x => x.EmployeeId, x => x.Count);

                var assignedCounts = await _context.CitizenRequests
                    .Where(r => r.AssignedToId.HasValue)
                    .GroupBy(r => r.AssignedToId!.Value)
                    .Select(g => new { EmployeeId = g.Key, Count = g.Count() })
                    .ToDictionaryAsync(x => x.EmployeeId, x => x.Count);

                var users = await _context.Users
                    .Include(u => u.Role)
                    .ToListAsync();

                var result = employees.Select(e =>
                {
                    var user = users.FirstOrDefault(u => u.EmployeeId == e.Id);
                    return new EmployeeDetailsDto
                    {
                        Id = e.Id,
                        FirstName = e.FirstName,
                        LastName = e.LastName,
                        Patronymic = e.Patronymic,
                        Phone = "", // Пустая строка, так как столбец Phone может отсутствовать в БД
                        FullName = $"{e.LastName} {e.FirstName} {e.Patronymic}".Trim(),
                        UserId = user?.Id,
                        Username = user?.Username,
                        RoleName = user?.Role?.Name,
                        RoleId = user?.RoleId,
                        AcceptedRequestsCount = acceptedCounts.GetValueOrDefault(e.Id, 0),
                        AssignedRequestsCount = assignedCounts.GetValueOrDefault(e.Id, 0)
                    };
                }).ToList();

                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting employees");
                // Более детальная ошибка для отладки
                var errorMessage = ex.InnerException?.Message ?? ex.Message;
                return StatusCode(500, $"Ошибка получения списка сотрудников: {errorMessage}");
            }
        }

        // POST: api/Admin/employees - Создать нового сотрудника (только для Админа)
        [HttpPost("employees")]
        public async Task<ActionResult<EmployeeDetailsDto>> CreateEmployee([FromBody] CreateEmployeeDto dto)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            try
            {
                // Проверяем что username не занят
                var existingUser = await _userRepository.GetByUsernameAsync(dto.Username);
                if (existingUser != null)
                {
                    return BadRequest($"Пользователь с именем '{dto.Username}' уже существует");
                }

                // Проверяем что роль существует
                var role = await _roleRepository.GetByIdAsync(dto.RoleId);
                if (role == null)
                {
                    return BadRequest($"Роль с ID {dto.RoleId} не найдена");
                }

                // Создаем сотрудника
                var employee = new Employee
                {
                    FirstName = dto.FirstName,
                    LastName = dto.LastName,
                    Patronymic = dto.Patronymic ?? "" // В БД Patronymic обязателен, поэтому используем пустую строку если null
                };
                
                // Phone не используется в БД, не устанавливаем его

                await _employeeRepository.AddAsync(employee);
                await _employeeRepository.SaveAsync();

                // Создаем пользователя
                var user = new User
                {
                    Username = dto.Username,
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
                    EmployeeId = employee.Id,
                    RoleId = dto.RoleId
                };

                await _context.Users.AddAsync(user);
                await _context.SaveChangesAsync();

                _logger.LogInformation($"✅ Admin created new employee: {employee.LastName} {employee.FirstName}, Username: {dto.Username}, Role: {role.Name}");

                // Возвращаем детали
                var result = new EmployeeDetailsDto
                {
                    Id = employee.Id,
                    FirstName = employee.FirstName,
                    LastName = employee.LastName,
                    Patronymic = employee.Patronymic,
                    Phone = "", // Пустая строка, так как столбец Phone может отсутствовать в БД
                    FullName = $"{employee.LastName} {employee.FirstName} {employee.Patronymic}".Trim(),
                    UserId = user.Id,
                    Username = user.Username,
                    RoleName = role.Name,
                    RoleId = role.Id,
                    AcceptedRequestsCount = 0,
                    AssignedRequestsCount = 0
                };

                return CreatedAtAction(nameof(GetEmployeeById), new { id = employee.Id }, result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating employee");
                var errorMessage = ex.InnerException?.Message ?? ex.Message;
                _logger.LogError($"Inner exception: {ex.InnerException}");
                return StatusCode(500, $"Ошибка создания сотрудника: {errorMessage}");
            }
        }

        // GET: api/Admin/employees/5 - Получить сотрудника по ID
        [HttpGet("employees/{id}")]
        public async Task<ActionResult<EmployeeDetailsDto>> GetEmployeeById(int id)
        {
            try
            {
                // Используем явный Select без Phone, чтобы избежать ошибки если столбец не существует
                var employeeData = await _context.Employees
                    .Where(e => e.Id == id)
                    .Select(e => new
                    {
                        e.Id,
                        e.FirstName,
                        e.LastName,
                        e.Patronymic,
                        AcceptedCount = e.AcceptedRequests.Count,
                        AssignedCount = e.AssignedRequests.Count
                    })
                    .FirstOrDefaultAsync();

                if (employeeData == null)
                {
                    return NotFound($"Сотрудник с ID {id} не найден");
                }

                var user = await _context.Users
                    .Include(u => u.Role)
                    .FirstOrDefaultAsync(u => u.EmployeeId == id);

                var dto = new EmployeeDetailsDto
                {
                    Id = employeeData.Id,
                    FirstName = employeeData.FirstName,
                    LastName = employeeData.LastName,
                    Patronymic = employeeData.Patronymic,
                    Phone = "", // Пустая строка, так как столбец Phone может отсутствовать в БД
                    FullName = $"{employeeData.LastName} {employeeData.FirstName} {employeeData.Patronymic}".Trim(),
                    UserId = user?.Id,
                    Username = user?.Username,
                    RoleName = user?.Role?.Name,
                    RoleId = user?.RoleId,
                    AcceptedRequestsCount = employeeData.AcceptedCount,
                    AssignedRequestsCount = employeeData.AssignedCount
                };

                return Ok(dto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting employee {id}");
                return StatusCode(500, $"Ошибка получения сотрудника: {ex.Message}");
            }
        }

        // PUT: api/Admin/employees/5 - Обновить сотрудника (только для Админа)
        [HttpPut("employees/{id}")]
        public async Task<ActionResult<EmployeeDetailsDto>> UpdateEmployee(int id, [FromBody] UpdateEmployeeDto dto)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            try
            {
                var employee = await _employeeRepository.GetByIdAsync(id);
                if (employee == null)
                {
                    return NotFound($"Сотрудник с ID {id} не найден");
                }

                // Проверяем что username не занят другим пользователем
                var existingUser = await _userRepository.GetByUsernameAsync(dto.Username);
                var currentUser = await _context.Users.FirstOrDefaultAsync(u => u.EmployeeId == id);
                if (existingUser != null && existingUser.Id != currentUser?.Id)
                {
                    return BadRequest($"Пользователь с именем '{dto.Username}' уже существует");
                }

                // Проверяем что роль существует
                var role = await _roleRepository.GetByIdAsync(dto.RoleId);
                if (role == null)
                {
                    return BadRequest($"Роль с ID {dto.RoleId} не найдена");
                }

                // Обновляем данные сотрудника
                employee.FirstName = dto.FirstName;
                employee.LastName = dto.LastName;
                employee.Patronymic = dto.Patronymic ?? ""; // В БД Patronymic обязателен, поэтому используем пустую строку если null
                
                // Phone не используется в БД, не обновляем его

                _employeeRepository.Update(employee);
                await _employeeRepository.SaveAsync();

                // Обновляем или создаем пользователя
                if (currentUser == null)
                {
                    // Создаем нового пользователя если его нет
                    currentUser = new User
                    {
                        Username = dto.Username,
                        PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password ?? "default123"),
                        EmployeeId = employee.Id,
                        RoleId = dto.RoleId
                    };
                    await _context.Users.AddAsync(currentUser);
                }
                else
                {
                    // Обновляем существующего пользователя
                    currentUser.Username = dto.Username;
                    currentUser.RoleId = dto.RoleId;
                    
                    // Обновляем пароль только если он указан
                    if (!string.IsNullOrWhiteSpace(dto.Password))
                    {
                        currentUser.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password);
                    }
                }

                await _context.SaveChangesAsync();

                _logger.LogInformation($"✅ Admin updated employee: {employee.LastName} {employee.FirstName}, Username: {dto.Username}, Role: {role.Name}");

                // Возвращаем обновленные детали (без Phone, чтобы избежать ошибки)
                var updatedEmployeeData = await _context.Employees
                    .Where(e => e.Id == id)
                    .Select(e => new
                    {
                        e.Id,
                        e.FirstName,
                        e.LastName,
                        e.Patronymic,
                        AcceptedCount = e.AcceptedRequests.Count,
                        AssignedCount = e.AssignedRequests.Count
                    })
                    .FirstOrDefaultAsync();

                var updatedUser = await _context.Users
                    .Include(u => u.Role)
                    .FirstOrDefaultAsync(u => u.EmployeeId == id);

                var result = new EmployeeDetailsDto
                {
                    Id = updatedEmployeeData!.Id,
                    FirstName = updatedEmployeeData.FirstName,
                    LastName = updatedEmployeeData.LastName,
                    Patronymic = updatedEmployeeData.Patronymic,
                    Phone = "", // Пустая строка, так как столбец Phone может отсутствовать в БД
                    FullName = $"{updatedEmployeeData.LastName} {updatedEmployeeData.FirstName} {updatedEmployeeData.Patronymic}".Trim(),
                    UserId = updatedUser?.Id,
                    Username = updatedUser?.Username,
                    RoleName = updatedUser?.Role?.Name,
                    RoleId = updatedUser?.RoleId,
                    AcceptedRequestsCount = updatedEmployeeData.AcceptedCount,
                    AssignedRequestsCount = updatedEmployeeData.AssignedCount
                };

                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error updating employee {id}");
                return StatusCode(500, $"Ошибка обновления сотрудника: {ex.Message}");
            }
        }

        // DELETE: api/Admin/employees/5 - Удалить сотрудника (только для Админа)
        [HttpDelete("employees/{id}")]
        public async Task<IActionResult> DeleteEmployee(int id)
        {
            try
            {
                var employee = await _context.Employees
                    .Include(e => e.AcceptedRequests)
                    .Include(e => e.AssignedRequests)
                    .FirstOrDefaultAsync(e => e.Id == id);

                if (employee == null)
                {
                    return NotFound($"Сотрудник с ID {id} не найден");
                }

                // Проверяем нет ли активных обращений
                var activeRequests = employee.AcceptedRequests?.Count(r => r.RequestStatusId != 4 && r.RequestStatusId != 5) ?? 0;
                if (activeRequests > 0)
                {
                    return BadRequest($"Невозможно удалить сотрудника. У него есть {activeRequests} активных обращений. Сначала переназначьте их.");
                }

                // Удаляем пользователя (если есть)
                var user = await _context.Users.FirstOrDefaultAsync(u => u.EmployeeId == id);
                if (user != null)
                {
                    _context.Users.Remove(user);
                }

                // Удаляем сотрудника
                _employeeRepository.Remove(employee);
                await _employeeRepository.SaveAsync();

                _logger.LogInformation($"✅ Admin deleted employee: {employee.LastName} {employee.FirstName} (ID: {id})");

                return Ok(new { message = "Сотрудник удален", employeeId = id });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error deleting employee {id}");
                return StatusCode(500, $"Ошибка удаления сотрудника: {ex.Message}");
            }
        }

        // GET: api/Admin/roles - Получить список ролей
        [HttpGet("roles")]
        public async Task<ActionResult<IEnumerable<Role>>> GetRoles()
        {
            try
            {
                var roles = await _roleRepository.GetAllAsync();
                return Ok(roles);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting roles");
                return StatusCode(500, $"Ошибка получения ролей: {ex.Message}");
            }
        }

        // GET: api/Admin/stats - Статистика системы (только для Админа)
        [HttpGet("stats")]
        public async Task<ActionResult<object>> GetSystemStats()
        {
            try
            {
                var totalEmployees = await _context.Employees.CountAsync();
                var totalOperators = await _context.Users.CountAsync(u => u.RoleId == 1);
                var totalAdmins = await _context.Users.CountAsync(u => u.RoleId == 3);
                var totalRequests = await _context.CitizenRequests.CountAsync();
                var totalCitizens = await _context.Citizens.CountAsync();
                
                var activeRequests = await _context.CitizenRequests
                    .CountAsync(r => r.RequestStatusId != 4 && r.RequestStatusId != 5);
                
                var completedRequests = await _context.CitizenRequests
                    .CountAsync(r => r.RequestStatusId == 4);

                return Ok(new
                {
                    employees = new
                    {
                        total = totalEmployees,
                        operators = totalOperators,
                        admins = totalAdmins
                    },
                    requests = new
                    {
                        total = totalRequests,
                        active = activeRequests,
                        completed = completedRequests
                    },
                    citizens = new
                    {
                        total = totalCitizens
                    }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting system stats");
                return StatusCode(500, $"Ошибка получения статистики: {ex.Message}");
            }
        }
    }
}

