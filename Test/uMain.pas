unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ToolWin,
  Vcl.ComCtrls, MQTT, MQTTReadThread;

type
  TForm1 = class(TForm)
    RichEdit1: TRichEdit;
    ToolBarMain: TToolBar;
    btnConn: TButton;
    btnDisConn: TButton;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    LabeledEdit1: TLabeledEdit;
    RichEdit2: TRichEdit;
    btnPub: TButton;
    GroupBox2: TGroupBox;
    LabeledEdit2: TLabeledEdit;
    btnSub: TButton;
    btnUnSub: TButton;
    ToolBar1: TToolBar;
    CheckBox1: TCheckBox;
    Timer1: TTimer;
    ComboBoxQos: TComboBox;
    CheckBoxRetain: TCheckBox;
    Label2: TLabel;
    LabelDup: TLabel;
    EditDup: TEdit;
    btnPing: TButton;
    Label3: TLabel;
    ComboBox1: TComboBox;
    Button1: TButton;
    procedure btnConnClick(Sender: TObject);
    procedure btnDisConnClick(Sender: TObject);
    procedure btnPingClick(Sender: TObject);
    procedure btnPubClick(Sender: TObject);
    procedure btnSubClick(Sender: TObject);
    procedure btnUnSubClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button1Click(Sender: TObject);
  private

  public
    procedure Log(strMsg: UTF8String);
    procedure OnConnAck(Sender: TObject; ReturnCode: Integer);
    procedure OnPingResp(Sender: TObject);
    procedure OnSubAck(Sender: TObject; MessageID: Integer;
      GrantedQoS: Array of Integer);
    procedure OnUnSubAck(Sender: TObject; MessageID: Integer);
    procedure OnPublish(Sender: TObject; Qos, MessageID: Integer;
      topic, payload: UTF8String);
    procedure OnPubAck(Sender: TObject; MessageID: Integer);
    procedure OnPubRec(Sender: TObject; MessageID: Integer);
    procedure OnPubRel(Sender: TObject; MessageID: Integer);
    procedure OnPubComp(Sender: TObject; MessageID: Integer);
  end;

var
  Form1: TForm1;
  MQTTClient: TMQTT;

implementation

{$R *.dfm}

procedure TForm1.btnConnClick(Sender: TObject);
begin
  if Assigned(MQTTClient) then
    MQTTClient.Free;

  MQTTClient := TMQTT.Create('127.0.0.1', 1883);
  MQTTClient.Username := 'admin';
  MQTTClient.Password := 'password';

  with MQTTClient do
  begin
    OnConnAck := Self.OnConnAck;

    OnPingResp := Self.OnPingResp; // 服务端到客户端
    OnSubAck := Self.OnSubAck;
    OnUnSubAck := Self.OnUnSubAck;

    OnPublish := Self.OnPublish;
    OnPubAck := Self.OnPubAck;;
    OnPubRec := Self.OnPubRec;
    OnPubRel := Self.OnPubRel;;
    OnPubComp := Self.OnPubComp;
  end;

  MQTTClient.Connect;
end;

procedure TForm1.btnDisConnClick(Sender: TObject);
begin
  if (Assigned(MQTTClient)) then
  begin
    MQTTClient.Disconnect;

    MQTTClient.Free;
  end;
end;

procedure TForm1.btnPingClick(Sender: TObject);
begin
  MQTTClient.PingReq;
end;

procedure TForm1.btnPubClick(Sender: TObject);
begin
  MQTTClient.Publish(LabeledEdit1.Text, RichEdit2.Text, CheckBoxRetain.Checked,
    StrToIntDef(ComboBoxQos.Text, 0));
end;

procedure TForm1.btnSubClick(Sender: TObject);
begin
  MQTTClient.Subscribe(LabeledEdit2.Text, StrToIntDef(ComboBox1.Text, 0));
end;

procedure TForm1.btnUnSubClick(Sender: TObject);
begin
  MQTTClient.Unsubscribe(LabeledEdit2.Text);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  RichEdit1.Clear;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(MQTTClient) then
  begin
    MQTTClient.Disconnect;
    MQTTClient.Free;
  end;

end;

procedure TForm1.Log(strMsg: UTF8String);
begin
  RichEdit1.Lines.Add(FormatDateTime('hh:mm:ss', Now) + ' = ' + strMsg);
  if CheckBox1.Checked then
    PostMessage(RichEdit1.Handle, WM_VSCROLL, SB_BOTTOM, 0);
end;

procedure TForm1.OnConnAck(Sender: TObject; ReturnCode: Integer);
begin
  Log('Connection Acknowledged, Return Code: ' + IntToStr(Ord(ReturnCode)));
end;

procedure TForm1.OnPingResp(Sender: TObject);
begin
  Log('OnPingResp!');
end;

procedure TForm1.OnPublish(Sender: TObject; Qos, MessageID: Integer;
  topic, payload: UTF8String);
begin
  Log('Publish Received. Topic: ' + topic + ' Payload: ' + payload + ' Qos: ' +
    IntToStr(Qos) + #13#10' MessageID: ' + IntToStr(MessageID));
  Log(IntToStr(Length(payload)));
end;

procedure TForm1.OnSubAck(Sender: TObject; MessageID: Integer;
  GrantedQoS: Array of Integer);
var
  vs: string;
  I: Integer;
begin
  vs := '';
  for I := Low(GrantedQoS) to High(GrantedQoS) do
  begin
    case GrantedQoS[I] of
      $00:
        vs := vs + '        ' + IntToStr(I) + ': 0x00 - 最大QoS 0'#13#10;
      $01:
        vs := vs + '        ' + IntToStr(I) + ': 0x01 - 成功 – 最大QoS 1'#13#10;
      $02:
        vs := vs + '        ' + IntToStr(I) + ': 0x02 - 成功 – 最大QoS 2'#13#10;
      $80:
        vs := vs + '        ' + IntToStr(I) + ': 0x80 - Failure 失败'#13#10;
    end;
  end;
  Log(Format('Sub Ack Received . MessageId:%d'#13#10 +

    '        GrantedQoS共%d项:'#13#10'%s', [MessageID, Length(GrantedQoS), vs]));

end;

procedure TForm1.OnUnSubAck(Sender: TObject; MessageID: Integer);
begin
  Log('Unsubscribe Ack Received .MessageID:' + IntToStr(MessageID));
end;

procedure TForm1.OnPubAck(Sender: TObject; MessageID: Integer);
begin
  Log('Pub Ack Received .MessageID:' + IntToStr(MessageID));
end;

procedure TForm1.OnPubRec(Sender: TObject; MessageID: Integer);
begin
  Log('Pub Rec Received .MessageID:' + IntToStr(MessageID));
end;

procedure TForm1.OnPubRel(Sender: TObject; MessageID: Integer);
begin
  Log('Pub Rel Received .MessageID:' + IntToStr(MessageID));
end;

procedure TForm1.OnPubComp(Sender: TObject; MessageID: Integer);
begin
  Log('Pub Comp Received .MessageID:' + IntToStr(MessageID));
end;

end.
