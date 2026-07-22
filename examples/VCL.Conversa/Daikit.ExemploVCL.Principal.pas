unit Daikit.ExemploVCL.Principal;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  System.TypInfo,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Daikit.Dominio.Interfaces,
  Daikit.Aplicacao.Interfaces,
  Daikit.Aplicacao.Log,
  Daikit.Componentes.Chat,
  Daikit.Componentes.Conversa,
  Daikit.Componentes.Provedores,
  Daikit.Componentes.Provedor;

type
  TFormPrincipal = class(TForm)
    MemoConversa: TMemo;
    ComboProvedor: TComboBox;
    EditMensagem: TEdit;
    BotaoEnviar: TButton;
    LabelLog: TLabel;
    MemoLog: TMemo;
    ProvedorOpenAI: TProvedorOpenAI;
    ProvedorAnthropic: TProvedorAnthropic;
    ProvedorGemini: TProvedorGemini;
    ConversaIA: TConversaIA;
    ChatIA: TChatIA;
    ComboModelo: TComboBox;
    LabelUso: TLabel;
    ButtonLimpar: TButton;
    ComboModoConversa: TComboBox;
    ComboNivelLog: TComboBox;
    BotaoLimparLog: TButton;
    procedure FormCreate(Sender: TObject);
    procedure BotaoEnviarClick(Sender: TObject);
    procedure ComboProvedorChange(Sender: TObject);
    procedure ChatIAAoReceberResposta(Sender: TObject;
      const AResposta: IRespostaChatIA);
    procedure ButtonLimparClick(Sender: TObject);
    procedure ComboModoConversaChange(Sender: TObject);
    procedure BotaoLimparLogClick(Sender: TObject);
    procedure ChatIAAoRegistrarLog(Sender: TObject;
      const AEvento: IEventoLogIA);
  private
    procedure AdicionarLinhaLog(const AMensagem: string;
      const Args: array of const);
    procedure SelecionarProvedor;
    procedure LimparChat;
    procedure SelecionarModoConversa;
    procedure RegistrarMensagem(const AMensagem: string;
      const Args: array of const);
    function NivelMinimoLog: TNivelLogIA;
  end;

var
  FormPrincipal: TFormPrincipal;

implementation

{$R *.dfm}

const
  CLimiteLinhasLogExemplo = 300;

procedure TFormPrincipal.BotaoEnviarClick(Sender: TObject);
var
  LTexto, LResposta: string;
begin
  LTexto := Trim(EditMensagem.Text);
  if LTexto = '' then
    Exit;

  SelecionarProvedor;
  RegistrarMensagem('Você: %s', [LTexto]);
  EditMensagem.Clear;

  try
    LResposta := ChatIA.EnviarTexto(LTexto);
    RegistrarMensagem('%s: %s', [ComboProvedor.Text, LResposta]);
  except
    on E: Exception do
      MemoConversa.Lines.Add('Erro: ' + E.Message);
  end;
end;

procedure TFormPrincipal.ButtonLimparClick(Sender: TObject);
begin
  LimparChat;
end;

procedure TFormPrincipal.BotaoLimparLogClick(Sender: TObject);
begin
  MemoLog.Clear;
end;

procedure TFormPrincipal.ChatIAAoRegistrarLog(Sender: TObject;
  const AEvento: IEventoLogIA);
begin
  if (AEvento = nil) or (Ord(AEvento.Nivel) < Ord(NivelMinimoLog)) then
    Exit;
  AdicionarLinhaLog('[%s] %s; HTTP=%d', [
    GetEnumName(TypeInfo(TNivelLogIA), Ord(AEvento.Nivel)),
    AEvento.Provedor, AEvento.StatusHTTP]);
  AdicionarLinhaLog('%s', [AEvento.Mensagem]);
end;

procedure TFormPrincipal.ChatIAAoReceberResposta(Sender: TObject;
  const AResposta: IRespostaChatIA);
var
  LDetalhesUso: string;
begin
  LDetalhesUso := 'não informado pelo provedor';
  if AResposta.Uso <> nil then
    LDetalhesUso := Format('%d entrada | %d saída | %d tokens', [
      AResposta.Uso.UnidadesEntrada,
      AResposta.Uso.UnidadesSaida,
      AResposta.Uso.UnidadesTotal]);

  LabelUso.Caption := Format('Última interação: %s', [LDetalhesUso]);
end;

procedure TFormPrincipal.ComboModoConversaChange(Sender: TObject);
begin
  SelecionarModoConversa;
end;

procedure TFormPrincipal.ComboProvedorChange(Sender: TObject);
begin
  SelecionarProvedor;
end;

procedure TFormPrincipal.FormCreate(Sender: TObject);
begin
  SelecionarProvedor;
end;

procedure TFormPrincipal.AdicionarLinhaLog(const AMensagem: string;
  const Args: array of const);
begin
  MemoLog.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + '  ' + Format(AMensagem, Args));
  while MemoLog.Lines.Count > CLimiteLinhasLogExemplo do
    MemoLog.Lines.Delete(0);
end;

function TFormPrincipal.NivelMinimoLog: TNivelLogIA;
begin
  case ComboNivelLog.ItemIndex of
    2: Result := TNivelLogIA.Erro;
  else
    Result := TNivelLogIA.Informacao;
  end;
end;

procedure TFormPrincipal.RegistrarMensagem(const AMensagem: string;
  const Args: array of const);
const
  CTamanhoSeparador = 115;
begin
  MemoConversa.Lines.Add(Format(AMensagem, Args));
  MemoConversa.Lines.Add(StringOfChar('-', CTamanhoSeparador));
end;

procedure TFormPrincipal.LimparChat;
begin
   ChatIA.LimparHistorico;
   MemoConversa.Lines.Clear;
end;

procedure TFormPrincipal.SelecionarModoConversa;
begin
  case ComboModoConversa.ItemIndex of
    0: ChatIA.ModoConversa := ManterHistorico;
    1: ChatIA.ModoConversa := MensagemIsolada;
  else
    ChatIA.ModoConversa := ManterHistorico;
  end;
end;

procedure TFormPrincipal.SelecionarProvedor;
begin
  case ComboProvedor.ItemIndex of
    0: ChatIA.Provedor := ProvedorOpenAI;
    1: ChatIA.Provedor := ProvedorAnthropic;
    2: ChatIA.Provedor := ProvedorGemini;
  else
    ChatIA.Provedor := nil;
  end;
end;

end.
