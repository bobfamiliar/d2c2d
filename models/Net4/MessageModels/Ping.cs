namespace Looksfamiliar.d2c2d.MessageModels
{
    public class Ping : MessageBase
    {
        public Ping() { MessageType = MessageTypeEnum.Ping; Ack = string.Empty; }
        public string Ack { get; set; }
    }
}
