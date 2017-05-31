object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 538
  ClientWidth = 683
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  object RichEdit1: TRichEdit
    Left = 0
    Top = 306
    Width = 683
    Height = 232
    Align = alClient
    Font.Charset = GB2312_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Lines.Strings = (
      'RichEdit1')
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 0
    Zoom = 100
  end
  object ToolBarMain: TToolBar
    Left = 0
    Top = 0
    Width = 683
    Height = 29
    ButtonHeight = 25
    ButtonWidth = 67
    Caption = 'ToolBarMain'
    TabOrder = 1
    object btnConn: TButton
      Left = 0
      Top = 0
      Width = 75
      Height = 25
      Caption = 'btnConn'
      TabOrder = 0
      OnClick = btnConnClick
    end
    object btnDisConn: TButton
      Left = 75
      Top = 0
      Width = 75
      Height = 25
      Caption = 'btnDisConn'
      TabOrder = 1
      OnClick = btnDisConnClick
    end
  end
  object GroupBox1: TGroupBox
    Left = 0
    Top = 110
    Width = 683
    Height = 167
    Align = alTop
    Caption = #25512#36865
    TabOrder = 2
    object Label1: TLabel
      Left = 19
      Top = 46
      Width = 48
      Height = 13
      Caption = #25512#36865#20869#23481
    end
    object Label2: TLabel
      Left = 419
      Top = 120
      Width = 19
      Height = 13
      Caption = 'Qos'
    end
    object LabelDup: TLabel
      Left = 255
      Top = 120
      Width = 19
      Height = 13
      Caption = 'Dup'
    end
    object LabeledEdit1: TLabeledEdit
      Left = 70
      Top = 19
      Width = 547
      Height = 21
      EditLabel.Width = 24
      EditLabel.Height = 13
      EditLabel.Caption = #20027#39064
      LabelPosition = lpLeft
      TabOrder = 0
      Text = '123'
    end
    object RichEdit2: TRichEdit
      Left = 70
      Top = 46
      Width = 547
      Height = 59
      Font.Charset = GB2312_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      Lines.Strings = (
        'AT+VER')
      ParentFont = False
      ScrollBars = ssBoth
      TabOrder = 1
      Zoom = 100
    end
    object btnPub: TButton
      Left = 70
      Top = 111
      Width = 171
      Height = 42
      Caption = 'btnPub '#25512#36865
      TabOrder = 2
      OnClick = btnPubClick
    end
    object ComboBoxQos: TComboBox
      Left = 444
      Top = 120
      Width = 49
      Height = 21
      ItemIndex = 0
      TabOrder = 3
      Text = '0'
      Items.Strings = (
        '0'
        '1'
        '2')
    end
    object CheckBoxRetain: TCheckBox
      Left = 528
      Top = 120
      Width = 57
      Height = 17
      Caption = #20445#30041
      TabOrder = 4
    end
    object EditDup: TEdit
      Left = 280
      Top = 120
      Width = 81
      Height = 21
      TabOrder = 5
      Text = '0'
    end
  end
  object GroupBox2: TGroupBox
    Left = 0
    Top = 29
    Width = 683
    Height = 81
    Align = alTop
    Caption = #35746#38405
    TabOrder = 3
    object Label3: TLabel
      Left = 523
      Top = 27
      Width = 19
      Height = 13
      Caption = 'Qos'
    end
    object LabeledEdit2: TLabeledEdit
      Left = 70
      Top = 19
      Width = 321
      Height = 21
      EditLabel.Width = 24
      EditLabel.Height = 13
      EditLabel.Caption = #20027#39064
      LabelPosition = lpLeft
      TabOrder = 0
      Text = #36879#20256#20113
    end
    object btnSub: TButton
      Left = 397
      Top = 17
      Width = 107
      Height = 25
      Caption = 'btnSub '#35746#38405
      TabOrder = 1
      OnClick = btnSubClick
    end
    object btnUnSub: TButton
      Left = 397
      Top = 48
      Width = 107
      Height = 25
      Caption = 'btnUnSub '#21462#28040#35746#38405
      TabOrder = 2
      OnClick = btnUnSubClick
    end
    object ComboBox1: TComboBox
      Left = 548
      Top = 19
      Width = 49
      Height = 21
      ItemIndex = 0
      TabOrder = 3
      Text = '0'
      Items.Strings = (
        '0'
        '1'
        '2')
    end
  end
  object ToolBar1: TToolBar
    Left = 0
    Top = 277
    Width = 683
    Height = 29
    Caption = 'ToolBar1'
    TabOrder = 4
    object CheckBox1: TCheckBox
      Left = 0
      Top = 0
      Width = 97
      Height = 22
      Caption = #33258#21160#28378#21160
      Checked = True
      State = cbChecked
      TabOrder = 0
    end
    object Button1: TButton
      Left = 97
      Top = 0
      Width = 75
      Height = 22
      Caption = 'Cls'
      TabOrder = 1
      OnClick = Button1Click
    end
  end
  object btnPing: TButton
    Left = 152
    Top = 0
    Width = 75
    Height = 25
    Caption = 'PING'
    TabOrder = 5
    OnClick = btnPingClick
  end
  object Timer1: TTimer
    Interval = 10000
    Left = 448
    Top = 8
  end
end
