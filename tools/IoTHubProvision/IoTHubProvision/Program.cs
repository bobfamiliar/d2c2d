using System;
using System.Configuration;
using System.IO;
using System.Threading.Tasks;
using Microsoft.Azure.Devices;

namespace IioTHubProvision
{
    class Program
    {
        private static RegistryManager _registry;

        private static void Main(string[] args)
        {
            _registry = RegistryManager.CreateFromConnectionString(ConfigurationManager.AppSettings["IoTHubConnStr"]);
            var deviceId = $"d2c2d-{Guid.NewGuid()}";
            var device = RegisterDevice(deviceId).Result;
            if (device != null)
            {
                File.AppendAllText(Directory.GetCurrentDirectory() + "\\deviceInfo.txt", "\r\n");
                File.AppendAllText(Directory.GetCurrentDirectory() + "\\deviceInfo.txt", deviceId + "\r\n");
                File.AppendAllText(Directory.GetCurrentDirectory() + "\\deviceInfo.txt", device.Authentication.SymmetricKey.PrimaryKey + "\r\n");
                Console.WriteLine(deviceId);
                Console.WriteLine(device.Authentication.SymmetricKey.PrimaryKey);
            }
            Console.ReadLine();
        }

        private static async Task<Device> RegisterDevice(string deviceId)
        {
            Device device = null;
            try
            {
                device = await _registry.AddDeviceAsync(new Device(deviceId));
                Console.WriteLine($"Device {deviceId} has been provisioned.");
            }
            catch (Exception err)
            {
                Console.WriteLine(err.Message);
            }

            return device;
        }
    }
}
