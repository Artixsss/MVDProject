
public class CitizenRequestDto
{
    public int Id { get; set; }
    public int? CitizenId { get; set; }
    public int? RequestTypeId { get; set; }
    public int? CategoryId { get; set; }
    public string Description { get; set; }
    public int? AcceptedById { get; set; }
    public int? AssignedToId { get; set; }
    public DateTime? IncidentTime { get; set; }
    public DateTime CreatedAt { get; set; }
    public string IncidentLocation { get; set; }
    public string CitizenLocation { get; set; }
    public int? RequestStatusId { get; set; }
    public int? DistrictId { get; set; }
    public string RequestNumber { get; set; } = "";

    // Геоданные вместо NetTopologySuite.Geometry
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    // Поля AI
    public string AiCategory { get; set; }
    public string AiPriority { get; set; }
    public string AiSummary { get; set; }
    public string AiSuggestedAction { get; set; }
    public string AiSentiment { get; set; }
    public DateTime? AiAnalyzedAt { get; set; }
    public bool IsAiCorrected { get; set; }
    public string FinalCategory { get; set; }

  
}
