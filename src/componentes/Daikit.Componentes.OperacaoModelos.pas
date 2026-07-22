unit Daikit.Componentes.OperacaoModelos;

interface

uses
  System.Classes,
  Daikit.Dominio.Interfaces,
  Daikit.Aplicacao.Interfaces,
  Daikit.Componentes.OperacaoChat;

type
  TEventoConclusaoOperacaoModelosIA = reference to procedure(
    const AModelos: TArray<IModeloIA>; const AErro: IErroChatIA);

  TDadosOperacaoModelosIA = record
    Adaptador: IAdaptadorIA;
    TokenCancelamento: ITokenCancelamentoIA;
    AoConcluir: TEventoConclusaoOperacaoModelosIA;
  end;

  TOperacaoModelosIA = class(TThread)
  private
    FAdaptador: IAdaptadorIA;
    FTokenCancelamento: ITokenCancelamentoIA;
    FAoConcluir: TEventoConclusaoOperacaoModelosIA;
    FModelos: TArray<IModeloIA>;
    FErro: IErroChatIA;
    FDesconectada: Integer;
    function EstaDesconectada: Boolean;
    procedure EntregarResultado;
  protected
    procedure Execute; override;
  public
    constructor Create(const ADados: TDadosOperacaoModelosIA);
    procedure Desconectar;
  end;

implementation

uses
  System.SysUtils,
  System.SyncObjs,
  Daikit.Aplicacao.ServicoModelos,
  Daikit.Componentes.Excecoes;

type
  TErroModelosIA = class(TInterfacedObject, IErroChatIA)
  private
    FClasse: string;
    FMensagem: string;
    function ObterClasse: string;
    function ObterMensagem: string;
  public
    constructor Create(const AClasse, AMensagem: string);
  end;

constructor TErroModelosIA.Create(const AClasse, AMensagem: string);
begin
  inherited Create;
  FClasse := AClasse;
  FMensagem := AMensagem;
end;

function TErroModelosIA.ObterClasse: string;
begin
  Result := FClasse;
end;

function TErroModelosIA.ObterMensagem: string;
begin
  Result := FMensagem;
end;

constructor TOperacaoModelosIA.Create(const ADados: TDadosOperacaoModelosIA);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  if ADados.Adaptador = nil then
    raise EConfiguracaoComponenteIA.Create(
      'O adaptador deve ser informado para listar os modelos.');
  if ADados.TokenCancelamento = nil then
    raise EConfiguracaoComponenteIA.Create(
      'O token de cancelamento deve ser informado para listar os modelos.');
  if not Assigned(ADados.AoConcluir) then
    raise EConfiguracaoComponenteIA.Create(
      'O evento de conclusao deve ser informado para listar os modelos.');
  FAdaptador := ADados.Adaptador;
  FTokenCancelamento := ADados.TokenCancelamento;
  FAoConcluir := ADados.AoConcluir;
end;

procedure TOperacaoModelosIA.Desconectar;
begin
  TInterlocked.Exchange(FDesconectada, 1);
end;

function TOperacaoModelosIA.EstaDesconectada: Boolean;
begin
  Result := TInterlocked.CompareExchange(FDesconectada, 0, 0) <> 0;
end;

procedure TOperacaoModelosIA.EntregarResultado;
var
  LEventoConclusao: TEventoConclusaoOperacaoModelosIA;
begin
  if EstaDesconectada then
    Exit;
  LEventoConclusao := FAoConcluir;
  try
    if Assigned(LEventoConclusao) then
      LEventoConclusao(FModelos, FErro);
  finally
    if not EstaDesconectada then
    begin
      FAoConcluir := nil;
      Free;
    end;
  end;
end;

procedure TOperacaoModelosIA.Execute;
begin
  try
    FModelos := TServicoModelosIA.Listar(FAdaptador, FTokenCancelamento);
  except
    on E: Exception do
      FErro := TErroModelosIA.Create(E.ClassName, E.Message);
  end;
  TThread.Queue(Self, EntregarResultado);
end;

end.
