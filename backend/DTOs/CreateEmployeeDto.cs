using System.ComponentModel.DataAnnotations;

namespace MvdBackend.DTOs
{
    /// <summary>
    /// DTO для создания нового сотрудника (только для Администратора)
    /// </summary>
    public class CreateEmployeeDto
    {
        [Required(ErrorMessage = "Фамилия обязательна")]
        [StringLength(100, MinimumLength = 2)]
        public string LastName { get; set; } = "";

        [Required(ErrorMessage = "Имя обязательно")]
        [StringLength(100, MinimumLength = 2)]
        public string FirstName { get; set; } = "";

        [StringLength(100)]
        public string? Patronymic { get; set; }

        // Phone не используется в базе данных, оставляем для совместимости
        [StringLength(20)]
        public string? Phone { get; set; }

        [Required(ErrorMessage = "Имя пользователя обязательно")]
        [StringLength(50, MinimumLength = 3)]
        public string Username { get; set; } = "";

        [Required(ErrorMessage = "Пароль обязателен")]
        [StringLength(100, MinimumLength = 3)]
        public string Password { get; set; } = "";

        [Required(ErrorMessage = "Роль обязательна")]
        [Range(1, 3, ErrorMessage = "RoleId должен быть 1 (Operator) или 3 (Admin)")]
        public int RoleId { get; set; }
    }
}

