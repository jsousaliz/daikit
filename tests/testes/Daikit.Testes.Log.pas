unit Daikit.Testes.Log;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesLog = class
  public
    [Test] procedure Evento_DevePreservarDadosImutaveis;
    [Test] procedure Transporte_DeveExigirReceptor;
    [Test] procedure Transporte_DeveRegistrarRequisicaoEResposta;
    [Test] procedure Transporte_DeveRegistrarRespostaHTTPDeErro;
    [Test] procedure Transporte_DeveSanitizarSegredosEPreservarConteudo;
    [Test] procedure Transporte_DeveTratarJSONInvalido;
    [Test] procedure Transporte_DevePreservarExcecaoOriginal;
    [Test] procedure Transporte_DevePreservarCancelamento;
    [Test] procedure Transporte_DevePropagarFalhaDoReceptor;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  System.Generics.Collections,
  Daikit.Dominio.Excecoes,
  Daikit.Aplicacao.Interfaces,
  Daikit.Aplicacao.Log,
  Daikit.Aplicacao.TokenCancelamento,
  Daikit.Infraestrutura.HTTP.Interfaces,
  Daikit.Infraestrutura.HTTP.Modelos,
  Daikit.Infraestrutura.HTTP.Excecoes,
  Daikit.Infraestrutura.HTTP.Log,
  Daikit.Infraestrutura.JSON.Constantes,
  Daikit.Testes.TransporteHTTPFalso;

const
  CProvedorTeste = 'ProvedorTeste';
  CURLTeste = 'https://api.exemplo.test/v1/recurso';
  CStatusTeste = 201;
  CStatusErroTeste = 400;
  CQuantidadeCabecalhosTeste = 1;
  CIndiceCabecalhoTeste = 0;
  CQuantidadeEventosLogSucesso = 2;
  CIndiceEventoRequisicao = 0;
  CIndiceEventoResultado = 1;
  CJSONRequisicaoTeste = '{' + #34 + 'entrada' + #34 + ':true}';
  CJSONRespostaTeste = '{' + #34 + 'saida' + #34 + ':true}';
  CMensagemErroTransporte = 'falha programada do transporte';
  CMensagemErroReceptor = 'falha intencional do receptor de teste';

type
  TReceptorLogTeste = class(TInterfacedObject, IReceptorLogIA)
  private
    FEventos: TList<IEventoLogIA>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Registrar(const AEvento: IEventoLogIA);
    function Evento(AIndice: Integer): IEventoLogIA;
    function Quantidade: Integer;
  end;

  TReceptorLogComFalha = class(TInterfacedObject, IReceptorLogIA)
  public
    procedure Registrar(const AEvento: IEventoLogIA);
  end;

constructor TReceptorLogTeste.Create;
begin
  inherited Create;
  FEventos := TList<IEventoLogIA>.Create;
end;

destructor TReceptorLogTeste.Destroy;
begin
  FEventos.Free;
  inherited;
end;

function TReceptorLogTeste.Evento(AIndice: Integer): IEventoLogIA;
begin
  Result := FEventos[AIndice];
end;

function TReceptorLogTeste.Quantidade: Integer;
begin
  Result := FEventos.Count;
end;

procedure TReceptorLogTeste.Registrar(const AEvento: IEventoLogIA);
begin
  FEventos.Add(AEvento);
end;

procedure TReceptorLogComFalha.Registrar(const AEvento: IEventoLogIA);
begin
  raise Exception.Create(CMensagemErroReceptor);
end;

function CriarRequisicaoHTTP(
  const ACorpo: string = CJSONRequisicaoTeste): IRequisicaoHTTP;
var
  LCabecalhosHTTP: TArray<TCabecalhoHTTP>;
  LOpcoesRequisicaoHTTP: TOpcoesRequisicaoHTTP;
begin
  SetLength(LCabecalhosHTTP, CQuantidadeCabecalhosTeste);
  LCabecalhosHTTP[CIndiceCabecalhoTeste] := TCabecalhoHTTP.Criar('Authorization',
    'Bearer segredo-de-teste');
  LOpcoesRequisicaoHTTP := TOpcoesRequisicaoHTTP.Padrao;
  LOpcoesRequisicaoHTTP.Metodo := TMetodoHTTP.Post;
  LOpcoesRequisicaoHTTP.URL := CURLTeste + '?api_key=segredo#fragmento';
  LOpcoesRequisicaoHTTP.Cabecalhos := LCabecalhosHTTP;
  LOpcoesRequisicaoHTTP.Corpo := ACorpo;
  Result := TRequisicaoHTTP.Create(LOpcoesRequisicaoHTTP);
