unit MQTT;

interface

uses
  SysUtils, Types, Classes, FMX.Types, Generics.Collections, SyncObjs,
  // ==============================================================================
  // HammerOh
  // blcksock,
  IdTCPClient,
  // ==============================================================================
  MQTTHeaders, MQTTReadThread;

type
{$IF not declared(TBytes)}
  TBytes = array of Byte;
{$IFEND}

  TMQTT = class
  private
    { Private Declarations }
    FClientID: UTF8String;
    FHostname: UTF8String;
    FPort: Integer;
    FMessageID: Integer;
    FisConnected: Boolean;
    FRecvThread: TMQTTReadThread;
    FCSSock: TCriticalSection;
    FWillMsg: UTF8String;
    FWillTopic: UTF8String;
    FUsername: UTF8String;
    FPassword: UTF8String;
    // ==============================================================================
    // HammerOh
    // FSocket: TTCPBlockSocket;
    FSocket: TIdTCPClient;
    // ==============================================================================

    FKeepAliveTimer: TTimer;

    // Event Fields
    FConnAckEvent: TConnAckEvent;
    FPublishEvent: TPublishEvent;
    FPingRespEvent: TPingRespEvent;
    FPingReqEvent: TPingReqEvent;
    FSubAckEvent: TSubAckEvent;
    FUnSubAckEvent: TUnSubAckEvent;
    FPubAckEvent: TPubAckEvent;
    FPubRelEvent: TPubRelEvent;
    FPubRecEvent: TPubRecEvent;
    FPubCompEvent: TPubCompEvent;
    function WriteData(AData: TBytes): Boolean;
    function hasWill: Boolean;
    function getNextMessageId: Integer;
    // ==============================================================================
    // HammerOh
    // function createAndResumeRecvThread(Socket: TTCPBlockSocket): boolean;
    function createAndResumeRecvThread(var Socket: TIdTCPClient): Boolean;
    // ==============================================================================

    // TMQTTMessage Factory Methods.
    function ConnectMessage: TMQTTMessage;
    function DisconnectMessage: TMQTTMessage;
    function PublishMessage: TMQTTMessage;
    function PublishAck(MessageID: Integer): TMQTTMessage;
    function PublishRec(MessageID: Integer): TMQTTMessage;
    function PublishRel(MessageID: Integer): TMQTTMessage;
    function PublishComp(MessageID: Integer): TMQTTMessage;
    function PingReqMessage: TMQTTMessage;
    function SubscribeMessage: TMQTTMessage;
    function UnsubscribeMessage: TMQTTMessage;

    // Our Keep Alive Ping Timer Event
    procedure KeepAliveTimer_Event(sender: TObject);

    // Recv Thread Event Handling Procedures.
    procedure GotConnAck(sender: TObject; ReturnCode: Integer);
    procedure GotPingResp(sender: TObject);
    procedure GotSubAck(sender: TObject; MessageID: Integer;
      GrantedQoS: array of Integer);
    procedure GotUnSubAck(sender: TObject; MessageID: Integer);
    procedure GotPublish(sender: TObject; QoS, MessageID: Integer;
      topic, payload: UTF8String);
    procedure GotPubAck(sender: TObject; MessageID: Integer);
    procedure GotPubRec(sender: TObject; MessageID: Integer);
    procedure GotPubRel(sender: TObject; MessageID: Integer);
    procedure GotPubComp(sender: TObject; MessageID: Integer);

  public
    { Public Declarations }

    function Connect: Boolean;
    function Disconnect: Boolean;
    function Publish(topic: UTF8String; sPayload: UTF8String): Boolean;
      overload;
    function Publish(topic: UTF8String; sPayload: UTF8String; Retain: Boolean)
      : Boolean; overload;
    function Publish(topic: UTF8String; sPayload: UTF8String; Retain: Boolean;
      QoS: Integer): Boolean; overload;
    function Subscribe(topic: UTF8String; RequestQoS: Integer)
      : Integer; overload;
    function Subscribe(Topics: TDictionary<UTF8String, Integer>)
      : Integer; overload;
    function Unsubscribe(topic: UTF8String): Integer; overload;
    function Unsubscribe(Topics: TStringList): Integer; overload;
    function PingReq: Boolean;
    constructor Create(hostName: UTF8String; port: Integer);
    destructor Destroy; override;
    property WillTopic: UTF8String read FWillTopic write FWillTopic;
    property WillMsg: UTF8String read FWillMsg write FWillMsg;
    property Username: UTF8String read FUsername write FUsername;
    property Password: UTF8String read FPassword write FPassword;
    // Client ID is our Client Identifier.
    property ClientID: UTF8String read FClientID write FClientID;
    property isConnected: Boolean read FisConnected;

    // Event Handlers
    property OnConnAck: TConnAckEvent read FConnAckEvent write FConnAckEvent;
    property OnPublish: TPublishEvent read FPublishEvent write FPublishEvent;
    property OnPingResp: TPingRespEvent read FPingRespEvent
      write FPingRespEvent;
    property OnPingReq: TPingReqEvent read FPingReqEvent write FPingReqEvent;
    property OnSubAck: TSubAckEvent read FSubAckEvent write FSubAckEvent;
    property OnUnSubAck: TUnSubAckEvent read FUnSubAckEvent
      write FUnSubAckEvent;
    property OnPubAck: TPubAckEvent read FPubAckEvent write FPubAckEvent;
    property OnPubRec: TPubRecEvent read FPubRecEvent write FPubRecEvent;
    property OnPubRel: TPubRelEvent read FPubRelEvent write FPubRelEvent;
    property OnPubComp: TPubCompEvent read FPubCompEvent write FPubCompEvent;
  end;

