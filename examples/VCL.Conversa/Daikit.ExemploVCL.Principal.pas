unit Daikit.ExemploVCL.Principal;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  System.TypInfo,
  Data.DB,
  Datasnap.DBClient,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.DBGrids,
  Daikit.Dominio.Interfaces,
  Daikit.Aplicacao.Interfaces,
  Daikit.Aplicacao.Log,
  Daikit.Componentes.Chat,
  Daikit.Componentes.OperacaoChat,
  Daikit.Componentes.Conversa,
  Daikit.Componentes.Provedores,
  Daikit.Componentes.Provedor, Vcl.Grids;

type
  TFormPrincipal = class(TForm)
    MemoConversa: TMemo;
    ComboProvedor: TComboBox;
    EditMensagem: TEdit;
    BotaoEnviar: TButton;
    LabelLog: TLabel;
    DBGridLog: TDBGrid;
    ProvedorOpenAI: TProvedorOpenAI;
    ProvedorAnthropic: TProvedorAnthropic;
    ProvedorGemini: TProvedorGemini;
    ConversaIA: TConversaIA;
    ChatIA: TChatIA;
    ComboModelo: TComboBox;
    LabelUso: TLabel;
    ButtonLimpar: TButton;
    ComboModoConversa: TComboBox;
    BotaoLimparLog: TButton;
    ButtonCarregarModelos: TButton;
    ClientDataSetLog: TClientDataSet;
    DataSourceLog: TDataSource;
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
    procedure ChatIAAoIniciarRequisicao(Sender: TObject);
    procedure ChatIAAoOcorrerErro(Sender: TObject;
      const AErro: IErroChatIA);
    procedure ChatIAAoConcluir(Sender: TObject);
    procedure ChatIAAoReceberModelos(Sender: TObject;
      const AModelos: TArray<IModeloIA>);
    procedure ComboModeloChange(Sender: TObject);
    procedure ButtonCarregarModelosClick(Sender: TObject);
  private
    procedure CriarCamposLog;
    procedure CampoMensagemLogGetText(Sender: TField; var Text: string;
      DisplayText: Boolean);
    procedure RemoverLogsExcedentes;
    procedure SelecionarProvedor;
    procedure SelecionarModelo;
    procedure SelecionarModoConversa;
    procedure PreencherModeloPadrao;
    procedure LimparChat;
    procedure RegistrarMensagem(const AEmissor, AMensagem: string;
      const Args: array of const);
  end;

var
  FormPrincipal: TFormPrincipal;

implementation

{$R *.dfm}

const
  CLimiteLinhasLogExemplo = 300;
  CCampoLogDataHoraUTC = 'DataHoraUTC';
  CCampoLogTipo = 'Tipo';
  CCampoLogProvedor = 'Provedor';
  CCampoLogMensagem = 'Mensagem';
  CCampoLogStatusHTTP = 'StatusHTTP';
  CTamanhoCampoTipoLog = 20;
  CTamanhoCampoProvedorLog = 80;
  CFormatoDataHoraLog = 'yyyy-mm-dd hh:nn:ss.zzz';

procedure TFormPrincipal.BotaoEnviarClick(Sender: TObject);
var
  LMensagem: string;
begin
  LMensagem := Trim(EditMensagem.Text);
  if LMensagem = '' then
    Exit;

  SelecionarProvedor;
  RegistrarMensagem('Você', LMensagem, []);
  EditMensagem.Clear;

  try
    ChatIA.Enviar(LMensagem);
  except
    on E: Exception do
      MemoConversa.Lines.Add('Erro: ' + E.Message);
  end;
end;

procedure TFormPrincipal.ButtonCarregarModelosClick(Sender: TObject);
begin
  ChatIA.CarregarModelos;
end;

procedure TFormPrincipal.ButtonLimparClick(Sender: TObject);
begin
  LimparChat;
end;

procedure TFormPrincipal.BotaoLimparLogClick(Sender: TObject);
begin
  if ClientDataSetLog.Active and not ClientDataSetLog.IsEmpty then
    ClientDataSetLog.EmptyDataSet;
end;

procedure TFormPrincipal.CampoMensagemLogGetText(Sender: TField;
  var Text: string; DisplayText: Boolean);
begin
  Text := Sender.AsString;
end;

procedure TFormPrincipal.ChatIAAoConcluir(Sender: TObject);
begin
  BotaoEnviar.Enabled := True;
  ButtonLimpar.Enabled := True;
  ComboProvedor.Enabled := True;
  ComboModelo.Enabled := True;
  ComboModoConversa.Enabled := True;
  EditMensagem.SetFocus;
end;

procedure TFormPrincipal.ChatIAAoIniciarRequisicao(Sender: TObject);
begin
  BotaoEnviar.Enabled := False;
  ButtonLimpar.Enabled := False;
  ComboProvedor.Enabled := False;
  ComboModelo.Enabled := False;
  ComboModoConversa.Enabled := False;
end;

procedure TFormPrincipal.ChatIAAoOcorrerErro(Sender: TObject;
  const AErro: IErroChatIA);
begin
  if AErro <> nil then
    RegistrarMensagem('Erro', '%s;%s', [sLineBreak, AErro.Classe,
      AErro.Mensagem]);
