using Microsoft.AspNetCore.Mvc;
using MvdBackend.Models;
using MvdBackend.Repositories;
using MvdBackend.DTOs;
using Microsoft.EntityFrameworkCore;
using BCrypt.Net;
namespace MvdBackend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IUserRepository _userRepository;
        private readonly ILogger<AuthController> _logger;

        public AuthController(IUserRepository userRepository, ILogger<AuthController> logger)
        {
            _userRepository = userRepository;
            _logger = logger;
        }

        [HttpPost("employee-login")]
        public async Task<IActionResult> EmployeeLogin([FromBody] LoginDto dto)
        {
            try
            {
                var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
                _logger.LogInformation("Login attempt | user: {Username} | ip: {Ip}", dto?.Username ?? "null", ip);

                if (dto == null || string.IsNullOrWhiteSpace(dto.Username))
                {
                    _logger.LogWarning("Login failed | reason: invalid_request | ip: {Ip}", ip);
                    return BadRequest("Неверный запрос");
                }

                var user = await _userRepository.GetByUsernameAsync(dto.Username);

                if (user == null)
                {
                    _logger.LogWarning("Login failed | reason: user_not_found | user: {Username} | ip: {Ip}", dto.Username, ip);
                    return Unauthorized("Неверный логин или пароль");
                }

                _logger.LogInformation("User found | userId: {UserId} | employeeId: {EmpId} | roleId: {RoleId} | ip: {Ip}", 
                    user.Id, user.EmployeeId, user.RoleId, ip);

                var verified = false;
                try
                {
                    verified = BCrypt.Net.BCrypt.Verify(dto.Password, user.PasswordHash);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "BCrypt verify error | user: {Username} | ip: {Ip}", dto.Username, ip);
                    return StatusCode(500, "Ошибка проверки пароля");
                }

                if (!verified)
                {
                    _logger.LogWarning("Login failed | reason: bad_password | user: {Username} | ip: {Ip}", dto.Username, ip);
                    return Unauthorized("Неверный логин или пароль");
                }

                // Проверяем связанные данные
                if (user.Role == null)
                {
                    _logger.LogError("User has no role assigned | userId: {UserId} | roleId: {RoleId} | ip: {Ip}", 
                        user.Id, user.RoleId, ip);
                    return StatusCode(500, $"Ошибка конфигурации: у пользователя не назначена роль (roleId: {user.RoleId})");
                }

                if (user.Employee == null)
                {
                    _logger.LogError("User has no employee assigned | userId: {UserId} | employeeId: {EmpId} | ip: {Ip}", 
                        user.Id, user.EmployeeId, ip);
                    return StatusCode(500, $"Ошибка конфигурации: у пользователя не назначен сотрудник (employeeId: {user.EmployeeId})");
                }

                var fullName = $"{user.Employee.LastName} {user.Employee.FirstName} {user.Employee.Patronymic}".Trim();
                
                _logger.LogInformation("Login success | user: {Username} | role: {Role} | employeeId: {EmpId} | fullName: {FullName} | ip: {Ip}", 
                    dto.Username, user.Role.Name, user.Employee.Id, fullName, ip);

                return Ok(new
                {
                    user.Id,
                    user.Username,
                    Role = user.Role.Name,
                    RoleId = user.RoleId, // Добавляем ID роли для проверок на фронтенде
                    Employee = new
                    {
                        user.Employee.Id,
                        FullName = fullName
                    }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during login | username: {Username} | ip: {Ip}", 
                    dto?.Username ?? "null", HttpContext.Connection.RemoteIpAddress?.ToString());
                return StatusCode(500, $"Ошибка при авторизации: {ex.Message}");
            }
        }
    }
}   
