object FormPrincipal: TFormPrincipal
  Left = 0
  Top = 0
  Caption = 'Daikit - conversa com IA'
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
    Left = 619
    Top = 341
    Width = 5
    Height = 15
    Alignment = taRightJustify
    Anchors = [akTop, akRight]
    Caption = '-'
  end
  object ComboNivelLog: TComboBox
    Left = 48
    Top = 408
    Width = 110
    Height = 23
    Style = csDropDownList
    Anchors = [akLeft, akBottom]
    ItemIndex = 0
    TabOrder = 8
    Text = 'Todos os niveis'
    Items.Strings = (
      'Todos os niveis'
      'Informacao'
      'Erro')
  end
  object BotaoLimparLog: TButton
    Left = 536
    Top = 407
    Width = 88
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Limpar log'
    TabOrder = 9
    OnClick = BotaoLimparLogClick
  end
  object MemoConversa: TMemo
    Left = 16
    Top = 48
    Width = 608
    Height = 289
    Anchors = [akLeft, akTop, akRight, akBottom]
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object ComboProvedor: TComboBox
    Left = 16
    Top = 16
    Width = 129
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
    Width = 505
    Height = 23
    Anchors = [akLeft, akRight, akBottom]
    TabOrder = 2
  end
  object BotaoEnviar: TButton
    Left = 536
    Top = 364
    Width = 88
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Enviar'
    Default = True
    TabOrder = 3
    OnClick = BotaoEnviarClick
  end
  object MemoLog: TMemo
    Left = 16
    Top = 440
    Width = 608
    Height = 104
    Anchors = [akLeft, akRight, akBottom]
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 4
    WordWrap = False
  end
  object ComboModelo: TComboBox
    Left = 158
    Top = 16
    Width = 129
    Height = 23
    Style = csDropDownList
    TabOrder = 5
    OnChange = ComboProvedorChange
  end
  object ButtonLimpar: TButton
    Left = 536
    Top = 16
    Width = 88
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Limpar'
    Default = True
    TabOrder = 6
    OnClick = ButtonLimparClick
  end
  object ComboModoConversa: TComboBox
    Left = 299
    Top = 16
    Width = 129
    Height = 23
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 7
    Text = 'Manter o Hist'#243'rico'
    OnChange = ComboModoConversaChange
    Items.Strings = (
      'Manter o Hist'#243'rico'
      'Mensagem Isolada')
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
    Left = 280
    Top = 88
  end
end