end;

function CriarRespostaHTTP(
  const ACorpo: string = CJSONRespostaTeste): IRespostaHTTP;
var
  LCabecalhosHTTP: TArray<TCabecalhoHTTP>;
begin
  Result := TRespostaHTTP.Create(CStatusTeste, 'Created', LCabecalhosHTTP,
    ACorpo);
end;

function CriarJSONComDoisCampos(const AChave1, AValor1, AChave2,
  AValor2: string): string;
begin
  Result := '{' + Char(34) + AChave1 + Char(34) + ':' + Char(34) +
    AValor1 + Char(34) + ',' + Char(34) + AChave2 + Char(34) + ':' +
    Char(34) + AValor2 + Char(34) + '}';
end;

procedure TTestesLog.Evento_DevePreservarDadosImutaveis;
var
  LDataHoraAntes: TDateTime;
  LDataHoraDepois: TDateTime;
  LEventoLog: IEventoLogIA;
begin
  LDataHoraAntes := TTimeZone.Local.ToUniversalTime(Now);
  LEventoLog := TEventoLogIA.Create(TTipoEventoLogIA.Resposta,
    CProvedorTeste, CJSONRespostaTeste, CStatusTeste);
  LDataHoraDepois := TTimeZone.Local.ToUniversalTime(Now);

  Assert.IsTrue(LEventoLog.Tipo = TTipoEventoLogIA.Resposta);
  Assert.AreEqual(CProvedorTeste, LEventoLog.Provedor);
  Assert.AreEqual(CJSONRespostaTeste, LEventoLog.Mensagem);
  Assert.IsTrue(LEventoLog.DataHoraUTC >= LDataHoraAntes);
  Assert.IsTrue(LEventoLog.DataHoraUTC <= LDataHoraDepois);
  Assert.AreEqual(CStatusTeste, LEventoLog.StatusHTTP);
end;

procedure TTestesLog.Transporte_DeveExigirReceptor;
var
  LTransporteHTTP: ITransporteHTTP;
begin
  LTransporteHTTP := TTransporteHTTPFalso.Create;
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TTransporteHTTPComLog.Create(LTransporteHTTP, nil, CProvedorTeste);
    end), EValidacaoHTTP);
end;

procedure TTestesLog.Transporte_DeveRegistrarRequisicaoEResposta;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LTransporteHTTPBase: ITransporteHTTP;
  LTransporteHTTPComLog: ITransporteHTTP;
  LReceptorLogTeste: TReceptorLogTeste;
  LReceptorLog: IReceptorLogIA;
  LRespostaEsperada: IRespostaHTTP;
begin
  LTransporteHTTPFalso := TTransporteHTTPFalso.Create;
  LTransporteHTTPBase := LTransporteHTTPFalso;
  LRespostaEsperada := CriarRespostaHTTP;
  LTransporteHTTPFalso.ProgramarResposta(LRespostaEsperada);
  LReceptorLogTeste := TReceptorLogTeste.Create;
  LReceptorLog := LReceptorLogTeste;
  LTransporteHTTPComLog := TTransporteHTTPComLog.Create(LTransporteHTTPBase,
    LReceptorLog, CProvedorTeste);

  Assert.IsTrue(LTransporteHTTPComLog.Enviar(CriarRequisicaoHTTP) =
    LRespostaEsperada);
  Assert.AreEqual(CQuantidadeEventosLogSucesso,
    LReceptorLogTeste.Quantidade);
  Assert.IsTrue(LReceptorLogTeste.Evento(CIndiceEventoRequisicao).Tipo =
    TTipoEventoLogIA.Requisicao);
  Assert.IsTrue(LReceptorLogTeste.Evento(CIndiceEventoResultado).Tipo =
    TTipoEventoLogIA.Resposta);
  Assert.AreEqual(CJSONRequisicaoTeste,
    LReceptorLogTeste.Evento(CIndiceEventoRequisicao).Mensagem);
  Assert.AreEqual(CJSONRespostaTeste,
    LReceptorLogTeste.Evento(CIndiceEventoResultado).Mensagem);
  Assert.AreEqual(CStatusTeste,
    LReceptorLogTeste.Evento(CIndiceEventoResultado).StatusHTTP);
