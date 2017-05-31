program MqttTest;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {Form1},
  MQTT in '..\LIB\MQTT.pas',
  MQTTHeaders in '..\LIB\MQTTHeaders.pas',
  MQTTReadThread in '..\LIB\MQTTReadThread.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
