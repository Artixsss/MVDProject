using Microsoft.EntityFrameworkCore;
using MvdBackend.Models;

namespace MvdBackend.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options)
            : base(options) { }

        public DbSet<Citizen> Citizens { get; set; } = null!;
        public DbSet<CitizenRequest> CitizenRequests { get; set; } = null!;
        public DbSet<RequestType> RequestTypes { get; set; } = null!;
        public DbSet<Employee> Employees { get; set; } = null!;
        public DbSet<RequestStatus> RequestStatuses { get; set; } = null!;
        public DbSet<Category> Categories { get; set; } = null!;
        public DbSet<District> Districts { get; set; } = null!;
        public DbSet<AuditLog> AuditLogs { get; set; } = null!;
        public DbSet<Role> Roles { get; set; } = null!;
        public DbSet<User> Users { get; set; } = null!;
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Конвертируем все DateTime в UTC для PostgreSQL
            foreach (var entityType in modelBuilder.Model.GetEntityTypes())
            {
                foreach (var property in entityType.GetProperties())
                {
                    if (property.ClrType == typeof(DateTime) || property.ClrType == typeof(DateTime?))
                    {
                        property.SetValueConverter(new Microsoft.EntityFrameworkCore.Storage.ValueConversion.ValueConverter<DateTime, DateTime>(
                            v => v.Kind == DateTimeKind.Utc ? v : v.ToUniversalTime(),
                            v => DateTime.SpecifyKind(v, DateTimeKind.Utc)));
                    }
                }
            }

            // Связь CitizenRequest -> Employee (кто принял)
            modelBuilder.Entity<CitizenRequest>()
                .HasOne(cr => cr.AcceptedBy)
                .WithMany(e => e.AcceptedRequests)
                .HasForeignKey(cr => cr.AcceptedById)
                .OnDelete(DeleteBehavior.Restrict);

            // Связь CitizenRequest -> Employee (кто выехал)
            modelBuilder.Entity<CitizenRequest>()
                .HasOne(cr => cr.AssignedTo)
                .WithMany(e => e.AssignedRequests)
                .HasForeignKey(cr => cr.AssignedToId)
                .OnDelete(DeleteBehavior.Restrict);

            // Связь CitizenRequest -> Citizen
            modelBuilder.Entity<CitizenRequest>()
                .HasOne(cr => cr.Citizen)
                .WithMany(c => c.Requests)
                .HasForeignKey(cr => cr.CitizenId)
                .OnDelete(DeleteBehavior.Restrict);

            // Связь CitizenRequest -> RequestType
            modelBuilder.Entity<CitizenRequest>()
                .HasOne(cr => cr.RequestType)
                .WithMany(rt => rt.Requests)
                .HasForeignKey(cr => cr.RequestTypeId)
                .OnDelete(DeleteBehavior.Restrict);

            // Связь CitizenRequest -> RequestStatus
            modelBuilder.Entity<CitizenRequest>()
                .HasOne(cr => cr.RequestStatus)
                .WithMany(rs => rs.Requests)
                .HasForeignKey(cr => cr.RequestStatusId)
                .OnDelete(DeleteBehavior.Restrict);

            // Связь CitizenRequest -> Category
            modelBuilder.Entity<CitizenRequest>()
                .HasOne(cr => cr.Category)
                .WithMany(c => c.CitizenRequests)
                .HasForeignKey(cr => cr.CategoryId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<CitizenRequest>()
             .HasOne(cr => cr.District)
             .WithMany(d => d.CitizenRequests)
             .HasForeignKey(cr => cr.DistrictId)
             .OnDelete(DeleteBehavior.Restrict);

            // Настройка геополя
            modelBuilder.Entity<CitizenRequest>()
                .Property(c => c.Location)
                .HasColumnType("geography (point)");

            modelBuilder.Entity<AuditLog>()
              .HasOne(al => al.User)
              .WithMany()
              .HasForeignKey(al => al.UserId)
              .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<AuditLog>()
           .HasOne(al => al.CitizenRequest)
           .WithMany()
           .HasForeignKey(al => al.CitizenRequestId)
           .OnDelete(DeleteBehavior.Cascade);

            // Связь User -> Employee
            modelBuilder.Entity<User>()
                .HasOne(u => u.Employee)
                .WithMany() 
                .HasForeignKey(u => u.EmployeeId)
                .OnDelete(DeleteBehavior.Cascade);

            // Связь User -> Role
            modelBuilder.Entity<User>()
                .HasOne(u => u.Role)
                .WithMany(r => r.Users)
                .HasForeignKey(u => u.RoleId)
                .OnDelete(DeleteBehavior.Restrict);

            // Игнорируем поле Phone в Employee, так как столбец не существует в БД
            modelBuilder.Entity<Employee>()
                .Ignore(e => e.Phone);
        }
    }
}
