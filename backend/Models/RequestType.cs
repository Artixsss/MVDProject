using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace MvdBackend.Models
{
    public class RequestType
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "Название типа обращения обязательно")]
        [StringLength(200, MinimumLength = 2, ErrorMessage = "Название должно быть от 2 до 200 символов")]
        public string Name { get; set; } = "";

        [JsonIgnore]
        public List<CitizenRequest> Requests { get; set; } = new();
    }
}