implementation

{ TMQTTClient }

function TMQTT.Connect: Boolean;
var
  Msg: TMQTTMessage;
begin

  // Create socket and connect.
  // ==============================================================================
  // HammerOh
  // FSocket := TTCPBlockSocket.Create;
  FSocket := TIdTCPClient.Create(nil);
  // ==============================================================================

  try
    // ==============================================================================
    // HammerOh
    // FSocket.Connect(Self.FHostname, IntToStr(Self.FPort));
    FSocket.Host := Self.FHostname;
    FSocket.port := Self.FPort;
    FSocket.Connect;
    // ==============================================================================

    FisConnected := true;
  except
    // If we encounter an exception upon connection then reraise it, free the socket
    // and reset our isConnected flag.
    on E: Exception do
    begin
      raise;
      FisConnected := False;
      FSocket.Free;
    end;
  end;

  if FisConnected then
  begin
    Msg := ConnectMessage;
    try
      Msg.payload.AddField(Self.FClientID);
      (Msg.VariableHeader as TMQTTConnectVarHeader).WillFlag := ord(hasWill);
      if hasWill then
      begin
        Msg.payload.AddField(Self.FWillTopic);
        Msg.payload.AddField(Self.FWillMsg);
      end;

      if ((Length(FUsername) > 1) and (Length(FPassword) > 1)) then
      begin
        Msg.payload.AddField(FUsername);
        Msg.payload.AddField(FPassword);
      end;

      if WriteData(Msg.ToBytes) then
        Result := true
      else
        Result := False;
      // Start our Receive thread.
      if (Result and createAndResumeRecvThread(FSocket)) then
      begin
        // Use the KeepAlive that we just sent to determine our ping timer.
        FKeepAliveTimer.Interval :=
          (Round((Msg.VariableHeader as TMQTTConnectVarHeader).KeepAlive *
          0.80)) * 1000;
        FKeepAliveTimer.Enabled := true;
      end;

    finally
      Msg.Free;
    end;
  end;
end;

constructor TMQTT.Create(hostName: UTF8String; port: Integer);
begin
  inherited Create;

  Self.FisConnected := False;
  Self.FHostname := hostName;
  Self.FPort := port;
  Self.FMessageID := 1;
  // Randomise and create a random client id.
  Randomize;
  Self.FClientID := 'UsrClientID_' + IntToStr(Random(1000) + 1);
  FCSSock := TCriticalSection.Create;

  // Create the timer responsible for pinging.
  FKeepAliveTimer := TTimer.Create(nil);
  FKeepAliveTimer.Enabled := False;
  FKeepAliveTimer.OnTimer := KeepAliveTimer_Event;
end;

// ==============================================================================
// HammerOh
// function TMQTT.createAndResumeRecvThread(Socket: TTCPBlockSocket): boolean;
function TMQTT.createAndResumeRecvThread(var Socket: TIdTCPClient): Boolean;
// ==============================================================================
begin
  Result := False;
  try
    FRecvThread := TMQTTReadThread.Create(Socket, FCSSock);

    FRecvThread.OnConnAck := Self.GotConnAck;
    FRecvThread.OnPublish := Self.GotPublish;
    FRecvThread.OnPingResp := Self.GotPingResp;
    FRecvThread.OnSubAck := Self.GotSubAck;
    FRecvThread.OnUnSubAck := Self.GotUnSubAck;
    FRecvThread.OnPubAck := Self.GotPubAck;
    FRecvThread.OnPubRec := Self.GotPubRec;
    FRecvThread.OnPubRel := Self.GotPubRel;
    FRecvThread.OnPubComp := Self.GotPubComp;

    Result := true;
  except
    Result := False;
  end;
