namespace MvdBackend.DTOs
{
    public class CitizenRequestCreatedDto
    {
        public int Id { get; set; }
        public string Description { get; set; } = "";
        public string IncidentLocation { get; set; } = "";
        public string CitizenLocation { get; set; } = "";
        public int? DistrictId { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public DateTime CreatedAt { get; set; }

        public string RequestNumber { get; set; } = "";
    }
}
