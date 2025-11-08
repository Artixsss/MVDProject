using System;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using MvdBackend.DTOs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace MvdBackend.Services
{
    /// <summary>
    /// Сервис для работы с MiniMax через OpenRouter API
    /// Не требует VPN! Работает напрямую
    /// </summary>
    public class OpenRouterService : IGeminiService
    {
        private readonly HttpClient _httpClient;
        private readonly string _apiKey;
        private readonly ILogger<OpenRouterService> _logger;
        private const string API_URL = "https://openrouter.ai/api/v1/chat/completions";
        private const string MODEL = "minimax/minimax-m2:free"; // Бесплатная модель MiniMax M2

        public OpenRouterService(HttpClient httpClient, IConfiguration configuration, ILogger<OpenRouterService> logger)
        {
            _httpClient = httpClient;
            _apiKey = configuration["OpenRouter:ApiKey"] ?? throw new ArgumentNullException("OpenRouter API Key not found");
            _logger = logger;

            // Настройка HttpClient (БЕЗ прокси - работает напрямую!)
            _httpClient.Timeout = TimeSpan.FromSeconds(60);
        }

        public async Task<GeminiAnalysisResponse> AnalyzeRequestAsync(string description)
        {
            try
            {
                _logger.LogInformation($"Starting AI analysis with MiniMax for: {description}");

                var prompt = $@"Проанализируй текст заявления в МВД. Определи категорию и верни JSON.

Текст: ""{description}""

ВАЖНО - ПРАВИЛА КАТЕГОРИЗАЦИИ:
1. Выбери ОДНУ категорию из списка ниже
2. ""Другое"" - ТОЛЬКО для запросов информации/консультаций/документов (НЕ преступления)
3. Если описано преступление/нарушение - ОБЯЗАТЕЛЬНО выбери соответствующую категорию
4. Анализируй ПО СМЫСЛУ, а не по ключевым словам

КАТЕГОРИИ (выбери точное название):

1. ""Имущественные преступления"" - кражи, грабежи, мошенничество, угон, порча имущества
   ✓ ""украли телефон"", ""ограбили"", ""обманули на деньги"", ""разбили машину""

2. ""Транспорт и ПДД"" - ДТП, нарушения ПДД, парковка, проблемы на дороге
   ✓ ""авария"", ""нарушают ПДД"", ""припаркованы на газоне"", ""гонки по ночам""

3. ""Общественный порядок"" - хулиганство, драки, шум, беспорядки, вандализм
   ✓ ""шумят ночью"", ""драка"", ""разбили окна"", ""дебоширят"", ""мат на улице""

4. ""Бытовые конфликты"" - семейные ссоры, соседские споры, бытовое насилие
   ✓ ""муж бьёт"", ""соседи угрожают"", ""семейный конфликт"", ""спор с соседями""

5. ""Угрозы и безопасность"" - угрозы, насилие, вымогательство, нападение
   ✓ ""угрожают"", ""избили"", ""напали"", ""требуют деньги"", ""преследуют""

6. ""Киберпреступления"" - интернет-мошенничество, взлом, кража данных
   ✓ ""взломали аккаунт"", ""мошенники в интернете"", ""украли данные карты""

7. ""Наркотики"" - оборот, торговля, употребление наркотиков
   ✓ ""торгуют наркотиками"", ""подозрение в наркотиках""

8. ""Экология и животные"" - жестокость к животным, экологические нарушения
   ✓ ""издеваются над собакой"", ""свалка мусора"", ""загрязнение""

9. ""Пропавшие люди"" - розыск, поиск пропавших
   ✓ ""пропал человек"", ""не выходит на связь""

10. ""Другое"" - запросы документов/информации, консультации, вопросы о законах, жалобы на работу МВД
    ✓ ""как получить справку"", ""вопрос по закону"", ""документы о постройке"", ""жалоба на сотрудника""

Приоритет:
- ""Высокий"" - угроза жизни, насилие, тяжкие преступления
- ""Средний"" - кражи, мошенничество, ДТП, конфликты
- ""Низкий"" - шум, парковка, консультации

Верни JSON (без markdown):
{{
    ""Category"": ""точное название из списка"",
    ""Summary"": ""краткое резюме"",
    ""Sentiment"": ""Негативный/Нейтральный/Положительный"",
    ""Priority"": ""Высокий/Средний/Низкий"",
    ""SuggestedAction"": ""действия сотрудника""
}}";

                var requestBody = new
                {
                    model = MODEL,
                    messages = new[]
                    {
                        new
                        {
                            role = "user",
                            content = prompt
                        }
                    },
                    temperature = 0.3, // Низкая температура для точной классификации
                    max_tokens = 1024
                };

                var json = JsonSerializer.Serialize(requestBody);
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var request = new HttpRequestMessage(HttpMethod.Post, API_URL);
                request.Content = content;
                request.Headers.Add("Authorization", $"Bearer {_apiKey}");
                request.Headers.Add("HTTP-Referer", "https://mvd-project.local"); // Для рейтинга на openrouter.ai
                request.Headers.Add("X-Title", "MVD Request Analysis System"); // Название проекта

                _logger.LogInformation($"Calling OpenRouter API with MiniMax model: {MODEL}");

                var response = await _httpClient.SendAsync(request);

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    _logger.LogError($"OpenRouter API error: Status={response.StatusCode}, Content={errorContent}");
                    _logger.LogError($"Request URL: {API_URL}, Model: {MODEL}");
                    return GetFallbackResponse(description);
                }

                var responseContent = await response.Content.ReadAsStringAsync();
                _logger.LogInformation($"OpenRouter raw response: {responseContent}");

                var openRouterResponse = JsonSerializer.Deserialize<OpenRouterResponse>(responseContent);

                if (openRouterResponse?.choices == null || openRouterResponse.choices.Length == 0)
                {
                    _logger.LogWarning($"OpenRouter returned empty response. Full response: {responseContent}");
                    return GetFallbackResponse(description);
                }

                var analysisText = openRouterResponse.choices[0].message?.content ?? string.Empty;
                _logger.LogInformation($"Analysis text from AI: {analysisText}");
                
                // Извлекаем JSON из ответа
                var jsonStart = analysisText.IndexOf('{');
                var jsonEnd = analysisText.LastIndexOf('}') + 1;

                if (jsonStart >= 0 && jsonEnd > jsonStart)
                {
                    var jsonText = analysisText.Substring(jsonStart, jsonEnd - jsonStart);
                    _logger.LogInformation($"Extracted JSON: {jsonText}");
                    
                    try
                    {
                        var analysis = JsonSerializer.Deserialize<GeminiAnalysisResponse>(jsonText, new JsonSerializerOptions 
                        { 
                            PropertyNameCaseInsensitive = true 
                        });
                        
                        if (analysis != null)
                        {
                            _logger.LogInformation($"✅ Successfully analyzed with MiniMax: Category={analysis.Category}, Priority={analysis.Priority}");
                            return analysis;
                        }
                    }
                    catch (JsonException jsonEx)
                    {
                        _logger.LogError($"JSON parsing error: {jsonEx.Message}, JSON: {jsonText}");
                    }
                }
                else
                {
                    _logger.LogWarning($"No JSON found in response. Full text: {analysisText}");
                }

                _logger.LogWarning("Failed to parse JSON from MiniMax response - returning fallback");
                return GetFallbackResponse(description);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ Error calling OpenRouter API with MiniMax: {ex.Message}");
                _logger.LogError($"Stack trace: {ex.StackTrace}");
                return GetFallbackResponse(description);
            }
        }

        public async Task<string> GenerateResponseAsync(string requestText)
        {
            try
            {
                var prompt = $@"Сгенерируй официальный ответ гражданину на его заявление в МВД.
Текст заявления: ""{requestText}""
Ответ должен быть:
- Официальным, но вежливым
- Кратким (3-4 предложения)
- Содержать информацию о принятых мерах
- Указывать сроки рассмотрения (5-10 дней)
- Содержать контактные данные для связи
Верни только текст ответа без комментариев.";

                var requestBody = new
                {
                    model = MODEL,
                    messages = new[]
                    {
                        new
                        {
                            role = "user",
                            content = prompt
                        }
                    },
                    temperature = 0.7,
                    max_tokens = 512
                };

                var json = JsonSerializer.Serialize(requestBody);
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var request = new HttpRequestMessage(HttpMethod.Post, API_URL);
                request.Content = content;
                request.Headers.Add("Authorization", $"Bearer {_apiKey}");
                request.Headers.Add("HTTP-Referer", "https://mvd-project.local");
                request.Headers.Add("X-Title", "MVD Request Analysis System");

                var response = await _httpClient.SendAsync(request);

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning($"OpenRouter API error in GenerateResponse: {response.StatusCode}");
                    return "Ваше обращение принято к рассмотрению. Срок рассмотрения - 10 рабочих дней.";
                }

                var responseContent = await response.Content.ReadAsStringAsync();
                var openRouterResponse = JsonSerializer.Deserialize<OpenRouterResponse>(responseContent);

                return openRouterResponse?.choices?[0]?.message?.content?.Trim()
                       ?? "Ваше обращение принято к рассмотрению. Срок рассмотрения - 10 рабочих дней.";
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating response with MiniMax");
                return "Ваше обращение принято к рассмотрению. Срок рассмотрения - 10 рабочих дней.";
            }
        }

        public async Task<string> DetectDistrictAsync(string location)
        {
            try
            {
                _logger.LogInformation($"Detecting district for location: {location}");

                var prompt = $@"Определи район Новосибирска для адреса: ""{location}""
        
Районы: Центральный, Железнодорожный, Заельцовский, Калининский, Кировский, 
        Ленинский, Октябрьский, Первомайский, Советский, Дзержинский
        
Верни ТОЛЬКО название района. Если не уверен - верни ""Не определен"".";

                var requestBody = new
                {
                    model = MODEL,
                    messages = new[]
                    {
                        new
                        {
                            role = "user",
                            content = prompt
                        }
                    },
                    temperature = 0.1,
                    max_tokens = 50
                };

                var json = JsonSerializer.Serialize(requestBody);
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var request = new HttpRequestMessage(HttpMethod.Post, API_URL);
                request.Content = content;
                request.Headers.Add("Authorization", $"Bearer {_apiKey}");
                request.Headers.Add("HTTP-Referer", "https://mvd-project.local");
                request.Headers.Add("X-Title", "MVD Request Analysis System");

                var response = await _httpClient.SendAsync(request);

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning($"OpenRouter API error in DetectDistrict: {response.StatusCode}");
                    return "Не определен";
                }

                var responseContent = await response.Content.ReadAsStringAsync();
                var openRouterResponse = JsonSerializer.Deserialize<OpenRouterResponse>(responseContent);

                if (openRouterResponse?.choices?.Length > 0)
                {
                    return openRouterResponse.choices[0].message?.content?.Trim() ?? "Не определен";
                }

                return "Не определен";
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error detecting district with MiniMax");
                return "Не определен";
            }
        }

        private GeminiAnalysisResponse GetFallbackResponse(string description)
        {
            return new GeminiAnalysisResponse
            {
                Category = "Другое",
                Summary = "Автоматический анализ не выполнен. Требуется ручная обработка.",
                Sentiment = "Нейтральный",
                Priority = "Средний",
                SuggestedAction = "Назначить сотрудника для ручной обработки заявления."
            };
        }
    }

    // Классы для десериализации ответа OpenRouter API
    public class OpenRouterResponse
    {
        public string? id { get; set; }
        public string? model { get; set; }
        public Choice[]? choices { get; set; }
        public Usage? usage { get; set; }
    }

    public class Choice
    {
        public Message? message { get; set; }
        public string? finish_reason { get; set; }
    }

    public class Message
    {
        public string? role { get; set; }
        public string? content { get; set; }
    }

    public class Usage
    {
        public int prompt_tokens { get; set; }
        public int completion_tokens { get; set; }
        public int total_tokens { get; set; }
    }
}

