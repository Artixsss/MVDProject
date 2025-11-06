using Microsoft.AspNetCore.Mvc;
using MvdBackend.Models;
using MvdBackend.Repositories;

namespace MvdBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DistrictsController : ControllerBase
    {
        private readonly IDistrictRepository _districtRepository;

        public DistrictsController(IDistrictRepository districtRepository)
        {
            _districtRepository = districtRepository;
        }

        // GET: api/Districts
        [HttpGet]
        public async Task<ActionResult<IEnumerable<District>>> GetDistricts()
        {
            var districts = await _districtRepository.GetAllAsync();
            return Ok(districts);
        }

        // GET: api/Districts/5
        [HttpGet("{id}")]
        public async Task<ActionResult<District>> GetDistrict(int id)
        {
            var district = await _districtRepository.GetByIdAsync(id);

            if (district == null)
            {
                return NotFound();
            }

            return district;
        }

        // GET: api/Districts/with-requests/5
        [HttpGet("with-requests/{id}")]
        public async Task<ActionResult<District>> GetDistrictWithRequests(int id)
        {
            var district = await _districtRepository.GetDistrictsWithRequestsAsync();
            var result = district.FirstOrDefault(d => d.Id == id);

            if (result == null)
            {
                return NotFound();
            }

            return result;
        }

        // POST: api/Districts
        [HttpPost]
        public async Task<ActionResult<District>> PostDistrict(District district)
        {
            await _districtRepository.AddAsync(district);
            await _districtRepository.SaveAsync();

            return CreatedAtAction("GetDistrict", new { id = district.Id }, district);
        }

        // PUT: api/Districts/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutDistrict(int id, District district)
        {
            if (id != district.Id)
            {
                return BadRequest();
            }

            _districtRepository.Update(district);
            await _districtRepository.SaveAsync();

            return NoContent();
        }

        // DELETE: api/Districts/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteDistrict(int id)
        {
            var district = await _districtRepository.GetByIdAsync(id);
            if (district == null)
            {
                return NotFound();
            }

            _districtRepository.Remove(district);
            await _districtRepository.SaveAsync();

            return NoContent();
        }
    }
}

