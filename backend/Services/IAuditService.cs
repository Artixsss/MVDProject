using System.Threading.Tasks;

namespace MvdBackend.Services
{
    public interface IAuditService
    {
        Task LogActionAsync(string action, string entityType, int entityId, string? oldValues = null, string? newValues = null, int? userId = null, int? requestId = null);
        Task LogRequestStatusChangeAsync(int requestId, string oldStatus, string newStatus, int? userId = null);
    }
}
