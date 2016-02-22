using System;
using System.Configuration;
using Microsoft.Azure.Devices;

namespace IoTHubDeProvision
{
    class Program
    {
        private static RegistryManager _registry;

        static void Main(string[] args)
        {
            _registry = RegistryManager.CreateFromConnectionString(ConfigurationManager.AppSettings["IoTHubConnStr"]);
            UnRegisterDevice("[deviceid]");
            Console.ReadLine();
        }

        private static async void UnRegisterDevice(string deviceId)
        {
            try
            {
                await _registry.RemoveDeviceAsync(deviceId);
                Console.WriteLine($"Device {deviceId} has been de-provisioned.");
            }
            catch (Exception err)
            {
                Console.WriteLine(err.Message);
            }
        }
    }
}
