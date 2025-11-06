using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace MvdBackend.Models
{
    public class RequestStatus
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "Название статуса обязательно")]
        [StringLength(100, MinimumLength = 2, ErrorMessage = "Название должно быть от 2 до 100 символов")]
        public string Name { get; set; } = "";

        [JsonIgnore]
        public List<CitizenRequest> Requests { get; set; } = new();
    }
}
