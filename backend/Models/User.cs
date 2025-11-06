using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace MvdBackend.Models
{
    public class User
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "Имя пользователя обязательно")]
        [StringLength(50, MinimumLength = 3, ErrorMessage = "Имя пользователя должно быть от 3 до 50 символов")]
        public string Username { get; set; } = "";

        [Required]
        [StringLength(500)]
        public string PasswordHash { get; set; } = "";

        [ForeignKey(nameof(Employee))]
        public int EmployeeId { get; set; }

        [JsonIgnore]
        public Employee Employee { get; set; } = null!;

        [ForeignKey(nameof(Role))]
        public int RoleId { get; set; }

        [JsonIgnore]
        public Role Role { get; set; } = null!;
    }
}
