using Microsoft.AspNetCore.Mvc;
using MvdBackend.Models;
using MvdBackend.Repositories;

namespace MvdBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RequestTypesController : ControllerBase
    {
        private readonly IRequestTypeRepository _requestTypeRepository;

        public RequestTypesController(IRequestTypeRepository requestTypeRepository)
        {
            _requestTypeRepository = requestTypeRepository;
        }

        // GET: api/RequestTypes
        [HttpGet]
        public async Task<ActionResult<IEnumerable<RequestType>>> GetRequestTypes()
        {
            var requestTypes = await _requestTypeRepository.GetAllAsync();
            return Ok(requestTypes);
        }

        // GET: api/RequestTypes/5
        [HttpGet("{id}")]
        public async Task<ActionResult<RequestType>> GetRequestType(int id)
        {
            var requestType = await _requestTypeRepository.GetByIdAsync(id);

            if (requestType == null)
            {
                return NotFound();
            }

            return requestType;
        }

        // GET: api/RequestTypes/with-requests/5
        [HttpGet("with-requests/{id}")]
        public async Task<ActionResult<RequestType>> GetRequestTypeWithRequests(int id)
        {
            var requestType = await _requestTypeRepository.GetWithRequestsAsync(id);

            if (requestType == null)
            {
                return NotFound();
            }

            return requestType;
        }

        // POST: api/RequestTypes
        [HttpPost]
        public async Task<ActionResult<RequestType>> PostRequestType(RequestType requestType)
        {
            await _requestTypeRepository.AddAsync(requestType);
            await _requestTypeRepository.SaveAsync();

            return CreatedAtAction("GetRequestType", new { id = requestType.Id }, requestType);
        }

        // PUT: api/RequestTypes/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutRequestType(int id, RequestType requestType)
        {
            if (id != requestType.Id)
            {
                return BadRequest();
            }

            _requestTypeRepository.Update(requestType);
            await _requestTypeRepository.SaveAsync();

            return NoContent();
        }

        // DELETE: api/RequestTypes/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteRequestType(int id)
        {
            var requestType = await _requestTypeRepository.GetByIdAsync(id);
            if (requestType == null)
            {
                return NotFound();
            }

            _requestTypeRepository.Remove(requestType);
            await _requestTypeRepository.SaveAsync();

            return NoContent();
        }
    }
}
