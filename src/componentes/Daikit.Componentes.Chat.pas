unit Daikit.Componentes.Chat;

interface

uses
  System.Classes,
  System.SysUtils,
  Daikit.Dominio.Interfaces,
  Daikit.Aplicacao.Interfaces,
  Daikit.Aplicacao.Log,
  Daikit.Componentes.OperacaoChat,
  Daikit.Componentes.OperacaoModelos,
  Daikit.Componentes.Provedor,
  Daikit.Componentes.Conversa;

type
  TEstadoChatIA = (Ocioso, Executando, CarregandoModelos, Cancelando);
  TEventoChatIA = procedure(Sender: TObject) of object;
  TEventoRespostaChatIA = procedure(Sender: TObject;
    const AResposta: IRespostaChatIA) of object;
  TEventoErroChatIA = procedure(Sender: TObject;
    const AErro: IErroChatIA) of object;
  TEventoRegistroLogIA = procedure(Sender: TObject;
    const AEvento: IEventoLogIA) of object;
  TEventoModelosIA = procedure(Sender: TObject;
    const AModelos: TArray<IModeloIA>) of object;

  TChatIA = class(TComponent)
  private
    FProvedor: TProvedorIA;
    FConversa: TConversaIA;
    FModelo: string;
    FModoConversa: TModoConversaIA;
    FEstado: TEstadoChatIA;
    FTokenCancelamento: ITokenCancelamentoIA;
    FOperacaoChat: TOperacaoChatIA;
    FOperacaoModelos: TOperacaoModelosIA;
    FDestruindo: Integer;
    FAoIniciarRequisicao: TEventoChatIA;
    FAoReceberResposta: TEventoRespostaChatIA;
    FAoOcorrerErro: TEventoErroChatIA;
    FAoConcluir: TEventoChatIA;
    FAoRegistrarLog: TEventoRegistroLogIA;
    FAoReceberModelos: TEventoModelosIA;
    procedure DefinirProvedor(AValor: TProvedorIA);
    procedure DefinirConversa(AValor: TConversaIA);
    function ObterContextoAtual: IContextoIA;
    function ObterAdaptadorAtual: IAdaptadorIA;
    function CriarReceptorLog: IReceptorLogIA;
    function EstaDestruindo: Boolean;
    procedure EnfileirarEventoLog(const AEvento: IEventoLogIA);
    procedure FinalizarOperacao(const AResposta: IRespostaChatIA;
      const AErro: IErroChatIA);
    procedure FinalizarModelos(const AModelos: TArray<IModeloIA>;
      const AErro: IErroChatIA);
    procedure RegistrarEventoLog(const AEvento: IEventoLogIA);
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Enviar(const ATexto: string);
    procedure CarregarModelos;
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
    property AoReceberModelos: TEventoModelosIA read FAoReceberModelos
      write FAoReceberModelos;
  end;

implementation

uses
  System.SyncObjs,
  Daikit.Aplicacao.TokenCancelamento,
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
  FChat.EnfileirarEventoLog(AEvento);
end;

constructor TChatIA.Create(AOwner: TComponent);
begin
  inherited;
  FEstado := TEstadoChatIA.Ocioso;
  FModoConversa := TModoConversaIA.ManterHistorico;
end;

destructor TChatIA.Destroy;
var
  LOperacaoChat: TOperacaoChatIA;
  LOperacaoModelos: TOperacaoModelosIA;
begin
  TInterlocked.Exchange(FDestruindo, 1);
  Cancelar;
  LOperacaoChat := FOperacaoChat;
  if LOperacaoChat <> nil then
  begin
    LOperacaoChat.Desconectar;
    TThread.RemoveQueuedEvents(LOperacaoChat);
    LOperacaoChat.WaitFor;
    TThread.RemoveQueuedEvents(LOperacaoChat);
    FOperacaoChat := nil;
    LOperacaoChat.Free;
  end;
  LOperacaoModelos := FOperacaoModelos;
  if LOperacaoModelos <> nil then
  begin
    LOperacaoModelos.Desconectar;
    TThread.RemoveQueuedEvents(LOperacaoModelos);
    LOperacaoModelos.WaitFor;
    TThread.RemoveQueuedEvents(LOperacaoModelos);
    FOperacaoModelos := nil;
    LOperacaoModelos.Free;
  end;
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
  if FEstado <> TEstadoChatIA.Ocioso then
    raise EEstadoComponenteIA.Create(
      'A conversa nao pode ser alterada durante uma operacao do chat.');
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
  if FEstado <> TEstadoChatIA.Ocioso then
    raise EEstadoComponenteIA.Create(
      'O provedor nao pode ser alterado durante uma operacao do chat.');
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

procedure TChatIA.EnfileirarEventoLog(const AEvento: IEventoLogIA);
var
  LOperacao: TThread;
begin
  if EstaDestruindo or not Assigned(FAoRegistrarLog) then
    Exit;
  LOperacao := FOperacaoChat;
  if LOperacao = nil then
    LOperacao := FOperacaoModelos;
  if LOperacao = nil then
    Exit;
  TThread.Queue(LOperacao,
    procedure
    begin
      if not EstaDestruindo and
        ((FOperacaoChat = LOperacao) or (FOperacaoModelos = LOperacao)) then
        RegistrarEventoLog(AEvento);
    end);
end;

procedure TChatIA.CarregarModelos;
var
  LDadosOperacaoModelos: TDadosOperacaoModelosIA;