end;

procedure TTestesLog.Transporte_DeveRegistrarRespostaHTTPDeErro;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LTransporteHTTPBase: ITransporteHTTP;
  LTransporteHTTPComLog: ITransporteHTTP;
  LReceptorLogTeste: TReceptorLogTeste;
  LReceptorLog: IReceptorLogIA;
  LRespostaHTTP: IRespostaHTTP;
  LCabecalhosHTTP: TArray<TCabecalhoHTTP>;
begin
  LTransporteHTTPFalso := TTransporteHTTPFalso.Create;
  LTransporteHTTPBase := LTransporteHTTPFalso;
  LRespostaHTTP := TRespostaHTTP.Create(CStatusErroTeste, 'Bad Request',
    LCabecalhosHTTP, CJSONRespostaTeste);
  LTransporteHTTPFalso.ProgramarResposta(LRespostaHTTP);
  LReceptorLogTeste := TReceptorLogTeste.Create;
  LReceptorLog := LReceptorLogTeste;
  LTransporteHTTPComLog := TTransporteHTTPComLog.Create(LTransporteHTTPBase,
    LReceptorLog, CProvedorTeste);

  Assert.IsTrue(LTransporteHTTPComLog.Enviar(CriarRequisicaoHTTP) = LRespostaHTTP);
  Assert.IsTrue(LReceptorLogTeste.Evento(CIndiceEventoResultado).Tipo =
    TTipoEventoLogIA.RespostaErro);
  Assert.AreEqual(CStatusErroTeste,
    LReceptorLogTeste.Evento(CIndiceEventoResultado).StatusHTTP);
end;

procedure TTestesLog.Transporte_DeveSanitizarSegredosEPreservarConteudo;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LTransporteHTTPBase: ITransporteHTTP;
  LTransporteHTTPComLog: ITransporteHTTP;
  LReceptorLogTeste: TReceptorLogTeste;
  LReceptorLog: IReceptorLogIA;
  LJSONRequisicao: string;
  LJSONResposta: string;
begin
  LJSONRequisicao := CriarJSONComDoisCampos('api_key', 'segredo-chave',
    'content', 'pergunta-visivel');
  LJSONResposta := CriarJSONComDoisCampos('password', 'senha-secreta',
    'content', 'resposta-visivel');
  LTransporteHTTPFalso := TTransporteHTTPFalso.Create;
  LTransporteHTTPBase := LTransporteHTTPFalso;
  LTransporteHTTPFalso.ProgramarResposta(CriarRespostaHTTP(LJSONResposta));
  LReceptorLogTeste := TReceptorLogTeste.Create;
  LReceptorLog := LReceptorLogTeste;
  LTransporteHTTPComLog := TTransporteHTTPComLog.Create(LTransporteHTTPBase,
    LReceptorLog, CProvedorTeste);

  LTransporteHTTPComLog.Enviar(CriarRequisicaoHTTP(LJSONRequisicao));

  Assert.IsFalse(LReceptorLogTeste.Evento(CIndiceEventoRequisicao).Mensagem.
    Contains('segredo-chave'));
  Assert.IsTrue(LReceptorLogTeste.Evento(CIndiceEventoRequisicao).Mensagem.
    Contains('pergunta-visivel'));
  Assert.IsFalse(LReceptorLogTeste.Evento(CIndiceEventoResultado).Mensagem.
    Contains('senha-secreta'));
  Assert.IsTrue(LReceptorLogTeste.Evento(CIndiceEventoResultado).Mensagem.
    Contains('resposta-visivel'));
end;

procedure TTestesLog.Transporte_DeveTratarJSONInvalido;
var
  LCorpoInvalido: string;
  LReceptorLogTeste: TReceptorLogTeste;
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LReceptorLog: IReceptorLogIA;
  LTransporteHTTPBase: ITransporteHTTP;
  LTransporteHTTPComLog: ITransporteHTTP;
