using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;
using NetTopologySuite.Geometries;

namespace MvdBackend.Models
{
    public class CitizenRequest
    {
        public int Id { get; set; }

        [ForeignKey(nameof(Citizen))]
        public int CitizenId { get; set; }

        [JsonIgnore]
        public Citizen Citizen { get; set; } = null!;

        [ForeignKey(nameof(RequestType))]
        public int RequestTypeId { get; set; }

        [JsonIgnore]
        public RequestType RequestType { get; set; } = null!;

        [ForeignKey(nameof(Category))]
        public int CategoryId { get; set; }

        [JsonIgnore]
        public Category Category { get; set; } = null!;

        [Required(ErrorMessage = "Описание обязательно")]
        [StringLength(5000, MinimumLength = 10, ErrorMessage = "Описание должно быть от 10 до 5000 символов")]
        public string Description { get; set; } = "";

        [ForeignKey(nameof(AcceptedBy))]
        public int AcceptedById { get; set; }

        [JsonIgnore]
        public Employee AcceptedBy { get; set; } = null!;

        [ForeignKey(nameof(AssignedTo))]
        public int? AssignedToId { get; set; }

        [JsonIgnore]
        public Employee? AssignedTo { get; set; }

        [Required]
        public DateTime IncidentTime { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Required(ErrorMessage = "Адрес инцидента обязателен")]
        [StringLength(500, ErrorMessage = "Адрес не должен превышать 500 символов")]
        public string IncidentLocation { get; set; } = "";

        [StringLength(500, ErrorMessage = "Адрес не должен превышать 500 символов")]
        public string CitizenLocation { get; set; } = "";

        [Required]
        [StringLength(20)]
        public string RequestNumber { get; set; } = "";
        
        public DateTime? UpdatedAt { get; set; }

        [ForeignKey(nameof(RequestStatus))]
        public int RequestStatusId { get; set; }

        [JsonIgnore]
        public RequestStatus RequestStatus { get; set; } = null!;

        [ForeignKey(nameof(District))]
        public int? DistrictId { get; set; }

        [JsonIgnore]
        public District? District { get; set; }

        // PostGIS Point для географических координат
        public Point? Location { get; set; }

        // AI-анализ
        [StringLength(200)]
        public string? AiCategory { get; set; }

        [StringLength(50)]
        public string? AiPriority { get; set; }

        [StringLength(1000)]
        public string? AiSummary { get; set; }

        [StringLength(1000)]
        public string? AiSuggestedAction { get; set; }

        [StringLength(50)]
        public string? AiSentiment { get; set; }

        public DateTime? AiAnalyzedAt { get; set; }

        public bool IsAiCorrected { get; set; }

        [StringLength(200)]
        public string? FinalCategory { get; set; }
    }
}
