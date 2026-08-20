unit Daikit.Demo.Principal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Daikit.Componentes.Provedores, Daikit.Componentes.Provedor,
  Daikit.Componentes.Conversa, Daikit.Componentes.Chat,
  Daikit.Dominio.Interfaces,
  Daikit.Componentes.OperacaoChat,
  Daikit.Aplicacao.Log;

type
  TFormPrincipal = class(TForm)
    btEnviarMensagem: TButton;
    cbProvedor: TComboBox;
    cbModelo: TComboBox;
    edMensagem: TEdit;
    btCarregarModelos: TButton;
    cbManterHistorico: TCheckBox;
    lbMensagem: TLabel;
    mmMensagens: TMemo;
    ChatIA: TChatIA;
    ConversaIA: TConversaIA;
    ProvedorOpenAI: TProvedorOpenAI;
    ProvedorAnthropic: TProvedorAnthropic;
    ProvedorGemini: TProvedorGemini;
    lbTokens: TLabel;
    mmLog: TMemo;
    lbLog: TLabel;
    procedure btEnviarMensagemClick(Sender: TObject);
    procedure ChatIAAoReceberResposta(Sender: TObject;
      const AResposta: IRespostaChatIA);
    procedure ChatIAAoOcorrerErro(Sender: TObject; const AErro: IErroChatIA);
    procedure cbManterHistoricoClick(Sender: TObject);
    procedure btCarregarModelosClick(Sender: TObject);
    procedure ChatIAAoReceberModelos(Sender: TObject;
      const AModelos: TArray<Daikit.Dominio.Interfaces.IModeloIA>);
    procedure ChatIAAoRegistrarLog(Sender: TObject;
      const AEvento: IEventoLogIA);
  private
    procedure SelecionarProvedor;
    procedure RegistrarMensagem(AEvento, AMensagem: String);
  end;

var
  FormPrincipal: TFormPrincipal;

implementation

{$R *.dfm}


procedure TFormPrincipal.btCarregarModelosClick(Sender: TObject);
begin
  SelecionarProvedor;
  ChatIA.CarregarModelos;
end;

procedure TFormPrincipal.btEnviarMensagemClick(Sender: TObject);
begin
  SelecionarProvedor;
  var LMensagem: String := Trim(edMensagem.Text);
  if LMensagem.IsEmpty then
    Exit;
  edMensagem.Clear;

  RegistrarMensagem('Eu', LMensagem);
  ChatIA.Enviar(LMensagem);
end;

procedure TFormPrincipal.SelecionarProvedor;
begin
  case cbProvedor.ItemIndex of
    0: ChatIA.Provedor := ProvedorOpenAI;
    1: ChatIA.Provedor := ProvedorAnthropic;
    2: ChatIA.Provedor := ProvedorGemini;
  else
    ChatIA.Provedor := nil;
  end;
end;

procedure TFormPrincipal.RegistrarMensagem(AEvento, AMensagem: String);
begin
  mmMensagens.Lines.Add(AEvento + ':');
  mmMensagens.Lines.Add(AMensagem);
  mmMensagens.Lines.Add('-----');
  mmMensagens.Lines.Add('');
end;

procedure TFormPrincipal.cbManterHistoricoClick(Sender: TObject);
begin
  ChatIA.ModoConversa := MensagemIsolada;
  if cbManterHistorico.Checked then
    ChatIA.ModoConversa := ManterHistorico;
end;

procedure TFormPrincipal.ChatIAAoOcorrerErro(Sender: TObject;
  const AErro: IErroChatIA);
begin
  RegistrarMensagem('Erro', AErro.Mensagem);
end;

procedure TFormPrincipal.ChatIAAoReceberModelos(Sender: TObject;
  const AModelos: TArray<Daikit.Dominio.Interfaces.IModeloIA>);
begin
  cbModelo.Items.BeginUpdate;
  try
    for var I := Low(AModelos) to High(AModelos) do
      cbModelo.Items.Add(AModelos[I].Id);

    cbModelo.ItemIndex := cbModelo.Items.IndexOf(ChatIA.Provedor.ModeloPadrao);
  finally
    cbModelo.Items.EndUpdate;
  end;
end;

procedure TFormPrincipal.ChatIAAoReceberResposta(Sender: TObject;
  const AResposta: IRespostaChatIA);
begin
  RegistrarMensagem(cbProvedor.Text, AResposta.Mensagem.Texto);

  lbTokens.Caption := Format('%d entrada - %d saída - %d total',
    [AResposta.Uso.UnidadesEntrada,
     AResposta.Uso.UnidadesSaida,
     AResposta.Uso.UnidadesTotal]);
end;

procedure TFormPrincipal.ChatIAAoRegistrarLog(Sender: TObject;
  const AEvento: IEventoLogIA);
begin
  mmLog.Lines.Add(Format('- Provedor: %s Mensagem log: %s',
    [AEvento.Provedor, AEvento.Mensagem]));
end;

end.
