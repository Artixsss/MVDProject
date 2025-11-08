namespace MvdBackend.DTOs
{
    /// <summary>
    /// DTO с полной информацией о сотруднике (для администратора)
    /// </summary>
    public class EmployeeDetailsDto
    {
        public int Id { get; set; }
        public string LastName { get; set; } = "";
        public string FirstName { get; set; } = "";
        public string? Patronymic { get; set; }
        public string Phone { get; set; } = "";
        public string FullName { get; set; } = "";
        
        // Связанный пользователь
        public int? UserId { get; set; }
        public string? Username { get; set; }
        public string? RoleName { get; set; }
        public int? RoleId { get; set; }
        
        // Статистика
        public int AcceptedRequestsCount { get; set; }
        public int AssignedRequestsCount { get; set; }
    }
}

