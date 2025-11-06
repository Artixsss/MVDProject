namespace MvdBackend.DTOs
{
    public class UpdateCitizenRequestDto
    {
        public int Id { get; set; }
        public int CitizenId { get; set; }
        public int RequestTypeId { get; set; }
        public int CategoryId { get; set; }
        public string Description { get; set; } = string.Empty;
        public int AcceptedById { get; set; }
        public int AssignedToId { get; set; }
        public DateTime IncidentTime { get; set; }
        public string IncidentLocation { get; set; } = string.Empty;
        public string CitizenLocation { get; set; } = string.Empty;
        public int RequestStatusId { get; set; }
        public int? DistrictId { get; set; }
    }
}