end;

procedure TFormPrincipal.ChatIAAoReceberModelos(Sender: TObject;
  const AModelos: TArray<IModeloIA>);
var
  I: Integer;
  LIndicePadrao: Integer;
begin
  LIndicePadrao := -1;
  ComboModelo.Items.BeginUpdate;
  try
    ComboModelo.Clear;
    for I := Low(AModelos) to High(AModelos) do
    begin
      ComboModelo.Items.Add(AModelos[I].Id);
      if SameText(AModelos[I].Id, ChatIA.Provedor.ModeloPadrao) then
        LIndicePadrao := I;
    end;
    if (LIndicePadrao < 0) and (Length(AModelos) > 0) then
      LIndicePadrao := 0;
    ComboModelo.ItemIndex := LIndicePadrao;
  finally
    ComboModelo.Items.EndUpdate;
  end;
  SelecionarModelo;
end;

procedure TFormPrincipal.ChatIAAoRegistrarLog(Sender: TObject;
  const AEvento: IEventoLogIA);
begin
  if (AEvento = nil) then
    Exit;
  ClientDataSetLog.Append;
  try
    ClientDataSetLog.FieldByName(CCampoLogDataHoraUTC).AsDateTime :=
      AEvento.DataHoraUTC;
    ClientDataSetLog.FieldByName(CCampoLogTipo).AsString :=
      GetEnumName(TypeInfo(TTipoEventoLogIA), Ord(AEvento.Tipo));
    ClientDataSetLog.FieldByName(CCampoLogProvedor).AsString :=
      AEvento.Provedor;
    ClientDataSetLog.FieldByName(CCampoLogMensagem).AsString :=
      AEvento.Mensagem;
    ClientDataSetLog.FieldByName(CCampoLogStatusHTTP).AsInteger :=
      AEvento.StatusHTTP;
    ClientDataSetLog.Post;
  except
    ClientDataSetLog.Cancel;
    raise;
  end;
  RemoverLogsExcedentes;
end;

procedure TFormPrincipal.ChatIAAoReceberResposta(Sender: TObject;
  const AResposta: IRespostaChatIA);
var
  LDetalhesUso: string;
begin
  RegistrarMensagem(ComboProvedor.Text, AResposta.Mensagem.Texto, []);
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

procedure TFormPrincipal.ComboModeloChange(Sender: TObject);
begin
  SelecionarModelo;
end;

procedure TFormPrincipal.ComboProvedorChange(Sender: TObject);
begin
  SelecionarProvedor;
  PreencherModeloPadrao;
  SelecionarModelo;
end;

procedure TFormPrincipal.FormCreate(Sender: TObject);
begin
  CriarCamposLog;
  ComboProvedorChange(ComboProvedor);
end;

procedure TFormPrincipal.CriarCamposLog;
begin
  ClientDataSetLog.Close;
  ClientDataSetLog.FieldDefs.Clear;
  ClientDataSetLog.FieldDefs.Add(CCampoLogDataHoraUTC, ftDateTime);
  ClientDataSetLog.FieldDefs.Add(CCampoLogTipo, ftString, CTamanhoCampoTipoLog);
  ClientDataSetLog.FieldDefs.Add(CCampoLogProvedor, ftString,
    CTamanhoCampoProvedorLog);
  ClientDataSetLog.FieldDefs.Add(CCampoLogMensagem, ftMemo);
  ClientDataSetLog.FieldDefs.Add(CCampoLogStatusHTTP, ftInteger);
  ClientDataSetLog.CreateDataSet;
  TDateTimeField(ClientDataSetLog.FieldByName(CCampoLogDataHoraUTC)).DisplayFormat :=
    CFormatoDataHoraLog;
  ClientDataSetLog.FieldByName(CCampoLogMensagem).OnGetText :=
    CampoMensagemLogGetText;
end;

procedure TFormPrincipal.RemoverLogsExcedentes;
begin
  if ClientDataSetLog.RecordCount <= CLimiteLinhasLogExemplo then
    Exit;
  ClientDataSetLog.DisableControls;
  try
    ClientDataSetLog.First;
    while ClientDataSetLog.RecordCount > CLimiteLinhasLogExemplo do
      ClientDataSetLog.Delete;
    ClientDataSetLog.Last;
  finally
    ClientDataSetLog.EnableControls;
  end;
end;

procedure TFormPrincipal.RegistrarMensagem(const AEmissor, AMensagem: string;
  const Args: array of const);
begin
  MemoConversa.Lines.Add(AEmissor);
  MemoConversa.Lines.Add(Format(AMensagem, Args));
  MemoConversa.Lines.Add('----------');
  MemoConversa.Lines.Add(EmptyStr);
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

procedure TFormPrincipal.PreencherModeloPadrao;
begin
  ComboModelo.Clear;
  ComboModelo.Items.Add(ChatIA.Provedor.ModeloPadrao);
  ComboModelo.ItemIndex := 0;
end;

procedure TFormPrincipal.SelecionarModelo;
begin
  ChatIA.Modelo := '';
  if ComboModelo.ItemIndex >= 0 then
    ChatIA.Modelo := ComboModelo.Text;
end;


end.