end;

destructor TMQTT.Destroy;
begin
  if Assigned(FSocket) then
  begin
    Disconnect;
  end;
  if Assigned(FKeepAliveTimer) then
  begin
    FreeAndNil(FKeepAliveTimer);
  end;
  if Assigned(FRecvThread) then
  begin
    FreeAndNil(FRecvThread);
  end;
  if Assigned(FCSSock) then
  begin
    FreeAndNil(FCSSock);
  end;
  inherited;
end;

function TMQTT.Disconnect: Boolean;
var
  Msg: TMQTTMessage;
begin
  Result := False;
  if isConnected then
  begin
    FKeepAliveTimer.Enabled := False;
    Msg := DisconnectMessage;
    if WriteData(Msg.ToBytes) then
      Result := true
    else
      Result := False;
    Msg.Free;

    // Close our socket.
    // ==============================================================================
    // HammerOh
    // FSocket.CloseSocket;
    FSocket.Disconnect;
    // ==============================================================================

    // Terminate our socket receive thread.
    FRecvThread.Terminate;
    FRecvThread.WaitFor;

    FisConnected := False;

    // Free everything.
    if Assigned(FRecvThread) then
      FreeAndNil(FRecvThread);
    if Assigned(FSocket) then
      FreeAndNil(FSocket);
  end;
end;

function TMQTT.getNextMessageId: Integer;
begin
  // If we've reached the upper bounds of our 16 bit unsigned message Id then
  // start again. The spec says it typically does but is not required to Inc(MsgId,1).
  if (FMessageID = 65535) then
  begin
    FMessageID := 1;
  end;

  // Return our current message Id
  Result := FMessageID;
  // Increment message Id
  Inc(FMessageID);
end;

function TMQTT.hasWill: Boolean;
begin
  if ((Length(FWillTopic) < 1) and (Length(FWillMsg) < 1)) then
  begin
    Result := False;
  end
  else
    Result := true;
end;

procedure TMQTT.KeepAliveTimer_Event(sender: TObject);
begin
  if Self.isConnected then
  begin
    PingReq;
  end;
end;

function TMQTT.PingReq: Boolean;
var
  Msg: TMQTTMessage;
begin
  Result := False;
  if isConnected then
  begin
    Msg := PingReqMessage;
    if WriteData(Msg.ToBytes) then
      Result := true
    else
      Result := False;
    Msg.Free;
  end;
end;

function TMQTT.Publish(topic, sPayload: UTF8String; Retain: Boolean): Boolean;
begin
  Result := Publish(topic, sPayload, Retain, 0);
end;

function TMQTT.Publish(topic, sPayload: UTF8String): Boolean;
begin
  Result := Publish(topic, sPayload, False, 0);
end;

function TMQTT.Publish(topic, sPayload: UTF8String; Retain: Boolean;
  QoS: Integer): Boolean;
var
  Msg: TMQTTMessage;
begin
  if ((QoS > -1) and (QoS <= 3)) then
  begin
    if isConnected then
    begin
      Msg := PublishMessage;
      Msg.FixedHeader.QoSLevel := QoS;
      if Retain then
        Msg.FixedHeader.Retain := 1
      else
        Msg.FixedHeader.Retain := 0;
      (Msg.VariableHeader as TMQTTPublishVarHeader).QoSLevel := QoS;
      (Msg.VariableHeader as TMQTTPublishVarHeader).topic := topic;
      if (QoS > 0) then
      begin
        (Msg.VariableHeader as TMQTTPublishVarHeader).MessageID :=
          getNextMessageId;
      end;
      Msg.payload.AddField(sPayload, False);
      if WriteData(Msg.ToBytes) then
        Result := true
      else
        Result := False;
      Msg.Free;
    end;
  end
  else
    raise EInvalidOp.Create
      ('QoS level can only be equal to or between 0 and 3.');
end;

// ------------------------------------------------------------------------------
// TMQTTMessage Factory Methods.
// ------------------------------------------------------------------------------

function TMQTT.ConnectMessage: TMQTTMessage;
begin
  Result := TMQTTMessage.Create;
  Result.VariableHeader := TMQTTConnectVarHeader.Create;
  Result.payload := TMQTTPayload.Create;
  Result.FixedHeader.MessageType := ord(TMQTTMessageType.Connect);
  Result.FixedHeader.Retain := 0;
  Result.FixedHeader.QoSLevel := 0;
  Result.FixedHeader.Duplicate := 0;
