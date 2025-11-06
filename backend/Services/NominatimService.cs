using System.Text.Json;

namespace MvdBackend.Services
{
    public interface INominatimService
    {
        Task<(double lat, double lon, string district)?> GeocodeAsync(string address);
    }

    public class NominatimService : INominatimService
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger<NominatimService> _logger;

        public NominatimService(HttpClient httpClient, ILogger<NominatimService> logger)
        {
            _httpClient = httpClient;
            _logger = logger;
            _httpClient.DefaultRequestHeaders.Add("User-Agent", "MvdBackend/1.0");
        }

        public async Task<(double lat, double lon, string district)?> GeocodeAsync(string address)
        {
            try
            {
                var url = $"https://nominatim.openstreetmap.org/search?format=json&addressdetails=1&limit=1&q={Uri.EscapeDataString(address + ", Новосибирск")}";
                _logger.LogInformation($"Calling Nominatim: {url}");

                var response = await _httpClient.GetStringAsync(url);
                var results = JsonSerializer.Deserialize<JsonElement[]>(response);

                if (results == null || results.Length == 0)
                {
                    _logger.LogWarning("No results from Nominatim");
                    return null;
                }

                var firstResult = results[0];

                // ДЕБАГ: выведем все свойства для анализа
                _logger.LogInformation($"Available properties: {string.Join(", ", firstResult.EnumerateObject().Select(p => p.Name))}");

                // Извлекаем координаты - они в строковом формате!
                if (firstResult.TryGetProperty("lat", out var latElem) &&
                    firstResult.TryGetProperty("lon", out var lonElem))
                {
                    var latString = latElem.GetString();
                    var lonString = lonElem.GetString();

                    _logger.LogInformation($"Raw coordinates - lat: '{latString}', lon: '{lonString}'");

                    if (double.TryParse(latString, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out double lat) &&
                        double.TryParse(lonString, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out double lon))
                    {
                        // Извлекаем район
                        string district = "Не определен";
                        if (firstResult.TryGetProperty("address", out var addressInfo))
                        {
                            if (addressInfo.TryGetProperty("city_district", out var districtElem))
                            {
                                district = districtElem.GetString() ?? "Не определен";
                                // Убираем "район" из названия если есть
                                district = district.Replace(" район", "").Trim();
                                _logger.LogInformation($"Found district: {district}");
                            }
                            else
                            {
                                _logger.LogWarning("city_district not found in address");
                            }
                        }

                        _logger.LogInformation($"Geocoding SUCCESS: Lat={lat}, Lon={lon}, District={district}");
                        return (lat, lon, district);
                    }
                    else
                    {
                        _logger.LogWarning($"Failed to parse coordinates: lat='{latString}', lon='{lonString}'");
                    }
                }
                else
                {
                    _logger.LogWarning("lat or lon properties not found in response");
                }

                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Nominatim geocoding");
                return null;
            }
        }
    }
}
