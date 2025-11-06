using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MvdBackend.Data;
using MvdBackend.DTOs;

namespace MvdBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AnalyticsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AnalyticsController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/analytics/districts
        [HttpGet("districts")]
        public async Task<ActionResult<IEnumerable<DistrictStatsDto>>> GetDistrictStats()
        {
            // Сначала вытаскиваем данные в память
            var requests = await _context.CitizenRequests
                .Include(cr => cr.District)
                .ToListAsync();

            var stats = requests
                .GroupBy(cr => cr.District != null ? cr.District.Name : "Не определен")
                .Select(g => new DistrictStatsDto
                {
                    DistrictName = g.Key,
                    RequestsCount = g.Count(),
                    AverageAiPriorityScore = g.Average(cr => ConvertAiPriorityToScore(cr.AiPriority))
                })
                .ToList();

            return Ok(stats);
        }

        // GET: api/analytics/categories
        [HttpGet("categories")]
        public async Task<ActionResult<IEnumerable<CategoryStatsDto>>> GetCategoryStats()
        {
            var requests = await _context.CitizenRequests
                .Include(cr => cr.Category)
                .ToListAsync();

            var stats = requests
                .GroupBy(cr => cr.Category != null ? cr.Category.Name : "Другое")
                .Select(g => new CategoryStatsDto
                {
                    CategoryName = g.Key,
                    RequestsCount = g.Count(),
                    AverageAiPriorityScore = g.Average(cr => ConvertAiPriorityToScore(cr.AiPriority))
                })
                .ToList();

            return Ok(stats);
        }

        // GET: api/analytics/ai
        [HttpGet("ai")]
        public async Task<ActionResult<AiStatsDto>> GetAiStats()
        {
            var total = await _context.CitizenRequests.CountAsync();
            var analyzed = await _context.CitizenRequests.CountAsync(cr => !string.IsNullOrEmpty(cr.AiCategory));
            var corrected = await _context.CitizenRequests.CountAsync(cr => cr.IsAiCorrected);

            var stats = new AiStatsDto
            {
                TotalRequests = total,
                AnalyzedRequests = analyzed,
                CorrectedRequests = corrected,
                AnalysisCoveragePercent = total > 0 ? Math.Round((double)analyzed / total * 100, 2) : 0,
                CorrectionRatePercent = analyzed > 0 ? Math.Round((double)corrected / analyzed * 100, 2) : 0
            };

            return Ok(stats);
        }

        private double ConvertAiPriorityToScore(string? priority)
        {
            return priority?.ToLower() switch
            {
                "низкий" => 1,
                "средний" => 2,
                "высокий" => 3,
                _ => 2
            };
        }
    }
}
