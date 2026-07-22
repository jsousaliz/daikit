unit Daikit.Componentes.Chat;

interface

uses
  System.Classes,
  System.SysUtils,
  Daikit.Dominio.Interfaces,
  Daikit.Aplicacao.Interfaces,
  Daikit.Aplicacao.Log,
  Daikit.Componentes.Provedor,
  Daikit.Componentes.Conversa;

type
  TEstadoChatIA = (Ocioso, Executando, Cancelando);
  TEventoChatIA = procedure(Sender: TObject) of object;
  TEventoRespostaChatIA = procedure(Sender: TObject;
    const AResposta: IRespostaChatIA) of object;
  TEventoErroChatIA = procedure(Sender: TObject;
    const AExcecao: Exception) of object;
  TEventoRegistroLogIA = procedure(Sender: TObject;
    const AEvento: IEventoLogIA) of object;

  TChatIA = class(TComponent)
  private
    FProvedor: TProvedorIA;
    FConversa: TConversaIA;
    FModelo: string;
    FModoConversa: TModoConversaIA;
    FEstado: TEstadoChatIA;
    FTokenCancelamento: ITokenCancelamentoIA;
    FAoIniciarRequisicao: TEventoChatIA;
    FAoReceberResposta: TEventoRespostaChatIA;
    FAoOcorrerErro: TEventoErroChatIA;
    FAoConcluir: TEventoChatIA;
    FAoRegistrarLog: TEventoRegistroLogIA;
    procedure DefinirProvedor(AValor: TProvedorIA);
    procedure DefinirConversa(AValor: TConversaIA);
    function ObterContextoAtual: IContextoIA;
    function ObterAdaptadorAtual: IAdaptadorIA;
    function CriarReceptorLog: IReceptorLogIA;
    procedure RegistrarEventoLog(const AEvento: IEventoLogIA);
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Enviar(const ATexto: string): IRespostaChatIA;
    function EnviarTexto(const ATexto: string): string;
    procedure Cancelar;
    procedure LimparHistorico;
    function ObterMensagens: TArray<IMensagemIA>;
    property Estado: TEstadoChatIA read FEstado;
  published
    property Provedor: TProvedorIA read FProvedor write DefinirProvedor;
    property Conversa: TConversaIA read FConversa write DefinirConversa;
    property Modelo: string read FModelo write FModelo;
    property ModoConversa: TModoConversaIA read FModoConversa
      write FModoConversa default TModoConversaIA.ManterHistorico;
    property AoIniciarRequisicao: TEventoChatIA read FAoIniciarRequisicao
      write FAoIniciarRequisicao;
    property AoReceberResposta: TEventoRespostaChatIA
      read FAoReceberResposta write FAoReceberResposta;
    property AoOcorrerErro: TEventoErroChatIA read FAoOcorrerErro
      write FAoOcorrerErro;
    property AoConcluir: TEventoChatIA read FAoConcluir write FAoConcluir;
    property AoRegistrarLog: TEventoRegistroLogIA read FAoRegistrarLog
      write FAoRegistrarLog;
  end;

implementation

uses
  Daikit.Aplicacao.TokenCancelamento,
  Daikit.Aplicacao.ServicoContexto,
  Daikit.Componentes.Excecoes;

type
  TReceptorLogChat = class(TInterfacedObject, IReceptorLogIA)
  private
    FChat: TChatIA;
  public
    constructor Create(AChat: TChatIA);
    procedure Registrar(const AEvento: IEventoLogIA);
  end;

constructor TReceptorLogChat.Create(AChat: TChatIA);
begin
  inherited Create;
  FChat := AChat;
end;

procedure TReceptorLogChat.Registrar(const AEvento: IEventoLogIA);
begin
  FChat.RegistrarEventoLog(AEvento);
end;

constructor TChatIA.Create(AOwner: TComponent);
begin
  inherited;
  FEstado := TEstadoChatIA.Ocioso;
  FModoConversa := TModoConversaIA.ManterHistorico;
end;