begin
  if EstaDestruindo then
    raise EEstadoComponenteIA.Create(
      'O componente de chat esta sendo destruido.');
  if FEstado <> TEstadoChatIA.Ocioso then
    raise EEstadoComponenteIA.Create(
      'O componente de chat ja possui uma operacao em andamento.');
  LDadosOperacaoModelos.Adaptador := ObterAdaptadorAtual;
  FTokenCancelamento := TTokenCancelamentoIA.Create;
  LDadosOperacaoModelos.TokenCancelamento := FTokenCancelamento;
  LDadosOperacaoModelos.AoConcluir :=
    procedure(const AModelos: TArray<IModeloIA>; const AErro: IErroChatIA)
    begin
      FinalizarModelos(AModelos, AErro);
    end;
  FEstado := TEstadoChatIA.CarregandoModelos;
  try
    FOperacaoModelos := TOperacaoModelosIA.Create(LDadosOperacaoModelos);
    if Assigned(FAoIniciarRequisicao) then
      FAoIniciarRequisicao(Self);
    FOperacaoModelos.Start;
  except
    FOperacaoModelos.Free;
    FOperacaoModelos := nil;
    FTokenCancelamento := nil;
    FEstado := TEstadoChatIA.Ocioso;
    raise;
  end;
end;

procedure TChatIA.Enviar(const ATexto: string);
var
  LDadosOperacaoChat: TDadosOperacaoChatIA;
begin
  if EstaDestruindo then
    raise EEstadoComponenteIA.Create(
      'O componente de chat esta sendo destruido.');
  if FEstado <> TEstadoChatIA.Ocioso then
    raise EEstadoComponenteIA.Create(
      'O componente de chat ja possui uma operacao em andamento.');
  if Trim(ATexto) = '' then
    raise EConfiguracaoComponenteIA.Create(
      'O texto da mensagem deve ser informado.');

  LDadosOperacaoChat.Adaptador := ObterAdaptadorAtual;
  LDadosOperacaoChat.Contexto := ObterContextoAtual;
  FTokenCancelamento := TTokenCancelamentoIA.Create;
  LDadosOperacaoChat.TokenCancelamento := FTokenCancelamento;
  LDadosOperacaoChat.Modelo := FModelo;
  LDadosOperacaoChat.Texto := ATexto;
  LDadosOperacaoChat.ModoConversa := FModoConversa;
  LDadosOperacaoChat.AoConcluir :=
    procedure(const AResposta: IRespostaChatIA; const AErro: IErroChatIA)
    begin
      FinalizarOperacao(AResposta, AErro);
    end;

  FEstado := TEstadoChatIA.Executando;
  try
    FOperacaoChat := TOperacaoChatIA.Create(LDadosOperacaoChat);
    if Assigned(FAoIniciarRequisicao) then
      FAoIniciarRequisicao(Self);
    FOperacaoChat.Start;
  except
    FOperacaoChat.Free;
    FOperacaoChat := nil;
    FTokenCancelamento := nil;
    FEstado := TEstadoChatIA.Ocioso;
    raise;
  end;
end;

function TChatIA.EstaDestruindo: Boolean;
begin
  Result := TInterlocked.CompareExchange(FDestruindo, 0, 0) <> 0;
end;

procedure TChatIA.FinalizarOperacao(const AResposta: IRespostaChatIA;
  const AErro: IErroChatIA);
var
  LEventoConcluir: TEventoChatIA;
begin
  if EstaDestruindo then
    Exit;
  FOperacaoChat := nil;
  try
    if AErro <> nil then
    begin
      if Assigned(FAoOcorrerErro) then
        FAoOcorrerErro(Self, AErro);
    end
    else if Assigned(FAoReceberResposta) then
      FAoReceberResposta(Self, AResposta);
  finally
    FTokenCancelamento := nil;
    FEstado := TEstadoChatIA.Ocioso;
    LEventoConcluir := FAoConcluir;
    if Assigned(LEventoConcluir) then
      LEventoConcluir(Self);
  end;
end;

procedure TChatIA.FinalizarModelos(const AModelos: TArray<IModeloIA>;
  const AErro: IErroChatIA);
var
  LEventoConcluir: TEventoChatIA;
begin
  if EstaDestruindo then
    Exit;
  FOperacaoModelos := nil;
  try
    if AErro <> nil then
    begin
      if Assigned(FAoOcorrerErro) then
        FAoOcorrerErro(Self, AErro);
    end
    else if Assigned(FAoReceberModelos) then
      FAoReceberModelos(Self, AModelos);
  finally
    FTokenCancelamento := nil;
    FEstado := TEstadoChatIA.Ocioso;
    LEventoConcluir := FAoConcluir;
    if Assigned(LEventoConcluir) then
      LEventoConcluir(Self);
  end;
end;

procedure TChatIA.LimparHistorico;
begin
  if FEstado <> TEstadoChatIA.Ocioso then
    raise EEstadoComponenteIA.Create(
      'O historico nao pode ser limpo durante uma operacao do chat.');
  ObterContextoAtual.Limpar;
end;

procedure TChatIA.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if Operation = opRemove then
  begin
    if AComponent = FProvedor then
    begin
      Cancelar;
      FProvedor := nil;
    end;
    if AComponent = FConversa then
    begin
      Cancelar;
      FConversa := nil;
    end;
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
