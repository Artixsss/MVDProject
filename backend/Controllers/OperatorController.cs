using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MvdBackend.Models;
using MvdBackend.Repositories;
using MvdBackend.DTOs;
using MvdBackend.Data;
using MvdBackend.Services;
using NetTopologySuite.Geometries;
using System.Text.Json;

namespace MvdBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OperatorController : ControllerBase
    {
        private readonly ICitizenRequestRepository _requestRepository;
        private readonly IRepository<Citizen> _citizenRepository;
        private readonly IRepository<Employee> _employeeRepository;
        private readonly IRepository<RequestStatus> _statusRepository;
        private readonly IRepository<Category> _categoryRepository;
        private readonly IDistrictRepository _districtRepository;
        private readonly IGeminiService _geminiService;
        private readonly INominatimService _nominatimService;
        private readonly IAuditService _auditService;
        private readonly AppDbContext _context;
        private readonly ILogger<OperatorController> _logger;

        public OperatorController(
            ICitizenRequestRepository requestRepository,
            IRepository<Citizen> citizenRepository,
            IRepository<Employee> employeeRepository,
            IRepository<RequestStatus> statusRepository,
            IRepository<Category> categoryRepository,
            IDistrictRepository districtRepository,
            IGeminiService geminiService,
            INominatimService nominatimService,
            IAuditService auditService,
            AppDbContext context,
            ILogger<OperatorController> logger)
        {
            _requestRepository = requestRepository;
            _citizenRepository = citizenRepository;
            _employeeRepository = employeeRepository;
            _statusRepository = statusRepository;
            _categoryRepository = categoryRepository;
            _districtRepository = districtRepository;
            _geminiService = geminiService;
            _nominatimService = nominatimService;
            _auditService = auditService;
            _context = context;
            _logger = logger;
        }

        // POST: api/Operator/create-request - Оператор создает обращение (звонок/личное посещение)
        [HttpPost("create-request")]
        public async Task<ActionResult<CitizenRequestDto>> CreateRequestByOperator([FromBody] CreateRequestByOperatorDto dto)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            try
            {
                // Проверяем что оператор существует
                var operatorEmployee = await _employeeRepository.GetByIdAsync(dto.OperatorId);
                if (operatorEmployee == null)
                {
                    return BadRequest($"Оператор с ID {dto.OperatorId} не найден");
                }

                _logger.LogInformation($"📞 Operator {operatorEmployee.LastName} creating request via {dto.ContactMethod}");

                // Находим или создаем гражданина
                var existingCitizen = await _context.Citizens
                    .FirstOrDefaultAsync(c => c.FirstName == dto.CitizenFirstName &&
                                            c.LastName == dto.CitizenLastName &&
                                            c.Phone == dto.CitizenPhone);

                if (existingCitizen == null)
                {
                    existingCitizen = new Citizen
                    {
                        FirstName = dto.CitizenFirstName,
                        LastName = dto.CitizenLastName,
                        Patronymic = dto.CitizenPatronymic,
                        Phone = dto.CitizenPhone
                    };
                    await _citizenRepository.AddAsync(existingCitizen);
                    await _citizenRepository.SaveAsync();
                    _logger.LogInformation($"Created new citizen: {existingCitizen.LastName} {existingCitizen.FirstName}");
                }

                // Получаем статус "Новое"
                var newStatus = await _statusRepository.GetAllAsync();
                var statusNew = newStatus.FirstOrDefault(s => s.Name.Contains("Нов") || s.Id == 1);
                if (statusNew == null)
                {
                    return BadRequest("Статус 'Новое' не найден");
                }

                // Создаем обращение
                var defaultCategoryId = dto.CategoryId ?? 10; // "Другое" как временная

                var request = new CitizenRequest
                {
                    CitizenId = existingCitizen.Id,
                    RequestTypeId = dto.RequestTypeId,
                    CategoryId = defaultCategoryId,
                    Description = dto.Description,
                    AcceptedById = dto.OperatorId, // Оператор принял
                    AssignedToId = dto.OperatorId, // Назначается на себя
                    IncidentTime = dto.IncidentTime.Kind == DateTimeKind.Utc
                        ? dto.IncidentTime
                        : dto.IncidentTime.ToUniversalTime(),
                    IncidentLocation = dto.IncidentLocation,
                    CitizenLocation = dto.CitizenLocation ?? "Не указан",
                    RequestStatusId = statusNew.Id,
                    CreatedAt = DateTime.UtcNow,
                    RequestNumber = Guid.NewGuid().ToString("N").Substring(0, 10).ToUpper()
                };

                // Геокодирование
                if (dto.Latitude.HasValue && dto.Longitude.HasValue)
                {
                    request.Location = new Point(dto.Longitude.Value, dto.Latitude.Value);
                }
                else
                {
                    var geocodeResult = await _nominatimService.GeocodeAsync(dto.IncidentLocation);
                    if (geocodeResult != null)
                    {
                        request.Location = new Point(geocodeResult.Value.lon, geocodeResult.Value.lat);
                        var district = await _districtRepository.GetByNameAsync(geocodeResult.Value.district);
                        if (district != null)
                        {
                            request.DistrictId = district.Id;
                        }
                    }
                }

                await _requestRepository.AddAsync(request);
                await _requestRepository.SaveAsync();

                // СИНХРОННЫЙ ИИ анализ
                try
                {
                    _logger.LogInformation($"🤖 Starting AI analysis for operator request #{request.Id}");
                    var analysis = await _geminiService.AnalyzeRequestAsync(request.Description);

                    request.AiCategory = analysis.Category;
                    request.AiPriority = analysis.Priority;
                    request.AiSummary = analysis.Summary;
                    request.AiSuggestedAction = analysis.SuggestedAction;
                    request.AiSentiment = analysis.Sentiment;
                    request.AiAnalyzedAt = DateTime.UtcNow;
                    request.FinalCategory = analysis.Category;

                    // Обновляем CategoryId если не выбрана
                    if (!dto.CategoryId.HasValue || request.CategoryId == 10)
                    {
                        var allCategories = await _categoryRepository.GetAllAsync();
                        var matchedCategory = allCategories.FirstOrDefault(c =>
                            c.Name.Equals(analysis.Category, StringComparison.OrdinalIgnoreCase));

                        if (matchedCategory != null)
                        {
                            request.CategoryId = matchedCategory.Id;
                            _logger.LogInformation($"✅ Category updated: {matchedCategory.Name}");
                        }
                    }

                    _requestRepository.Update(request);
                    await _requestRepository.SaveAsync();

                    _logger.LogInformation($"✅ Operator request #{request.Id} created and analyzed");
                }
                catch (Exception aiEx)
                {
                    _logger.LogWarning(aiEx, $"⚠️ AI analysis failed: {aiEx.Message}");
                }

                // Логируем создание
                await _auditService.LogActionAsync(
                    "CREATE_BY_OPERATOR",
                    "CitizenRequest",
                    request.Id,
                    newValues: JsonSerializer.Serialize(new
                    {
                        Description = request.Description,
                        Location = request.IncidentLocation,
                        ContactMethod = dto.ContactMethod,
                        OperatorId = dto.OperatorId
                    }),
                    userId: dto.OperatorId,
                    requestId: request.Id
                );

                // Возвращаем результат
                var responseDto = new CitizenRequestDto
                {
                    Id = request.Id,
                    CitizenId = request.CitizenId,
                    RequestTypeId = request.RequestTypeId,
                    CategoryId = request.CategoryId,
                    Description = request.Description,
                    AcceptedById = request.AcceptedById,
                    AssignedToId = request.AssignedToId,
                    IncidentTime = request.IncidentTime,
                    CreatedAt = request.CreatedAt,
                    IncidentLocation = request.IncidentLocation,
                    CitizenLocation = request.CitizenLocation,
                    RequestStatusId = request.RequestStatusId,
                    DistrictId = request.DistrictId,
                    Latitude = request.Location is Point p ? (double?)p.Y : dto.Latitude,
                    Longitude = request.Location is Point p2 ? (double?)p2.X : dto.Longitude,
                    RequestNumber = request.RequestNumber,
                    AiCategory = request.AiCategory,
                    AiPriority = request.AiPriority,
                    AiSummary = request.AiSummary,
                    AiSuggestedAction = request.AiSuggestedAction,
                    AiSentiment = request.AiSentiment,
                    AiAnalyzedAt = request.AiAnalyzedAt,
                    IsAiCorrected = request.IsAiCorrected,
                    FinalCategory = request.FinalCategory
                };

                return CreatedAtAction("GetCitizenRequest", "CitizenRequests", new { id = request.Id }, responseDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating request by operator");
                return StatusCode(500, $"Ошибка создания обращения: {ex.Message}");
            }
        }
    }
}

