# d2c2d - Device to Cloud to Device
### A workshop for learning about Windows 10 Core IoT device development, Azure IoT Hub, Stream Analytics and automating Azure using PowerShell.

##Workshop Overview
This hands-on training program provides foundational knowledge in how to architect and implement an IoT solution using Windows 10 Core IoT hardware devices and Azure IoT Hub and Stream Analytics. Both Device to Cloud and Cloud to Device communication patterns are discussed, designed and implemented using best practices. 

At the conclusion of this workshop you will have provisioned an Azure environment using PowerShell that contains IoT Hub, Stream Analytics Jobs that identify telemetry events and alarm states, and a Service Bus Namespace and set of message queues for backend integration.
 
You will also develop a Windows 10 Core IoT application that sends telemetry and receives incoming commands as well as develop a real-time dashboard that displays incoming telemetry and has the ability to send commands to the remote device. Device Provisioning, IoT Hub monitoring and techniques for dynamic business rules will be covered.

The solution that you will build and deploy consists of the following components:

- Device: a Windows 10 IoT Core IoT solution that dynamically connects to IoT hub providing heartbeat and climate telemetry and processes several incoming commands. The device application will run on yoru local system or can be deployed to a Windows 10 Core IoT device
- Dashboard: a Windows 10 WPF application that displays registered devices, map location using Bing Maps, incoming device telemetry and alarms
- Provision API: A ReST API the provides end points for device registration with IoT Hub and DocumentDb and device manifest lookup via unique serial number. The Dashboard application registered devise and the Device application uses the API to retrieve its manifest
- IoT Hub Listener: a debugging utility that provides visibility to messages arriving from the device

And the following Azure Services

- API Management – provides proxy, policy injection and developer registration services for ReST APIs
- Service Bus Namespace – two queues are defined, one that is a target for all incoming messages, the other will have receive messages that contain data that is an alarm state, an out of range value
- IoT Hub – IoT Hub provides device registration, incoming telemetry at scale and cloud to device message services
- Stream Analytics Job – two solution uses two Stream Analytics jobs, one that handles all incoming messages routing them to one queue and the other identifies alarm states and routs those messages to another queue

