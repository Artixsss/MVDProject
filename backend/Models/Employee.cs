using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace MvdBackend.Models
{
    public class Employee
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "Фамилия сотрудника обязательна")]
        [StringLength(100, MinimumLength = 2)]
        public string LastName { get; set; } = "";

        [Required(ErrorMessage = "Имя сотрудника обязательно")]
        [StringLength(100, MinimumLength = 2)]
        public string FirstName { get; set; } = "";

        [StringLength(100)]
        public string Patronymic { get; set; } = "";

        [Phone]
        [StringLength(20)]
        public string? Phone { get; set; }

        [JsonIgnore]
        public List<CitizenRequest> AcceptedRequests { get; set; } = new();

        [JsonIgnore]
        public List<CitizenRequest> AssignedRequests { get; set; } = new();
    }
}
