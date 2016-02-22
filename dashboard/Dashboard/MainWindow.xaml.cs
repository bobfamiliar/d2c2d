using System;
using System.CodeDom;
using System.Configuration;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Threading;
using Looksfamiliar.d2c2d.MessageModels;
using Microsoft.Azure.Devices;
using Microsoft.ServiceBus.Messaging;
using Newtonsoft.Json;
using Microsoft.Maps.MapControl.WPF;
using Location = Microsoft.Maps.MapControl.WPF.Location;
using TransportType = Microsoft.Azure.Devices.TransportType;

namespace Looksfamiliar.D2C2D.Dashboard
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private readonly QueueClient _messageClient;
        private ServiceClient _serviceClient;

        public MainWindow()
        {
            InitializeComponent();
            _messageClient = QueueClient.CreateFromConnectionString(ConfigurationManager.AppSettings["ServiceBusConnStr"], "messagedrop");
            _serviceClient = ServiceClient.CreateFromConnectionString(ConfigurationManager.AppSettings["IoTHubConnStr"], TransportType.Amqp);
        }

        private void MainWindow_OnLoaded(object sender, RoutedEventArgs e)
        {
            var mapCenter = MyMap.Center;

            var messageTask = Task.Factory.StartNew(() =>
            {
                while (true)
                {
                    var message = _messageClient.Receive();
                    var messageBody = string.Empty;
                    if (message == null) continue;

                    try
                    {
                        messageBody = message.GetBody<string>();
                        var obj = JsonConvert.DeserializeObject<MessageBase>(messageBody);
                        switch (obj.MessageType)
                        {
                            case MessageTypeEnum.NotSet:
                                throw new Exception("Message Type Not Set");
                                break;
                            case MessageTypeEnum.Ping:
                                var ping = JsonConvert.DeserializeObject<Ping>(messageBody);

                                Application.Current.Dispatcher.Invoke(DispatcherPriority.Background, new ThreadStart(delegate
                                {
                                    var location = new Location(ping.Latitude, ping.Longitude);
                                    var pin = new Pushpin { Location = location };
                                    MyMap.Children.Add(pin);
                                    MyMap.Center = location;
                                    MyMap.ZoomLevel = 12;
                                    MyMap.SetView(location, 12);
                                    MyMap.Focusable = true;
                                    MyMap.Focus();
                                    PingFeed.Text += $"Ping Ack: {ping.Ack}\r\n" ;
                                }));

                                break;
                            case MessageTypeEnum.Climate:
                                var climate = JsonConvert.DeserializeObject<Climate>(messageBody);
                                Application.Current.Dispatcher.Invoke(DispatcherPriority.Background, new ThreadStart(delegate
                                {
                                    TelemetryFeed.Text += $"Timestamp {climate.Timestamp.ToLongDateString()} {climate.Timestamp.ToLongTimeString()}\r\n";
                                    TelemetryFeed.Text += $"Temperature {climate.Temperature}\r\n";
                                    TelemetryFeed.Text += $"Humidity {climate.Humidity}\r\n";
                                    TelemetryFeed.Text += $"Heat Index {climate.HeatIndex}\r\n\r\n";
                                }));
                                break;
                            case MessageTypeEnum.Command:
                                // noop
                                break;
                            default:
                                throw new ArgumentOutOfRangeException();
                        }

                        message.Complete();
                    }
                    catch (Exception err)
                    {
                        Application.Current.Dispatcher.Invoke(DispatcherPriority.Background, new ThreadStart(delegate
                        {
                            // Indicates a problem, unlock message in queue.
                            TelemetryFeed.Text += err.Message;
                            TelemetryFeed.Text += messageBody;
                            message.Abandon();
                        }));
                    }
                }
            });
        }

        private void StartButton_Click(object sender, RoutedEventArgs e)
        {
            var climateSettings = new ClimateSettings
            {
                MinHumidity = 0,
                MaxHumiditiy = 100,
                MinTemperature = 75,
                MaxTemperature = 110
            };

            var command = new Command
            {
                CommandType = CommandTypeEnum.Start,
                CommandParameters = JsonConvert.SerializeObject(climateSettings)
            };

            var json = JsonConvert.SerializeObject(command);
            var message = new Message(Encoding.ASCII.GetBytes(json));

            _serviceClient.SendAsync(ConfigurationManager.AppSettings["DeviceId"], message);
        }

        private void StopButton_Click(object sender, RoutedEventArgs e)
        {
            var command = new Command();
            command.CommandType = CommandTypeEnum.Stop;
            var json = JsonConvert.SerializeObject(command);
            var message = new Message(Encoding.ASCII.GetBytes(json));
            _serviceClient.SendAsync(ConfigurationManager.AppSettings["DeviceId"], message);
        }
    }
}
