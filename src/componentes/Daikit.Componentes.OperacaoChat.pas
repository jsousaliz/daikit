unit Daikit.Componentes.OperacaoChat;

interface

uses
  System.Classes,
  Daikit.Dominio.Interfaces,
  Daikit.Aplicacao.Interfaces;

type
  IErroChatIA = interface
    ['{C87DC934-C3D2-4D17-B1D7-292D6934BB29}']
    function ObterClasse: string;
    function ObterMensagem: string;
    property Classe: string read ObterClasse;
    property Mensagem: string read ObterMensagem;
  end;

  TEventoConclusaoOperacaoChatIA = reference to procedure(
    const AResposta: IRespostaChatIA; const AErro: IErroChatIA);

  TDadosOperacaoChatIA = record
    Adaptador: IAdaptadorIA;
    Contexto: IContextoIA;
    TokenCancelamento: ITokenCancelamentoIA;
    Modelo: string;
    Texto: string;
    ModoConversa: TModoConversaIA;
    AoConcluir: TEventoConclusaoOperacaoChatIA;
  end;

  TOperacaoChatIA = class(TThread)
  private
    FAdaptador: IAdaptadorIA;
    FContexto: IContextoIA;
    FTokenCancelamento: ITokenCancelamentoIA;
    FModelo: string;
    FTexto: string;
    FModoConversa: TModoConversaIA;
    FAoConcluir: TEventoConclusaoOperacaoChatIA;
    FRespostaChat: IRespostaChatIA;
    FErroChat: IErroChatIA;
    FDesconectada: Integer;
    function EstaDesconectada: Boolean;
    procedure EntregarResultado;
  protected
    procedure Execute; override;
  public
    constructor Create(const ADados: TDadosOperacaoChatIA);
    procedure Desconectar;
  end;

implementation

uses
  System.SysUtils,
  System.SyncObjs,
  Daikit.Aplicacao.ServicoContexto,
  Daikit.Componentes.Excecoes;

type
  TErroChatIA = class(TInterfacedObject, IErroChatIA)
  private
    FClasse: string;
    FMensagem: string;
    function ObterClasse: string;
    function ObterMensagem: string;
  public
    constructor Create(const AClasse, AMensagem: string);
  end;

constructor TErroChatIA.Create(const AClasse, AMensagem: string);
begin
  inherited Create;
  FClasse := AClasse;
  FMensagem := AMensagem;
end;

function TErroChatIA.ObterClasse: string;
begin
  Result := FClasse;
end;

function TErroChatIA.ObterMensagem: string;
begin
  Result := FMensagem;
end;

constructor TOperacaoChatIA.Create(const ADados: TDadosOperacaoChatIA);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  if ADados.Adaptador = nil then
    raise EConfiguracaoComponenteIA.Create(
      'O adaptador deve ser informado para a operacao do chat.');
  if ADados.Contexto = nil then
    raise EConfiguracaoComponenteIA.Create(
      'O contexto deve ser informado para a operacao do chat.');
  if ADados.TokenCancelamento = nil then
    raise EConfiguracaoComponenteIA.Create(
      'O token de cancelamento deve ser informado para a operacao do chat.');
  if Trim(ADados.Texto) = '' then
    raise EConfiguracaoComponenteIA.Create(
      'O texto da mensagem deve ser informado para a operacao do chat.');
  if not Assigned(ADados.AoConcluir) then
    raise EConfiguracaoComponenteIA.Create(
      'O evento de conclusao deve ser informado para a operacao do chat.');

  FAdaptador := ADados.Adaptador;
  FContexto := ADados.Contexto;
  FTokenCancelamento := ADados.TokenCancelamento;
  FModelo := ADados.Modelo;
  FTexto := ADados.Texto;
  FModoConversa := ADados.ModoConversa;
  FAoConcluir := ADados.AoConcluir;
end;

procedure TOperacaoChatIA.Desconectar;
begin
  TInterlocked.Exchange(FDesconectada, 1);
end;

procedure TOperacaoChatIA.EntregarResultado;
var
  LEventoConclusao: TEventoConclusaoOperacaoChatIA;
begin
  if EstaDesconectada then
    Exit;
  LEventoConclusao := FAoConcluir;
  try
    if Assigned(LEventoConclusao) then
      LEventoConclusao(FRespostaChat, FErroChat);
  finally
    if not EstaDesconectada then
    begin
      FAoConcluir := nil;
      Free;
    end;
  end;
end;

function TOperacaoChatIA.EstaDesconectada: Boolean;
begin
  Result := TInterlocked.CompareExchange(FDesconectada, 0, 0) <> 0;
end;

procedure TOperacaoChatIA.Execute;
var
  LServicoContexto: TServicoContextoIA;
begin
  try
    LServicoContexto := TServicoContextoIA.Create(FAdaptador, FContexto);
    try
      FRespostaChat := LServicoContexto.Enviar(FModelo, FTexto,
        FModoConversa, FTokenCancelamento);
    finally
      LServicoContexto.Free;
    end;
  except
    on E: Exception do
      FErroChat := TErroChatIA.Create(E.ClassName, E.Message);
  end;
  TThread.Queue(Self, EntregarResultado);
end;

end.
