using System;
using System.Threading.Tasks;
using System.Text.Json;
using MvdBackend.Data;
using MvdBackend.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Http;

namespace MvdBackend.Services
{
    public class AuditService : IAuditService
    {
        private readonly AppDbContext _context;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly ILogger<AuditService> _logger;

        public AuditService(AppDbContext context, IHttpContextAccessor httpContextAccessor, ILogger<AuditService> logger)
        {
            _context = context;
            _httpContextAccessor = httpContextAccessor;
            _logger = logger;
        }

        public async Task LogActionAsync(string action, string entityType, int entityId, string? oldValues = null, string? newValues = null, int? userId = null, int? requestId = null)
        {
            try
            {
                var ipAddress = _httpContextAccessor.HttpContext?.Connection?.RemoteIpAddress?.ToString();

                var log = new AuditLog
                {
                    Action = action,
                    EntityType = entityType,
                    EntityId = entityId,
                    OldValues = oldValues,
                    NewValues = newValues,
                    UserId = userId,
                    CitizenRequestId = requestId,
                    IpAddress = ipAddress,
                    CreatedAt = DateTime.UtcNow
                };

                _context.AuditLogs.Add(log);
                await _context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to write audit log");
            }
        }

        public async Task LogRequestStatusChangeAsync(int requestId, string oldStatus, string newStatus, int? userId = null)
        {
            await LogActionAsync(
                "STATUS_CHANGE",
                "CitizenRequest",
                requestId,
                oldValues: JsonSerializer.Serialize(new { Status = oldStatus }),
                newValues: JsonSerializer.Serialize(new { Status = newStatus }),
                userId: userId,
                requestId: requestId
            );
        }
    }
}