end;

function TMQTT.PublishMessage: TMQTTMessage;
begin
  Result := TMQTTMessage.Create;
  Result.FixedHeader.MessageType := ord(TMQTTMessageType.Publish);
  Result.VariableHeader := TMQTTPublishVarHeader.Create(0);
  Result.payload := TMQTTPayload.Create;
end;

function TMQTT.PublishAck(MessageID: Integer): TMQTTMessage;
begin
  Result := TMQTTMessage.Create;
  Result.FixedHeader.MessageType := ord(TMQTTMessageType.PUBACK);
  Result.VariableHeader := TMQTTMessageIdVarHeader.Create(MessageID);
end;

function TMQTT.PublishRec(MessageID: Integer): TMQTTMessage;
begin
  Result := TMQTTMessage.Create;
  Result.FixedHeader.MessageType := ord(TMQTTMessageType.PUBREC);
  Result.VariableHeader := TMQTTMessageIdVarHeader.Create(MessageID);
end;

function TMQTT.PublishRel(MessageID: Integer): TMQTTMessage;
begin
  Result := TMQTTMessage.Create;
  Result.FixedHeader.MessageType := ord(TMQTTMessageType.PUBREL);
  Result.VariableHeader := TMQTTMessageIdVarHeader.Create(MessageID);
end;

function TMQTT.PublishComp(MessageID: Integer): TMQTTMessage;
begin
  Result := TMQTTMessage.Create;
  Result.FixedHeader.MessageType := ord(TMQTTMessageType.PUBCOMP);
  Result.VariableHeader := TMQTTMessageIdVarHeader.Create(MessageID);
end;

function TMQTT.PingReqMessage: TMQTTMessage;
begin
  Result := TMQTTMessage.Create;
  Result.FixedHeader.MessageType := ord(TMQTTMessageType.PingReq);
end;

function TMQTT.DisconnectMessage: TMQTTMessage;
begin
  Result := TMQTTMessage.Create;
  Result.FixedHeader.MessageType := ord(TMQTTMessageType.Disconnect);
end;

// ------------------------------------------------------------------------------
// Recv Thread Event Handling Procedures.
// ------------------------------------------------------------------------------

procedure TMQTT.GotConnAck(sender: TObject; ReturnCode: Integer);
begin
  if Assigned(FConnAckEvent) then
    OnConnAck(Self, ReturnCode);
end;

procedure TMQTT.GotPublish(sender: TObject; QoS, MessageID: Integer;
  topic, payload: UTF8String);
var
  Msg: TMQTTMessage;
begin
  case QoS of
    0:
      ;
    1:
      begin
        Msg := PublishAck(MessageID);
        try
          WriteData(Msg.ToBytes);
        finally
          Msg.Free;
        end;
      end;
    2:
      begin
        Msg := PublishRec(MessageID);
        try
          WriteData(Msg.ToBytes);
        finally
          Msg.Free;
        end;
      end;
  end;

  if Assigned(FPublishEvent) then
    OnPublish(Self, QoS, MessageID, topic, payload);
end;

procedure TMQTT.GotPubAck(sender: TObject; MessageID: Integer);
begin
  if Assigned(FPubAckEvent) then
    OnPubAck(Self, MessageID);
end;

procedure TMQTT.GotPubRec(sender: TObject; MessageID: Integer);
var
  Msg: TMQTTMessage;
begin
  Msg := PublishRel(MessageID);
  try
    WriteData(Msg.ToBytes);
  finally
    Msg.Free;
  end;
  if Assigned(FPubRecEvent) then
    OnPubRec(Self, MessageID);
end;

procedure TMQTT.GotPubRel(sender: TObject; MessageID: Integer);
var
  Msg: TMQTTMessage;
begin
  Msg := PublishComp(MessageID);
  try
    WriteData(Msg.ToBytes);
  finally
    Msg.Free;
  end;
  if Assigned(FPubRelEvent) then
    OnPubRel(Self, MessageID);
end;

procedure TMQTT.GotPubComp(sender: TObject; MessageID: Integer);
begin
  if Assigned(FPubCompEvent) then
    OnPubComp(Self, MessageID);
end;

procedure TMQTT.GotSubAck(sender: TObject; MessageID: Integer;
  GrantedQoS: array of Integer);
begin
  if Assigned(FSubAckEvent) then
    OnSubAck(Self, MessageID, GrantedQoS);
end;

