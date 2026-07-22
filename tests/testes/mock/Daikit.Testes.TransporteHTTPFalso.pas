unit Daikit.Testes.TransporteHTTPFalso;

interface

uses
  Daikit.Aplicacao.Interfaces,
  Daikit.Infraestrutura.HTTP.Interfaces;

type
  TTransporteHTTPFalso = class(TInterfacedObject, ITransporteHTTP)
  private
    FResposta: IRespostaHTTP;
    FUltimaRequisicao: IRequisicaoHTTP;
    FQuantidadeChamadas: Integer;
    FMensagemErro: string;
    function ObterUltimaRequisicao: IRequisicaoHTTP;
    function ObterQuantidadeChamadas: Integer;
  public
    procedure ProgramarResposta(const AResposta: IRespostaHTTP);
    procedure ProgramarErro(const AMensagem: string);
    function Enviar(const ARequisicao: IRequisicaoHTTP;
      const ACancelamento: ITokenCancelamentoIA = nil): IRespostaHTTP;
    property UltimaRequisicao: IRequisicaoHTTP read ObterUltimaRequisicao;
    property QuantidadeChamadas: Integer read ObterQuantidadeChamadas;
  end;

implementation

uses
  System.SysUtils,
  Daikit.Dominio.Excecoes,
  Daikit.Infraestrutura.HTTP.Excecoes;

function TTransporteHTTPFalso.Enviar(const ARequisicao: IRequisicaoHTTP;
  const ACancelamento: ITokenCancelamentoIA): IRespostaHTTP;
var
  LMensagemErro: string;
begin
  if ARequisicao = nil then
    raise EValidacaoHTTP.Create('A requisicao do transporte falso deve ser informada.');
  if (ACancelamento <> nil) and ACancelamento.FoiCancelado then
    raise EOperacaoCanceladaIA.Create('A operacao foi cancelada no transporte falso.');

  TMonitor.Enter(Self);
  try
    Inc(FQuantidadeChamadas);
    FUltimaRequisicao := ARequisicao;
    Result := FResposta;
    LMensagemErro := FMensagemErro;
  finally
    TMonitor.Exit(Self);
  end;

  if LMensagemErro <> '' then
    raise ETransporteHTTP.Create(LMensagemErro);
  if Result = nil then
    raise ETransporteHTTP.Create('O transporte falso nao possui resposta programada.');
end;

function TTransporteHTTPFalso.ObterQuantidadeChamadas: Integer;
begin
  TMonitor.Enter(Self);
  try
    Result := FQuantidadeChamadas;
  finally
    TMonitor.Exit(Self);
  end;
end;

function TTransporteHTTPFalso.ObterUltimaRequisicao: IRequisicaoHTTP;
begin
  TMonitor.Enter(Self);
  try
    Result := FUltimaRequisicao;
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TTransporteHTTPFalso.ProgramarErro(const AMensagem: string);
begin
  TMonitor.Enter(Self);
  try
    FMensagemErro := AMensagem;
    FResposta := nil;
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TTransporteHTTPFalso.ProgramarResposta(
  const AResposta: IRespostaHTTP);
begin
  if AResposta = nil then
    raise EValidacaoHTTP.Create('A resposta programada deve ser informada.');
  TMonitor.Enter(Self);
  try
    FResposta := AResposta;
    FMensagemErro := '';
  finally
    TMonitor.Exit(Self);
  end;
end;

end.
