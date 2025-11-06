namespace MvdBackend.DTOs
{
    public class DistrictStatsDto
    {
        public string DistrictName { get; set; } = "";
        public int RequestsCount { get; set; }
        public double AverageAiPriorityScore { get; set; }
    }
}