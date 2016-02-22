using System;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Newtonsoft.Json;

namespace Looksfamiliar.Device.Win10CoreIoT
{
    public sealed partial class MainPage : Page
    {
        private const string IotHubUri = "[iothub name].azure-devices.net";
        private const string DeviceId = "[device id]";
        private const string DeviceKey = "[device key]";

        public MainPage()
        {
            InitializeComponent();
        }

        private void MainPage_OnLoaded(object sender, RoutedEventArgs e)
        {
            Status.Text = "Main Page Loaded";
        }

    }
}