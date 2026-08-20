object FormPrincipal: TFormPrincipal
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'Demonstra'#231#227'o'
  ClientHeight = 582
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 15
  object lbMensagem: TLabel
    Left = 20
    Top = 81
    Width = 59
    Height = 15
    Caption = 'Mensagem'
  end
  object lbTokens: TLabel
    Left = 240
    Top = 418
    Width = 365
    Height = 15
    Alignment = taRightJustify
    AutoSize = False
    BiDiMode = bdLeftToRight
    ParentBiDiMode = False
  end
  object lbLog: TLabel
    Left = 20
    Top = 443
    Width = 20
    Height = 15
    Caption = 'Log'
  end
  object btEnviarMensagem: TButton
    Left = 530
    Top = 101
    Width = 75
    Height = 25
    Caption = 'Enviar'
    TabOrder = 5
    OnClick = btEnviarMensagemClick
  end
  object cbProvedor: TComboBox
    Left = 20
    Top = 30
    Width = 97
    Height = 23
    ItemIndex = 0
    TabOrder = 0
    TabStop = False
    Text = 'OpenIA'
    Items.Strings = (
      'OpenIA'
      'Anthropic'
      'Gemini')
  end
  object cbModelo: TComboBox
    Left = 250
    Top = 30
    Width = 130
    Height = 23
    TabOrder = 2
    TabStop = False
  end
  object edMensagem: TEdit
    Left = 20
    Top = 102
    Width = 505
    Height = 23
    TabOrder = 4
  end
  object btCarregarModelos: TButton
    Left = 123
    Top = 29
    Width = 121
    Height = 25
    Caption = 'Carregar Modelos'
    TabOrder = 1
    TabStop = False
    OnClick = btCarregarModelosClick
  end
  object cbManterHistorico: TCheckBox
    Left = 396
    Top = 37
    Width = 107
    Height = 17
    TabStop = False
    Caption = 'Manter hist'#243'rico'
    Checked = True
    State = cbChecked
    TabOrder = 3
    OnClick = cbManterHistoricoClick
  end
  object mmMensagens: TMemo
    Left = 20
    Top = 139
    Width = 585
    Height = 272
    TabStop = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 6
  end
  object mmLog: TMemo
    Left = 20
    Top = 464
    Width = 585
    Height = 89
    ScrollBars = ssBoth
    TabOrder = 7
  end
  object ChatIA: TChatIA
    Provedor = ProvedorOpenAI
    Conversa = ConversaIA
    AoReceberResposta = ChatIAAoReceberResposta
    AoOcorrerErro = ChatIAAoOcorrerErro
    AoRegistrarLog = ChatIAAoRegistrarLog
    AoReceberModelos = ChatIAAoReceberModelos
    Left = 184
    Top = 176
  end
  object ConversaIA: TConversaIA
    Left = 288
    Top = 176
  end
  object ProvedorOpenAI: TProvedorOpenAI
    Left = 120
    Top = 248
  end
  object ProvedorAnthropic: TProvedorAnthropic
    Left = 240
    Top = 248
  end
  object ProvedorGemini: TProvedorGemini
    Left = 360
    Top = 248
  end
end
