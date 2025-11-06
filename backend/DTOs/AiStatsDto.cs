namespace MvdBackend.DTOs
{

    public class AiStatsDto
    {
        public int TotalRequests { get; set; }
        public int AnalyzedRequests { get; set; }
        public int CorrectedRequests { get; set; }
        public double AnalysisCoveragePercent { get; set; }
        public double CorrectionRatePercent { get; set; }
    }
}