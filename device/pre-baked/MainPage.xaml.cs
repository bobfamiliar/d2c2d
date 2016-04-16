using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices.WindowsRuntime;
using Windows.Foundation;
using Windows.Foundation.Collections;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Controls.Primitives;
using Windows.UI.Xaml.Data;
using Windows.UI.Xaml.Input;
using Windows.UI.Xaml.Media;
using Windows.UI.Xaml.Navigation;
using Looksfamiliar.d2c2d.MessageModels;
using Microsoft.Azure.Devices.Client;
using Newtonsoft.Json;
using System.Threading.Tasks;
using System.Net.Http;
using System.Text;


// The Blank Page item template is documented at http://go.microsoft.com/fwlink/?LinkId=402352&clcid=0x409

namespace device
{
    /// <summary>
    /// An empty page that can be used on its own or navigated to within a Frame.
    /// </summary>
    public sealed partial class MainPage : Page
    {
        // The Device Serial Number is the serialNumber property of the sole document in your DocumentDB instance.
        //    -	Click on DocumentDb in your Resource Group
        //    -	From the menu bar, click Document Explorer to open a new blade
        //    -	Select the Device Database and the Registry Collection from the drop downs
        //    -	Click on the document in the list to open the JSON document

        private const string DeviceSerialNumber = "YOUR_DEVICE_SERIAL_NUMBER";
        private const string ProvisionApi = "https://YOUR_PROVISION_API_SERVICE_NAME.azurewebsites.net/provision/devicemanifests/id/" + DeviceSerialNumber;

        private const string AckMessage = "Windows 10 Core IoT Device is Alive";

        private static DeviceManifest _deviceManifest;
        private static DeviceClient _deviceClient;

        private static Task _pingTask;
        private static Task _listenTask;
        private static Task _telemetryTask;
        private static bool _sendingTelemetry = false;


        public MainPage()
        {
            this.InitializeComponent();
        }

        private static async Task<DeviceManifest> GetDeviceManifest()
        {
            var client = new HttpClient();
            var uriBuilder = new UriBuilder(ProvisionApi);
            var json = await client.GetStringAsync(uriBuilder.Uri);
            return JsonConvert.DeserializeObject<DeviceManifest>(json);
        }

        private async void MainPage_OnLoaded(object sender, RoutedEventArgs e)
        {
            Status.Text = "Main Page Loaded";

            try
            {
                _deviceManifest = await GetDeviceManifest();

                _deviceClient = DeviceClient.Create(
                    _deviceManifest.hub,
                    AuthenticationMethodFactory.CreateAuthenticationWithRegistrySymmetricKey(
                         _deviceManifest.serialnumber, _deviceManifest.key),
                         TransportType.Http1);

                Status.Text = "IoT Hub Connected";
            }
            catch (Exception connectionErr)
            {
                Status.Text = connectionErr.Message;
            }

            StartPingTask(Status);
            StartListenTask(Status);
        }

        private static void StartListenTask(TextBox status)
        {
            _listenTask = Task.Factory.StartNew(async () =>
            {
                while (true)
                {
                    var message = await _deviceClient.ReceiveAsync();

                    if (message == null)
                        continue;

                    var json = Encoding.ASCII.GetString(message.GetBytes());

                    var command = JsonConvert.DeserializeObject<Command>(json);

                    switch (command.CommandType)
                    {
                        case CommandTypeEnum.Ping:

                            var ping = new Ping
                            {
                                Ack = AckMessage,
                                Longitude = _deviceManifest.longitude,
                                Latitude = _deviceManifest.latitude,
                                DeviceId = _deviceManifest.serialnumber
                            };

                            json = JsonConvert.SerializeObject(ping);

                            var pingMessage = new Message(Encoding.ASCII.GetBytes(json));

                            try
                            {
                                await _deviceClient.SendEventAsync(pingMessage);
                            }
                            catch (Exception err)
                            {
                                var errMessage = err.Message;
                                status.Text = errMessage;
                            }
                            break;

                        case CommandTypeEnum.Start:
                            // the command is to start telemetry
                            // unpack the parameters that define the upper and lower bounds
                            var settings = JsonConvert.DeserializeObject<ClimateSettings>(
                                 command.CommandParameters);
                            _sendingTelemetry = true;
                            StartTelemetry(settings, status);
                            break;

                        case CommandTypeEnum.Stop:

                            _sendingTelemetry = false;
                            break;

                        case CommandTypeEnum.UpdateFirmeware:
                            // imagine
                            break;

                        default:
                            throw new ArgumentOutOfRangeException();
                    }

                    await _deviceClient.CompleteAsync(message);
                }
            });
        }


        private static void StartPingTask(TextBox status)
        {
            _pingTask = Task.Factory.StartNew(async () =>
            {
                while (true)
                {
                    var ping = new Ping
                    {
                        Ack = AckMessage,
                        Longitude = _deviceManifest.longitude,
                        Latitude = _deviceManifest.latitude,
                        DeviceId = _deviceManifest.serialnumber
                    };

                    var json = JsonConvert.SerializeObject(ping);

                    var message = new Message(Encoding.ASCII.GetBytes(json));

                    try
                    {
                        await _deviceClient.SendEventAsync(message);
                    }
                    catch (Exception err)
                    {
                        var errMessage = err.Message;
                        status.Text = errMessage;
                    }

                    await Task.Delay(10000);
                }
            });
        }

        private static void StartTelemetry(ClimateSettings settings, TextBox status)
        {
            _telemetryTask = Task.Factory.StartNew(async () =>
            {
                while (_sendingTelemetry)
                {
                    var random = new Random();

                    var climate = new Climate
                    {
                        Longitude = _deviceManifest.longitude,
                        Latitude = _deviceManifest.latitude,
                        DeviceId = _deviceManifest.serialnumber,
                        Temperature = random.Next((int)settings.MinTemperature,
                           (int)settings.MaxTemperature),
                        Humidity = random.Next((int)settings.MinHumidity,
                           (int)settings.MaxHumidity)
                    };

                    var json = JsonConvert.SerializeObject(climate);

                    var message = new Message(Encoding.ASCII.GetBytes(json));

                    try
                    {
                        await _deviceClient.SendEventAsync(message);
                    }
                    catch (Exception err)
                    {
                        var errMessage = err.Message;
                        status.Text = errMessage;
                    }

                    await Task.Delay(5000);
                }
            });
        }
    }
}
