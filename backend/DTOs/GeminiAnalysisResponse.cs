namespace MvdBackend.DTOs
{
    public class GeminiAnalysisResponse
    {
        public string Category { get; set; } = string.Empty;
        public string Summary { get; set; } = string.Empty;
        public string Sentiment { get; set; } = string.Empty;
        public string Priority { get; set; } = string.Empty;
        public string SuggestedAction { get; set; } = string.Empty;
    }
}
