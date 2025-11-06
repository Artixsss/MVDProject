using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace MvdBackend.Models
{
    public class AuditLog
    {
        public int Id { get; set; }

        [Required]
        public string Action { get; set; } = string.Empty; // CREATE, UPDATE, DELETE, STATUS_CHANGE
        public string EntityType { get; set; } = string.Empty; // CitizenRequest, Citizen, etc.
        public int EntityId { get; set; }
        public string? OldValues { get; set; }
        public string? NewValues { get; set; }
        public string? ChangedBy { get; set; }
        public string? IpAddress { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Навигационные свойства
        public int? UserId { get; set; }
        public Employee? User { get; set; }

        public int? CitizenRequestId { get; set; }
        public CitizenRequest? CitizenRequest { get; set; }
    }
}
