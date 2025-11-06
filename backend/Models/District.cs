using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace MvdBackend.Models
{
    public class District
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "Название района обязательно")]
        [StringLength(200, MinimumLength = 2, ErrorMessage = "Название должно быть от 2 до 200 символов")]
        public string Name { get; set; } = string.Empty;

        [StringLength(1000)]
        public string Description { get; set; } = string.Empty;

        [JsonIgnore]
        public ICollection<CitizenRequest> CitizenRequests { get; set; } = new List<CitizenRequest>();
    }
}