procedure TMQTT.GotUnSubAck(sender: TObject; MessageID: Integer);
begin
  if Assigned(FUnSubAckEvent) then
    OnUnSubAck(Self, MessageID);
end;

procedure TMQTT.GotPingResp(sender: TObject);
begin
  if Assigned(FPingRespEvent) then
    OnPingResp(Self);
end;

function TMQTT.Subscribe(topic: UTF8String; RequestQoS: Integer): Integer;
var
  dTopics: TDictionary<UTF8String, Integer>;
begin
  dTopics := TDictionary<UTF8String, Integer>.Create;
  dTopics.Add(topic, RequestQoS);
  Result := Subscribe(dTopics);
  dTopics.Free;
end;

function TMQTT.Subscribe(Topics: TDictionary<UTF8String, Integer>): Integer;
var
  Msg: TMQTTMessage;
  MsgId: Integer;
  sTopic: UTF8String;
  iRequestQoS: Byte;
  data: TBytes;
begin
  Result := -1;
  if isConnected then
  begin
    Msg := SubscribeMessage;
    MsgId := getNextMessageId;
    (Msg.VariableHeader as TMQTTSubscribeVarHeader).MessageID := MsgId;

    for sTopic in Topics.Keys do
    begin
      iRequestQoS := Topics.Items[sTopic];
      Msg.payload.AddField(sTopic);
      Msg.payload.AddField(iRequestQoS, False);
    end;

    data := Msg.ToBytes;
    if WriteData(data) then
      Result := MsgId;

    Msg.Free;
  end;
end;

function TMQTT.SubscribeMessage: TMQTTMessage;
begin
  Result := TMQTTMessage.Create;
  Result.FixedHeader.MessageType := ord(TMQTTMessageType.Subscribe);
  Result.FixedHeader.QoSLevel := 1;
  Result.VariableHeader := TMQTTSubscribeVarHeader.Create;
  Result.payload := TMQTTPayload.Create;
end;

function TMQTT.Unsubscribe(topic: UTF8String): Integer;
var
  slTopics: TStringList;
begin
  slTopics := TStringList.Create;
  slTopics.Add(topic);
  Result := Unsubscribe(slTopics);
  slTopics.Free;
end;

function TMQTT.Unsubscribe(Topics: TStringList): Integer;
var
  Msg: TMQTTMessage;
  MsgId: Integer;
  sTopic: UTF8String;
begin
  Result := -1;
  if isConnected then
  begin
    Msg := UnsubscribeMessage;
    MsgId := getNextMessageId;
    (Msg.VariableHeader as TMQTTUnsubscribeVarHeader).MessageID := MsgId;

    for sTopic in Topics do
      Msg.payload.AddField(sTopic);

    if WriteData(Msg.ToBytes) then
      Result := MsgId;

    Msg.Free;
  end;
end;

function TMQTT.UnsubscribeMessage: TMQTTMessage;
var
  Msg: TMQTTMessage;
begin
  Result := TMQTTMessage.Create;
  Result.FixedHeader.MessageType := ord(TMQTTMessageType.Unsubscribe);
  Result.FixedHeader.QoSLevel := 1;
  Result.VariableHeader := TMQTTUnsubscribeVarHeader.Create;
  Result.payload := TMQTTPayload.Create;
end;

function TMQTT.WriteData(AData: TBytes): Boolean;
var
  sentData: Integer;
  attemptsToWrite: Integer;
begin
  Result := False;
  sentData := 0;
  attemptsToWrite := 1;
  if isConnected then
  begin
    // ==============================================================================
    // HammerOh
    (*
      repeat
      FCSSock.Acquire;
      try
      if FSocket.CanWrite(500 * attemptsToWrite) then
      begin
      sentData := sentData + FSocket.SendBuffer(Pointer(Copy(AData, sentData - 1, Length(AData) + 1)), Length(AData) - sentData);
      Inc(attemptsToWrite);
      end;
      finally
      FCSSock.Release;
      end;
      until ((attemptsToWrite = 3) or (sentData = Length(AData)));
      if sentData = Length(AData) then
      begin
      Result := True;
      FisConnected := true;
      end
      else
      begin
      Result := False;
      FisConnected := false;
      raise Exception.Create('Error Writing to Socket, it appears to be disconnected');
      end;
    *)
    try
      FSocket.IOHandler.
        Write(Pointer(Copy(AData, sentData - 1, Length(AData) + 1)),
        Length(AData) - sentData);
      Result := true;
      FisConnected := true;
    except
      Result := False;
      FisConnected := False;
    end;
    // ==============================================================================
  end;
end;

end.
