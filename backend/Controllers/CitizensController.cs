using Microsoft.AspNetCore.Mvc;
using MvdBackend.Models;
using MvdBackend.Repositories;

namespace MvdBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CitizensController : ControllerBase
    {
        private readonly ICitizenRepository _citizenRepository;

        public CitizensController(ICitizenRepository citizenRepository)
        {
            _citizenRepository = citizenRepository;
        }

        // GET: api/Citizens
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Citizen>>> GetCitizens()
        {
            var citizens = await _citizenRepository.GetAllAsync();
            return Ok(citizens);
        }

        // GET: api/Citizens/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Citizen>> GetCitizen(int id)
        {
            var citizen = await _citizenRepository.GetByIdAsync(id);

            if (citizen == null)
            {
                return NotFound();
            }

            return citizen;
        }

        // POST: api/Citizens
        [HttpPost]
        public async Task<ActionResult<Citizen>> PostCitizen(Citizen citizen)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            try
            {
                await _citizenRepository.AddAsync(citizen);
                await _citizenRepository.SaveAsync();

                return CreatedAtAction("GetCitizen", new { id = citizen.Id }, citizen);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Ошибка создания гражданина: {ex.Message}");
            }
        }

        // PUT: api/Citizens/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutCitizen(int id, Citizen citizen)
        {
            if (id != citizen.Id)
            {
                return BadRequest();
            }

            _citizenRepository.Update(citizen);
            await _citizenRepository.SaveAsync();

            return NoContent();
        }

        // DELETE: api/Citizens/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteCitizen(int id)
        {
            var citizen = await _citizenRepository.GetByIdAsync(id);
            if (citizen == null)
            {
                return NotFound();
            }

            _citizenRepository.Remove(citizen);
            await _citizenRepository.SaveAsync();

            return NoContent();
        }
    }
}
