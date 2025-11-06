using System;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using MvdBackend.DTOs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace MvdBackend.Services
{
    public class GeminiService : IGeminiService
    {
        private readonly HttpClient _httpClient;
        private readonly string _apiKey;
        private readonly ILogger<GeminiService> _logger;

        public GeminiService(IConfiguration configuration, ILogger<GeminiService> logger)
        {
            _apiKey = configuration["Gemini:ApiKey"] ?? throw new ArgumentNullException("Gemini API Key not found");
            _logger = logger;

            var handler = new HttpClientHandler
            {
                Proxy = new WebProxy("http://127.0.0.1:12334"),
                UseProxy = true
            };

            _httpClient = new HttpClient(handler)
            {
                Timeout = TimeSpan.FromSeconds(30)
            };
        }

        public async Task<GeminiAnalysisResponse> AnalyzeRequestAsync(string description)
        {
            try
            {
                _logger.LogInformation($"Starting AI analysis for: {description}");

                var prompt = $@"
Проанализируй текст заявления в МВД и верни ответ в формате JSON.

Текст заявления: ""{description}""

ВНИМАНИЕ: Используй только категории из базы данных:
- Имущественные преступления, Транспорт и ПДД, Общественный порядок, Бытовые конфликты,
- Угрозы и безопасность, Киберпреступления, Наркотики, Экология и животные,
- Пропавшие люди, Другое

Верни только JSON:
{{
    ""Category"": ""string"",
    ""Summary"": ""string"", 
    ""Sentiment"": ""string"",
    ""Priority"": ""string"",
    ""SuggestedAction"": ""string""
}}";

                var requestBody = new
                {
                    contents = new[]
                    {
                        new
                        {
                            parts = new[]
                            {
                                new { text = prompt }
                            }
                        }
                    },
                    generationConfig = new
                    {
                        temperature = 0.7,
                        topK = 40,
                        topP = 0.95,
                        maxOutputTokens = 1024
                    }
                };

                var json = JsonSerializer.Serialize(requestBody);
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";
                _logger.LogInformation($"Calling Gemini API: {apiUrl}");

                var request = new HttpRequestMessage(HttpMethod.Post, apiUrl);
                request.Content = content;
                request.Headers.Add("x-goog-api-key", _apiKey); // ключ в заголовке

                var response = await _httpClient.SendAsync(request);

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    _logger.LogError($"Gemini API error: {response.StatusCode}, Content: {errorContent}");
                    return GetFallbackResponse(description);
                }

                var responseContent = await response.Content.ReadAsStringAsync();
                var geminiResponse = JsonSerializer.Deserialize<GeminiResponse>(responseContent);

                var analysisText = geminiResponse?.candidates?[0].content?.parts?[0].text ?? string.Empty;
                var jsonStart = analysisText.IndexOf('{');
                var jsonEnd = analysisText.LastIndexOf('}') + 1;

                if (jsonStart >= 0 && jsonEnd > jsonStart)
                {
                    var jsonText = analysisText.Substring(jsonStart, jsonEnd - jsonStart);
                    var analysis = JsonSerializer.Deserialize<GeminiAnalysisResponse>(jsonText);
                    if (analysis != null) return analysis;
                }

                return GetFallbackResponse(description);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calling Gemini API");
                return GetFallbackResponse(description);
            }
        }

        public async Task<string> GenerateResponseAsync(string requestText)
        {
            try
            {
                var prompt = $"""
Сгенерируй официальный ответ гражданину на его заявление в МВД.
Текст заявления: "{requestText}"
Ответ должен быть:
- Официальным, но вежливым
- Кратким (3-4 предложения)
- Содержать информацию о принятых мерах
- Указывать сроки рассмотрения (5-10 дней)
- Содержать контактные данные для связи
Верни только текст ответа без комментариев.
""";

                var requestBody = new
                {
                    contents = new[]
                    {
                        new
                        {
                            parts = new[]
                            {
                                new { text = prompt }
                            }
                        }
                    },
                    generationConfig = new
                    {
                        temperature = 0.7,
                        topK = 40,
                        topP = 0.95,
                        maxOutputTokens = 1024
                    }
                };

                var json = JsonSerializer.Serialize(requestBody);
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var request = new HttpRequestMessage(HttpMethod.Post,
                    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent");
                request.Content = content;
                request.Headers.Add("x-goog-api-key", _apiKey);

                var response = await _httpClient.SendAsync(request);

                if (!response.IsSuccessStatusCode)
                    return "Ваше обращение принято к рассмотрению. Срок рассмотрения - 10 рабочих дней.";

                var responseContent = await response.Content.ReadAsStringAsync();
                var geminiResponse = JsonSerializer.Deserialize<GeminiResponse>(responseContent);

                return geminiResponse?.candidates?[0].content?.parts?[0].text
                       ?? "Ваше обращение принято к рассмотрению. Срок рассмотрения - 10 рабочих дней.";
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating response with Gemini");
                return "Ваше обращение принято к рассмотрению. Срок рассмотрения - 10 рабочих дней.";
            }
        }
        public async Task<string> DetectDistrictAsync(string location)
        {
            try
            {
                _logger.LogInformation($"Detecting district for location: {location}");

                var prompt = $"""
        Определи район Новосибирска для адреса: "{location}"
        
        Районы: Центральный, Железнодорожный, Заельцовский, Калининский, Кировский, 
                Ленинский, Октябрьский, Первомайский, Советский, Дзержинский
        
        Верни ТОЛЬКО название района. Если не уверен - верни "Не определен".
        """;

                var requestBody = new
                {
                    contents = new[]
                    {
                new
                {
                    parts = new[]
                    {
                        new { text = prompt }
                    }
                }
            },
                    generationConfig = new
                    {
                        temperature = 0.1,
                        maxOutputTokens = 50
                    }
                };

                var json = JsonSerializer.Serialize(requestBody);
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var request = new HttpRequestMessage(HttpMethod.Post,
                    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent");
                request.Content = content;
                request.Headers.Add("x-goog-api-key", _apiKey);

                var response = await _httpClient.SendAsync(request);

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning($"Gemini API error: {response.StatusCode}");
                    return "Не определен";
                }

                var responseContent = await response.Content.ReadAsStringAsync();
                var geminiResponse = JsonSerializer.Deserialize<GeminiResponse>(responseContent);

                // БЕЗОПАСНАЯ ПРОВЕРКА МАССИВА
                if (geminiResponse?.candidates?.Length > 0 &&
                    geminiResponse.candidates[0]?.content?.parts?.Length > 0)
                {
                    return geminiResponse.candidates[0].content.parts[0].text?.Trim() ?? "Не определен";
                }

                return "Не определен";
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error detecting district");
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

    // Вспомогательные классы
    public class GeminiResponse
    {
        public Candidate[] candidates { get; set; } = Array.Empty<Candidate>();
    }

    public class Candidate
    {
        public Content content { get; set; } = new Content();
    }

    public class Content
    {
        public Part[] parts { get; set; } = Array.Empty<Part>();
    }

    public class Part
    {
        public string text { get; set; } = string.Empty;
    }
}
