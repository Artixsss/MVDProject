using MvdBackend.Data;
using Microsoft.EntityFrameworkCore;
using MvdBackend.Repositories;
using MvdBackend.Models;
using System.Text.Json.Serialization;
using MvdBackend.Services;
using Microsoft.AspNetCore.Diagnostics;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
        options.JsonSerializerOptions.WriteIndented = true;
        options.JsonSerializerOptions.NumberHandling = JsonNumberHandling.AllowNamedFloatingPointLiterals;
    });

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Database
// Database
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"),
        x => x.UseNetTopologySuite()));  

// Repositories
builder.Services.AddScoped<ICitizenRepository, CitizenRepository>();
builder.Services.AddScoped<ICitizenRequestRepository, CitizenRequestRepository>();
builder.Services.AddScoped<IEmployeeRepository, EmployeeRepository>();
builder.Services.AddScoped<IRequestTypeRepository, RequestTypeRepository>();
builder.Services.AddScoped<IRequestStatusRepository, RequestStatusRepository>();
builder.Services.AddScoped<ICategoryRepository, CategoryRepository>();
builder.Services.AddScoped<IDistrictRepository, DistrictRepository>();
builder.Services.AddScoped<IRepository<Citizen>, Repository<Citizen>>();
builder.Services.AddScoped<IRepository<Employee>, Repository<Employee>>();
builder.Services.AddScoped<IRepository<RequestType>, Repository<RequestType>>();
builder.Services.AddScoped<IRepository<RequestStatus>, Repository<RequestStatus>>();
builder.Services.AddScoped<IRepository<Category>, Repository<Category>>();
builder.Services.AddScoped<IRepository<District>, Repository<District>>();
builder.Services.AddScoped<IRepository<Role>, Repository<Role>>();
builder.Services.AddScoped<IRepository<User>, Repository<User>>();
builder.Services.AddScoped<IRoleRepository, RoleRepository>(); 
builder.Services.AddScoped<IUserRepository, UserRepository>(); 
// Services
builder.Services.AddHttpClient<IGeminiService, GeminiService>();
builder.Services.AddHttpClient<INominatimService, NominatimService>();
builder.Services.AddScoped<IGeminiService, GeminiService>();
builder.Services.AddScoped<INominatimService, NominatimService>();
builder.Services.AddScoped<IAuditService, AuditService>();
builder.Services.AddHttpContextAccessor();

// CORS - разрешить ВСЕ подключения (для разработки и продакшена)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy
            .SetIsOriginAllowed(_ => true) // Разрешить любые источники
            .AllowAnyMethod() // Разрешить все HTTP методы
            .AllowAnyHeader() // Разрешить все заголовки
            .AllowCredentials() // Разрешить credentials
            .WithExposedHeaders("*"); // Разрешить все заголовки в ответе
    });
}); 

var app = builder.Build();

// Initialize seed data
using (var scope = app.Services.CreateScope())
{
    try
    {
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        SeedData.Initialize(context);
    }
    catch (Exception ex)
    {
        var seedLogger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
        seedLogger.LogError(ex, "Error initializing seed data");
    }
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "MVD API v1");
        c.RoutePrefix = string.Empty; // Swagger UI at root
    });
}

// ВАЖНО: Порядок middleware имеет значение!
app.UseRouting();

// CORS - разрешить все подключения (должен быть перед UseAuthorization)
app.UseCors("AllowAll");

// Https редирект (отключен для разработки, чтобы избежать проблем с сертификатами)
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

// Авторизация (если нужно в будущем)
app.UseAuthorization();

// Endpoints
app.MapControllers();

// Health check endpoint
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }))
    .WithName("HealthCheck")
    .WithTags("Health");

// Log startup information
var logger = app.Services.GetRequiredService<ILogger<Program>>();
logger.LogInformation("======================================");
logger.LogInformation("MVD Backend API Starting");
logger.LogInformation("Environment: {Environment}", app.Environment.EnvironmentName);
logger.LogInformation("CORS: All origins allowed");
logger.LogInformation("Swagger: {SwaggerUrl}", app.Environment.IsDevelopment() ? "http://localhost:5029" : "disabled");
logger.LogInformation("======================================");

try
{
    app.Run();
}
catch (Exception ex)
{
    logger.LogCritical(ex, "Application terminated unexpectedly");
    throw;
}