begin
  LCorpoInvalido := '{api_key:segredo';
  LTransporteHTTPFalso := TTransporteHTTPFalso.Create;
  LTransporteHTTPBase := LTransporteHTTPFalso;
  LTransporteHTTPFalso.ProgramarResposta(CriarRespostaHTTP(LCorpoInvalido));
  LReceptorLogTeste := TReceptorLogTeste.Create;
  LReceptorLog := LReceptorLogTeste;
  LTransporteHTTPComLog := TTransporteHTTPComLog.Create(LTransporteHTTPBase,
    LReceptorLog, CProvedorTeste);

  LTransporteHTTPComLog.Enviar(CriarRequisicaoHTTP);

  Assert.IsTrue(LReceptorLogTeste.Evento(CIndiceEventoResultado).Mensagem.
    Contains(CJSONInvalidoRemovido));
  Assert.IsFalse(LReceptorLogTeste.Evento(CIndiceEventoResultado).Mensagem.
    Contains('segredo'));
end;

procedure TTestesLog.Transporte_DevePreservarExcecaoOriginal;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LTransporteHTTPBase: ITransporteHTTP;
  LTransporteHTTPComLog: ITransporteHTTP;
  LReceptorLogTeste: TReceptorLogTeste;
  LReceptorLog: IReceptorLogIA;
begin
  LTransporteHTTPFalso := TTransporteHTTPFalso.Create;
  LTransporteHTTPBase := LTransporteHTTPFalso;
  LTransporteHTTPFalso.ProgramarErro(CMensagemErroTransporte);
  LReceptorLogTeste := TReceptorLogTeste.Create;
  LReceptorLog := LReceptorLogTeste;
  LTransporteHTTPComLog := TTransporteHTTPComLog.Create(LTransporteHTTPBase,
    LReceptorLog, CProvedorTeste);

  try
    LTransporteHTTPComLog.Enviar(CriarRequisicaoHTTP);
    Assert.Fail('Era esperada uma ETransporteHTTP.');
  except
    on E: ETransporteHTTP do
      Assert.AreEqual(CMensagemErroTransporte, E.Message);
  end;
  Assert.IsTrue(LReceptorLogTeste.Evento(CIndiceEventoResultado).Tipo =
    TTipoEventoLogIA.Erro);
  Assert.IsTrue(LReceptorLogTeste.Evento(CIndiceEventoResultado).Mensagem.
    Contains(CMensagemErroTransporte));
end;

procedure TTestesLog.Transporte_DevePreservarCancelamento;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LTransporteHTTPBase: ITransporteHTTP;
  LTransporteHTTPComLog: ITransporteHTTP;
  LReceptorLogTeste: TReceptorLogTeste;
  LReceptorLog: IReceptorLogIA;
  LTokenCancelamento: ITokenCancelamentoIA;
begin
  LTransporteHTTPFalso := TTransporteHTTPFalso.Create;
  LTransporteHTTPBase := LTransporteHTTPFalso;
  LReceptorLogTeste := TReceptorLogTeste.Create;
  LReceptorLog := LReceptorLogTeste;
  LTransporteHTTPComLog := TTransporteHTTPComLog.Create(LTransporteHTTPBase,
    LReceptorLog, CProvedorTeste);
  LTokenCancelamento := TTokenCancelamentoIA.Create;
  LTokenCancelamento.Cancelar;

  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      LTransporteHTTPComLog.Enviar(CriarRequisicaoHTTP, LTokenCancelamento);
    end), EOperacaoCanceladaIA);
  Assert.IsTrue(LReceptorLogTeste.Evento(CIndiceEventoResultado).Tipo =
    TTipoEventoLogIA.Erro);
end;

procedure TTestesLog.Transporte_DevePropagarFalhaDoReceptor;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LTransporteHTTPBase: ITransporteHTTP;
  LTransporteHTTPComLog: ITransporteHTTP;
begin
  LTransporteHTTPFalso := TTransporteHTTPFalso.Create;
  LTransporteHTTPBase := LTransporteHTTPFalso;
  LTransporteHTTPFalso.ProgramarResposta(CriarRespostaHTTP);
  LTransporteHTTPComLog := TTransporteHTTPComLog.Create(LTransporteHTTPBase,
    TReceptorLogComFalha.Create, CProvedorTeste);

  Assert.WillRaiseWithMessage(
    TTestLocalMethod(procedure
    begin
      LTransporteHTTPComLog.Enviar(CriarRequisicaoHTTP);
    end), Exception, CMensagemErroReceptor);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesLog);

end.
