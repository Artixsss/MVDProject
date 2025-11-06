using MvdBackend.Models;

namespace MvdBackend.Repositories
{
    public interface IEmployeeRepository : IRepository<Employee>
    {
        Task<Employee> GetWithRequestsAsync(int id);
        Task<IEnumerable<Employee>> GetEmployeesByLastNameAsync(string lastName);
    }
}
