object FormPrincipal: TFormPrincipal
  Left = 0
  Top = 0
  Caption = 'Daikit - Conversa com IA'
  ClientHeight = 560
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  DesignSize = (
    640
    560)
  TextHeight = 15
  object LabelLog: TLabel
    Left = 16
    Top = 416
    Width = 20
    Height = 15
    Anchors = [akLeft, akBottom]
    Caption = 'Log'
  end
  object LabelUso: TLabel
    Left = 16
    Top = 44
    Width = 5
    Height = 15
    Caption = '-'
  end
  object BotaoLimparLog: TButton
    Left = 536
    Top = 407
    Width = 88
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Limpar log'
    TabOrder = 8
    TabStop = False
    OnClick = BotaoLimparLogClick
  end
  object MemoConversa: TMemo
    Left = 16
    Top = 67
    Width = 608
    Height = 289
    Anchors = [akLeft, akTop, akRight, akBottom]
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 3
  end
  object ComboProvedor: TComboBox
    Left = 16
    Top = 16
    Width = 90
    Height = 23
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 0
    Text = 'OpenAI'
    OnChange = ComboProvedorChange
    Items.Strings = (
      'OpenAI'
      'Anthropic'
      'Gemini')
  end
  object EditMensagem: TEdit
    Left = 16
    Top = 365
    Width = 418
    Height = 23
    Anchors = [akLeft, akRight, akBottom]
    TabOrder = 4
  end
  object BotaoEnviar: TButton
    Left = 442
    Top = 362
    Width = 88
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Enviar'
    Default = True
    TabOrder = 5
    OnClick = BotaoEnviarClick
  end
  object DBGridLog: TDBGrid
    Left = 16
    Top = 440
    Width = 608
    Height = 104
    Anchors = [akLeft, akRight, akBottom]
    DataSource = DataSourceLog
    Options = [dgEditing, dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgAlwaysShowSelection, dgTitleClick, dgTitleHotTrack]
    ReadOnly = True
    TabOrder = 7
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = 'Segoe UI'
    TitleFont.Style = []
    Columns = <
      item
        Expanded = False
        FieldName = 'DataHoraUTC'
        Title.Caption = 'Data/hora UTC'
        Width = 135
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Tipo'
        Width = 75
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Nivel'
        Title.Caption = 'N'#237'vel'
        Width = 85
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Provedor'
        Width = 70
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Mensagem'
        Width = 500
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'StatusHTTP'
        Title.Caption = 'HTTP'
        Width = 50
        Visible = True
      end>
  end
  object ComboModelo: TComboBox
    Left = 112
    Top = 16
    Width = 129
    Height = 23
    Style = csDropDownList
    TabOrder = 1
    OnChange = ComboModeloChange
  end
  object ButtonLimpar: TButton
    Left = 536
    Top = 362
    Width = 88
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Limpar'
    Default = True
    TabOrder = 6
    TabStop = False
    OnClick = ButtonLimparClick
  end
  object ComboModoConversa: TComboBox
    Left = 392
    Top = 16
    Width = 129
    Height = 23
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 2
    Text = 'Manter o Hist'#243'rico'
    OnChange = ComboModoConversaChange
    Items.Strings = (
      'Manter o Hist'#243'rico'
      'Mensagem Isolada')
  end
  object ButtonCarregarModelos: TButton
    Left = 247
    Top = 16
    Width = 139
    Height = 23
    Anchors = [akRight, akBottom]
    Caption = 'Carregar todos modelos'
    Default = True
    TabOrder = 9
    OnClick = ButtonCarregarModelosClick
  end
  object ProvedorOpenAI: TProvedorOpenAI
    VariavelAmbienteChaveAPI = 'OPENAI_API_KEY'
    Left = 216
    Top = 168
  end
  object ProvedorAnthropic: TProvedorAnthropic
    Left = 432
    Top = 168
  end
  object ProvedorGemini: TProvedorGemini
    Left = 320
    Top = 168
  end
  object ConversaIA: TConversaIA
    Left = 344
    Top = 88
  end
  object ChatIA: TChatIA
    Provedor = ProvedorOpenAI
    Conversa = ConversaIA
    AoIniciarRequisicao = ChatIAAoIniciarRequisicao
    AoReceberResposta = ChatIAAoReceberResposta
    AoOcorrerErro = ChatIAAoOcorrerErro
    AoConcluir = ChatIAAoConcluir
    AoRegistrarLog = ChatIAAoRegistrarLog
    AoReceberModelos = ChatIAAoReceberModelos
    Left = 280
    Top = 88
  end
  object ClientDataSetLog: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 400
    Top = 88
  end
  object DataSourceLog: TDataSource
    DataSet = ClientDataSetLog
    Left = 464
    Top = 88
  end
end
