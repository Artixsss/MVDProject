using Microsoft.AspNetCore.Mvc;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;

namespace MvdBackend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class NetworkController : ControllerBase
    {
        [HttpGet("my-ip")]
        public async Task<IActionResult> GetMyIp()
        {
            try
            {
                var handler = new HttpClientHandler
                {
                    Proxy = new WebProxy("http://127.0.0.1:12334"),
                    UseProxy = true
                };


                using var httpClient = new HttpClient(handler);
                var ip = await httpClient.GetStringAsync("https://api.ipify.org");
                return Ok(new { PublicIp = ip });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Error = ex.Message });
            }
        }
    }
}
