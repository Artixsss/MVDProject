using System.ComponentModel.DataAnnotations;

namespace MvdBackend.DTOs
{
    /// <summary>
    /// DTO для создания обращения оператором (когда гражданин позвонил или пришёл лично)
    /// </summary>
    public class CreateRequestByOperatorDto
    {
        // Данные гражданина
        [Required(ErrorMessage = "Имя гражданина обязательно")]
        [StringLength(100, MinimumLength = 2)]
        public string CitizenFirstName { get; set; } = "";

        [Required(ErrorMessage = "Фамилия гражданина обязательна")]
        [StringLength(100, MinimumLength = 2)]
        public string CitizenLastName { get; set; } = "";

        [StringLength(100)]
        public string? CitizenPatronymic { get; set; }

        [Required(ErrorMessage = "Телефон обязателен")]
        [Phone(ErrorMessage = "Неверный формат телефона")]
        public string CitizenPhone { get; set; } = "";

        // Данные обращения
        [Required(ErrorMessage = "Тип обращения обязателен")]
        public int RequestTypeId { get; set; }

        public int? CategoryId { get; set; } // Опционально, ИИ определит

        [Required(ErrorMessage = "Описание обязательно")]
        [StringLength(5000, MinimumLength = 10)]
        public string Description { get; set; } = "";

        [Required(ErrorMessage = "Адрес инцидента обязателен")]
        [StringLength(500)]
        public string IncidentLocation { get; set; } = "";

        [StringLength(500)]
        public string? CitizenLocation { get; set; }

        [Required(ErrorMessage = "Время инцидента обязательно")]
        public DateTime IncidentTime { get; set; }

        public double? Latitude { get; set; }
        public double? Longitude { get; set; }

        // ID оператора который создает
        [Required]
        public int OperatorId { get; set; }

        // Способ обращения
        public string ContactMethod { get; set; } = "Телефонный звонок"; // "Телефонный звонок", "Личное посещение", "Электронная почта"
    }
}

