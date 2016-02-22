using System;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Looksfamiliar.d2c2d.MessageModels;
using Microsoft.Azure.Devices.Client;
using Newtonsoft.Json;

namespace Looksfamiliar.Device.Win10CoreIoT
{
    public sealed partial class MainPage : Page
    {
        private const string IotHubUri = "[iothub name].azure-devices.net";
        private const string DeviceId = "[device id]";
        private const string DeviceKey = "[device key]";

        private static Location _location;
        private static DeviceClient _deviceClient;

        private static Task _pingTask;
        private static Task _listenTask;
        private static Task _telemetryTask;
        private static bool _sendingTelemetry = false;

        public MainPage()
        {
            InitializeComponent();
        }

        private async void MainPage_OnLoaded(object sender, RoutedEventArgs e)
        {
            Status.Text = "Main Page Loaded";

            _location = await GetLocationAsync();

            Status.Text = $"Location is {_location.city}, {_location.country}";

            try
            {
                _deviceClient = DeviceClient.Create(IotHubUri,
                    AuthenticationMethodFactory.CreateAuthenticationWithRegistrySymmetricKey(DeviceId, DeviceKey),
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

        private static async Task<Location> GetLocationAsync()
        {
            var client = new HttpClient();
            var json = await client.GetStringAsync("http://ip-api.com/json");
            var location = JsonConvert.DeserializeObject<Location>(json);
            return location;
        }

        private static void StartPingTask(TextBox status)
        {
            _pingTask = Task.Factory.StartNew(async () =>
            {
                while (true)
                {
                    var ping = new Ping
                    {
                        Ack = "Windows 10 Core IoT Device is Alive",
                        Longitude = _location.lon,
                        Latitude = _location.lat
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

                    await Task.Delay(60000);
                }
            });
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
                                Ack = "Windows 10 Core IoT Device is Alive",
                                Longitude = _location.lon,
                                Latitude = _location.lat
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
                                // not sure this will work as we are executing on bacground thread and UI element is on UI thread
                                status.Text = errMessage; 
                            }
                            break;
                        case CommandTypeEnum.Start:
                            var settings = JsonConvert.DeserializeObject<ClimateSettings>(command.CommandParameters);
                            _sendingTelemetry = true;
                            StartTelemetry(settings, status);
                            break;
                        case CommandTypeEnum.Stop:
                            _sendingTelemetry = false;
                            break;
                        case CommandTypeEnum.UpdateFirmeware:
                            break;
                        default:
                            throw new ArgumentOutOfRangeException();
                    }

                    await _deviceClient.CompleteAsync(message);
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
                        Temperature = random.Next((int) settings.MinTemperature, (int) settings.MaxTemperature),
                        Humidity = random.Next((int) settings.MinHumidity, (int) settings.MaxHumiditiy)
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