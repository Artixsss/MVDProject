using MvdBackend.DTOs;

namespace MvdBackend.Services
{
    public interface IGeminiService
    {
        Task<GeminiAnalysisResponse> AnalyzeRequestAsync(string description);
        Task<string> GenerateResponseAsync(string requestText);
        Task<string> DetectDistrictAsync(string location);
    }
}
