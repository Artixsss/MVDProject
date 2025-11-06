namespace MvdBackend.DTOs
{
    public class SubmitCitizenRequestDto
    {
        public string FirstName { get; set; } = "";
        public string LastName { get; set; } = "";
        public string MiddleName { get; set; } = "";
        public string Phone { get; set; } = "";
        public int RequestTypeId { get; set; }
        // CategoryId теперь опционально - нейросеть определит автоматически
        public int? CategoryId { get; set; }
        public string Description { get; set; } = "";
        public string IncidentLocation { get; set; } = "";
        public string CitizenLocation { get; set; } = "";
        public DateTime IncidentTime { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
    }
}

