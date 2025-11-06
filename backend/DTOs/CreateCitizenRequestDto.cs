namespace MvdBackend.DTOs
{
    public class CreateCitizenRequestDto
    {
        public int CitizenId { get; set; }
        public int RequestTypeId { get; set; }
        public int CategoryId { get; set; }
        public string Description { get; set; } = "";
        public int AcceptedById { get; set; }
        public int AssignedToId { get; set; }
        public DateTime IncidentTime { get; set; }
        public string IncidentLocation { get; set; } = "";
        public string CitizenLocation { get; set; } = "";
        public int RequestStatusId { get; set; }
    }
}
