object FormInstalador: TFormInstalador
  Left = 0
  Top = 0
  BorderStyle = bsSingle
  Caption = 'Instalador Daikit'
  ClientHeight = 390
  ClientWidth = 680
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 17
  object PanelCabecalho: TPanel
    Left = 0
    Top = 0
    Width = 680
    Height = 96
    Align = alTop
    BevelOuter = bvNone
    Color = 3158064
    ParentBackground = False
    TabOrder = 0
    object LabelTitulo: TLabel
      Left = 24
      Top = 17
      Width = 211
      Height = 30
      Caption = 'Instalador Daikit'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object LabelIntroducao: TLabel
      Left = 24
      Top = 55
      Width = 480
      Height = 17
      Caption = 'Instale os componentes de Daikit na paleta do Delphi 12.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 13684944
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object LabelEstado: TLabel
    Left = 24
    Top = 120
    Width = 167
    Height = 21
    Caption = 'Verificando ambiente...'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 3158064
    Font.Height = -16
    Font.Name = 'Segoe UI Semibold'
    Font.Style = []
    ParentFont = False
  end
  object LabelPlataformas: TLabel
    Left = 24
    Top = 160
    Width = 429
    Height = 17
    Caption = 'Bibliotecas incorporadas: runtime Win32/Win64 e design-time Win32.'
  end
  object LabelDestino: TLabel
    Left = 24
    Top = 190
    Width = 94
    Height = 17
    Caption = 'Destino das BPLs:'
  end
  object ButtonInstalar: TButton
    Left = 24
    Top = 226
    Width = 128
    Height = 38
    Caption = 'Instalar'
    Default = True
    TabOrder = 1
    OnClick = ButtonInstalarClick
  end
  object ButtonDesinstalar: TButton
    Left = 160
    Top = 226
    Width = 128
    Height = 38
    Caption = 'Desinstalar'
    TabOrder = 2
    OnClick = ButtonDesinstalarClick
  end
  object MemoLog: TMemo
    Left = 24
    Top = 280
    Width = 632
    Height = 86
    Color = 15790320
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 3
  end
end