destructor TChatIA.Destroy;
begin
  Cancelar;
  FTokenCancelamento := nil;
  inherited;
end;

procedure TChatIA.Cancelar;
begin
  if FTokenCancelamento <> nil then
  begin
    FEstado := TEstadoChatIA.Cancelando;
    FTokenCancelamento.Cancelar;
  end;
end;

procedure TChatIA.DefinirConversa(AValor: TConversaIA);
begin
  if FConversa = AValor then
    Exit;
  if FConversa <> nil then
    FConversa.RemoveFreeNotification(Self);
  FConversa := AValor;
  if FConversa <> nil then
    FConversa.FreeNotification(Self);
end;

procedure TChatIA.DefinirProvedor(AValor: TProvedorIA);
begin
  if FProvedor = AValor then
    Exit;
  if FProvedor <> nil then
    FProvedor.RemoveFreeNotification(Self);
  FProvedor := AValor;
  if FProvedor <> nil then
    FProvedor.FreeNotification(Self);
end;

function TChatIA.CriarReceptorLog: IReceptorLogIA;
begin
  if Assigned(FAoRegistrarLog) then
    Result := TReceptorLogChat.Create(Self)
  else
    Result := nil;
end;

function TChatIA.Enviar(const ATexto: string): IRespostaChatIA;
var
  LServicoContexto: TServicoContextoIA;
begin
  if FEstado <> TEstadoChatIA.Ocioso then
    raise EEstadoComponenteIA.Create(
      'O componente de chat ja possui uma operacao em andamento.');
  FEstado := TEstadoChatIA.Executando;
  FTokenCancelamento := TTokenCancelamentoIA.Create;
  try
    try
      if Assigned(FAoIniciarRequisicao) then
        FAoIniciarRequisicao(Self);
      LServicoContexto := TServicoContextoIA.Create(ObterAdaptadorAtual,
        ObterContextoAtual);
      try
        Result := LServicoContexto.Enviar(FModelo, ATexto, FModoConversa,
          FTokenCancelamento);
      finally
        LServicoContexto.Free;
      end;
      if Assigned(FAoReceberResposta) then
        FAoReceberResposta(Self, Result);
    except
      on E: Exception do
      begin
        if Assigned(FAoOcorrerErro) then
          FAoOcorrerErro(Self, E);
        raise;
      end;
    end;
  finally
    FTokenCancelamento := nil;
    FEstado := TEstadoChatIA.Ocioso;
    if Assigned(FAoConcluir) then
      FAoConcluir(Self);
  end;
end;

function TChatIA.EnviarTexto(const ATexto: string): string;
var
  LRespostaChat: IRespostaChatIA;
begin
  LRespostaChat := Enviar(ATexto);
  Result := LRespostaChat.Mensagem.Texto;
end;

procedure TChatIA.LimparHistorico;
begin
  ObterContextoAtual.Limpar;
end;

procedure TChatIA.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if Operation = opRemove then
  begin
    if AComponent = FProvedor then
      FProvedor := nil;
    if AComponent = FConversa then
      FConversa := nil;
  end;
end;

function TChatIA.ObterContextoAtual: IContextoIA;
begin
  if FConversa = nil then
    raise EConfiguracaoComponenteIA.Create(
      'O componente de conversa deve ser informado no chat.');
  Result := FConversa.ObterContexto;
end;

function TChatIA.ObterMensagens: TArray<IMensagemIA>;
begin
  Result := ObterContextoAtual.ObterMensagens;
end;

function TChatIA.ObterAdaptadorAtual: IAdaptadorIA;
begin
  if FProvedor = nil then
    raise EConfiguracaoComponenteIA.Create(
      'O provedor do componente de chat deve ser informado.');
  Result := FProvedor.CriarAdaptador(CriarReceptorLog);
end;

procedure TChatIA.RegistrarEventoLog(const AEvento: IEventoLogIA);
begin
  if Assigned(FAoRegistrarLog) then
    FAoRegistrarLog(Self, AEvento);
end;

initialization
  RegisterClass(TChatIA);

end.
