using System.Net.Http;
using System.Threading.Tasks;

namespace Looksfamiliar.Device.Win10CoreIoT
{
    public class Rest
    {
        public async Task<string> Get(string url)
        {
            var client = new HttpClient();
            return await client.GetStringAsync(url);
        }
    }
}