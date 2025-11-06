using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace MvdBackend.Models
{
    public class Category
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "Название категории обязательно")]
        [StringLength(200, MinimumLength = 2, ErrorMessage = "Название должно быть от 2 до 200 символов")]
        public string Name { get; set; } = "";

        [StringLength(500)]
        public string Description { get; set; } = "";

        [JsonIgnore]
        public ICollection<CitizenRequest>? CitizenRequests { get; set; }
    }
}
