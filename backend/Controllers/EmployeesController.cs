using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MvdBackend.Data;
using MvdBackend.Models;
using MvdBackend.Repositories;

namespace MvdBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class EmployeesController : ControllerBase
    {
        private readonly IEmployeeRepository _employeeRepository;
        private readonly AppDbContext _context;

        public EmployeesController(IEmployeeRepository employeeRepository, AppDbContext context)
        {
            _employeeRepository = employeeRepository;
            _context = context;
        }

        // GET: api/Employees
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Employee>>> GetEmployees()
        {
            // Используем явный Select без Phone, чтобы избежать ошибки с несуществующей колонкой
            var employees = await _context.Employees
                .Select(e => new Employee
                {
                    Id = e.Id,
                    LastName = e.LastName,
                    FirstName = e.FirstName,
                    Patronymic = e.Patronymic
                })
                .ToListAsync();
            return Ok(employees);
        }

        // GET: api/Employees/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Employee>> GetEmployee(int id)
        {
            // Используем явный Select без Phone
            var employee = await _context.Employees
                .Where(e => e.Id == id)
                .Select(e => new Employee
                {
                    Id = e.Id,
                    LastName = e.LastName,
                    FirstName = e.FirstName,
                    Patronymic = e.Patronymic
                })
                .FirstOrDefaultAsync();

            if (employee == null)
            {
                return NotFound();
            }

            return employee;
        }

        // GET: api/Employees/with-requests/5
        [HttpGet("with-requests/{id}")]
        public async Task<ActionResult<Employee>> GetEmployeeWithRequests(int id)
        {
            // Используем явный Select без Phone, но с загрузкой связанных запросов
            var employee = await _context.Employees
                .Where(e => e.Id == id)
                .Select(e => new Employee
                {
                    Id = e.Id,
                    LastName = e.LastName,
                    FirstName = e.FirstName,
                    Patronymic = e.Patronymic,
                    AcceptedRequests = e.AcceptedRequests.Select(r => new CitizenRequest
                    {
                        Id = r.Id,
                        RequestNumber = r.RequestNumber,
                        Description = r.Description,
                        CreatedAt = r.CreatedAt,
                        RequestStatusId = r.RequestStatusId
                    }).ToList(),
                    AssignedRequests = e.AssignedRequests.Select(r => new CitizenRequest
                    {
                        Id = r.Id,
                        RequestNumber = r.RequestNumber,
                        Description = r.Description,
                        CreatedAt = r.CreatedAt,
                        RequestStatusId = r.RequestStatusId
                    }).ToList()
                })
                .FirstOrDefaultAsync();

            if (employee == null)
            {
                return NotFound();
            }

            return employee;
        }

        // GET: api/Employees/search?lastName=Ива
        [HttpGet("search")]
        public async Task<ActionResult<IEnumerable<Employee>>> SearchEmployees([FromQuery] string lastName)
        {
            // Используем явный Select без Phone
            var employees = await _context.Employees
                .Where(e => e.LastName.Contains(lastName))
                .Select(e => new Employee
                {
                    Id = e.Id,
                    LastName = e.LastName,
                    FirstName = e.FirstName,
                    Patronymic = e.Patronymic
                })
                .ToListAsync();
            return Ok(employees);
        }

        // POST: api/Employees
        [HttpPost]
        public async Task<ActionResult<Employee>> PostEmployee(Employee employee)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            try
            {
                await _employeeRepository.AddAsync(employee);
                await _employeeRepository.SaveAsync();

                return CreatedAtAction("GetEmployee", new { id = employee.Id }, employee);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Ошибка создания сотрудника: {ex.Message}");
            }
        }

        // PUT: api/Employees/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutEmployee(int id, Employee employee)
        {
            if (id != employee.Id)
            {
                return BadRequest();
            }

            _employeeRepository.Update(employee);
            await _employeeRepository.SaveAsync();

            return NoContent();
        }

        // DELETE: api/Employees/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteEmployee(int id)
        {
            var employee = await _employeeRepository.GetByIdAsync(id);
            if (employee == null)
            {
                return NotFound();
            }

            _employeeRepository.Remove(employee);
            await _employeeRepository.SaveAsync();

            return NoContent();
        }
    }
}
