using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace MvdBackend.Models
{
    public class Citizen
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "Фамилия обязательна")]
        [StringLength(100, MinimumLength = 2, ErrorMessage = "Фамилия должна быть от 2 до 100 символов")]
        public string LastName { get; set; } = "";

        [Required(ErrorMessage = "Имя обязательно")]
        [StringLength(100, MinimumLength = 2, ErrorMessage = "Имя должно быть от 2 до 100 символов")]
        public string FirstName { get; set; } = "";

        [StringLength(100)]
        public string Patronymic { get; set; } = "";

        [Required(ErrorMessage = "Телефон обязателен")]
        [Phone(ErrorMessage = "Некорректный формат телефона")]
        [StringLength(20)]
        public string Phone { get; set; } = "";

        [JsonIgnore]
        public List<CitizenRequest> Requests { get; set; } = new();
    }
}
