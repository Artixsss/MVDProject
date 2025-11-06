namespace MvdBackend.DTOs
{


    public class CategoryStatsDto
    {
        public string CategoryName { get; set; } = "";
        public int RequestsCount { get; set; }
        public double AverageAiPriorityScore { get; set; }
    }
}