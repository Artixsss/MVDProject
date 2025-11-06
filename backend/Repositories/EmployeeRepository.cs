using Microsoft.EntityFrameworkCore;
using MvdBackend.Data;
using MvdBackend.Models;

namespace MvdBackend.Repositories
{
    public class EmployeeRepository : Repository<Employee>, IEmployeeRepository
    {
        public EmployeeRepository(AppDbContext context) : base(context)
        {
        }

        public async Task<Employee> GetWithRequestsAsync(int id)
        {
            // Используем явный Select без Phone, чтобы избежать ошибки с несуществующей колонкой
            return await _context.Employees
                .Where(e => e.Id == id)
                .Select(e => new Employee
                {
                    Id = e.Id,
                    LastName = e.LastName,
                    FirstName = e.FirstName,
                    Patronymic = e.Patronymic,
                    AcceptedRequests = e.AcceptedRequests.ToList(),
                    AssignedRequests = e.AssignedRequests.ToList()
                })
                .FirstOrDefaultAsync() ?? throw new KeyNotFoundException($"Employee with id {id} not found");
        }

        public async Task<IEnumerable<Employee>> GetEmployeesByLastNameAsync(string lastName)
        {
            // Используем явный Select без Phone
            return await _context.Employees
                .Where(e => e.LastName.Contains(lastName))
                .Select(e => new Employee
                {
                    Id = e.Id,
                    LastName = e.LastName,
                    FirstName = e.FirstName,
                    Patronymic = e.Patronymic
                })
                .ToListAsync();
        }
    }
}
