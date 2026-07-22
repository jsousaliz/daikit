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
  LCabecalhos: TArray<TCabecalhoHTTP>;
begin
  SetLength(LCabecalhos, CQuantidadeCabecalhosTeste);
  LCabecalhos[CIndiceCabecalhoTeste] := TCabecalhoHTTP.Criar('Authorization',
    'Bearer segredo-de-teste');
  Result := TRequisicaoHTTP.Create(TMetodoHTTP.Post,
    CURLTeste + '?api_key=segredo#fragmento', LCabecalhos, ACorpo);
end;

function CriarRespostaHTTP(
  const ACorpo: string = CJSONRespostaTeste): IRespostaHTTP;
var
  LCabecalhos: TArray<TCabecalhoHTTP>;
begin
  Result := TRespostaHTTP.Create(CStatusTeste, 'Created', LCabecalhos,
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
  LEvento: IEventoLogIA;
begin
  LDataHoraAntes := TTimeZone.Local.ToUniversalTime(Now);
  LEvento := TEventoLogIA.Create(TTipoEventoLogIA.Resposta,
    TNivelLogIA.Informacao, CProvedorTeste, CJSONRespostaTeste,
    CStatusTeste);
  LDataHoraDepois := TTimeZone.Local.ToUniversalTime(Now);

  Assert.IsTrue(LEvento.Tipo = TTipoEventoLogIA.Resposta);
  Assert.IsTrue(LEvento.Nivel = TNivelLogIA.Informacao);
  Assert.AreEqual(CProvedorTeste, LEvento.Provedor);
  Assert.AreEqual(CJSONRespostaTeste, LEvento.Mensagem);
  Assert.IsTrue(LEvento.DataHoraUTC >= LDataHoraAntes);
  Assert.IsTrue(LEvento.DataHoraUTC <= LDataHoraDepois);
  Assert.AreEqual(CStatusTeste, LEvento.StatusHTTP);
end;

procedure TTestesLog.Transporte_DeveExigirReceptor;
var
  LTransporte: ITransporteHTTP;
begin
  LTransporte := TTransporteHTTPFalso.Create;
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TTransporteHTTPComLog.Create(LTransporte, nil, CProvedorTeste);
    end), EValidacaoHTTP);
end;

procedure TTestesLog.Transporte_DeveRegistrarRequisicaoEResposta;
var
  LObjetoTransporte: TTransporteHTTPFalso;
  LTransporteBase: ITransporteHTTP;
  LTransporteLog: ITransporteHTTP;
  LObjetoReceptor: TReceptorLogTeste;
  LReceptor: IReceptorLogIA;
  LRespostaEsperada: IRespostaHTTP;
begin
  LObjetoTransporte := TTransporteHTTPFalso.Create;
  LTransporteBase := LObjetoTransporte;
  LRespostaEsperada := CriarRespostaHTTP;
  LObjetoTransporte.ProgramarResposta(LRespostaEsperada);
  LObjetoReceptor := TReceptorLogTeste.Create;
  LReceptor := LObjetoReceptor;
  LTransporteLog := TTransporteHTTPComLog.Create(LTransporteBase,
    LReceptor, CProvedorTeste);

  Assert.IsTrue(LTransporteLog.Enviar(CriarRequisicaoHTTP) =
    LRespostaEsperada);
  Assert.AreEqual(CQuantidadeEventosLogSucesso,
    LObjetoReceptor.Quantidade);
  Assert.IsTrue(LObjetoReceptor.Evento(CIndiceEventoRequisicao).Tipo =
    TTipoEventoLogIA.Requisicao);
  Assert.IsTrue(LObjetoReceptor.Evento(CIndiceEventoResultado).Tipo =
    TTipoEventoLogIA.Resposta);
  Assert.AreEqual(CJSONRequisicaoTeste,
    LObjetoReceptor.Evento(CIndiceEventoRequisicao).Mensagem);
  Assert.AreEqual(CJSONRespostaTeste,
    LObjetoReceptor.Evento(CIndiceEventoResultado).Mensagem);
  Assert.AreEqual(CStatusTeste,
    LObjetoReceptor.Evento(CIndiceEventoResultado).StatusHTTP);
end;

procedure TTestesLog.Transporte_DeveRegistrarRespostaHTTPDeErro;
var
  LObjetoTransporte: TTransporteHTTPFalso;
  LTransporteBase: ITransporteHTTP;
  LTransporteLog: ITransporteHTTP;
  LObjetoReceptor: TReceptorLogTeste;
  LReceptor: IReceptorLogIA;
  LResposta: IRespostaHTTP;
  LCabecalhos: TArray<TCabecalhoHTTP>;
begin
  LObjetoTransporte := TTransporteHTTPFalso.Create;
  LTransporteBase := LObjetoTransporte;
  LResposta := TRespostaHTTP.Create(CStatusErroTeste, 'Bad Request',
    LCabecalhos, CJSONRespostaTeste);
  LObjetoTransporte.ProgramarResposta(LResposta);
  LObjetoReceptor := TReceptorLogTeste.Create;
  LReceptor := LObjetoReceptor;
  LTransporteLog := TTransporteHTTPComLog.Create(LTransporteBase,
    LReceptor, CProvedorTeste);

  Assert.IsTrue(LTransporteLog.Enviar(CriarRequisicaoHTTP) = LResposta);
  Assert.IsTrue(LObjetoReceptor.Evento(CIndiceEventoResultado).Nivel =
    TNivelLogIA.Erro);
  Assert.AreEqual(CStatusErroTeste,
    LObjetoReceptor.Evento(CIndiceEventoResultado).StatusHTTP);
end;

procedure TTestesLog.Transporte_DeveSanitizarSegredosEPreservarConteudo;
var
  LObjetoTransporte: TTransporteHTTPFalso;
  LTransporteBase: ITransporteHTTP;
  LTransporteLog: ITransporteHTTP;
  LObjetoReceptor: TReceptorLogTeste;
  LReceptor: IReceptorLogIA;
  LJSONRequisicao: string;
  LJSONResposta: string;
begin
  LJSONRequisicao := CriarJSONComDoisCampos('api_key', 'segredo-chave',
    'content', 'pergunta-visivel');
  LJSONResposta := CriarJSONComDoisCampos('password', 'senha-secreta',
    'content', 'resposta-visivel');
  LObjetoTransporte := TTransporteHTTPFalso.Create;
  LTransporteBase := LObjetoTransporte;
  LObjetoTransporte.ProgramarResposta(CriarRespostaHTTP(LJSONResposta));
  LObjetoReceptor := TReceptorLogTeste.Create;
  LReceptor := LObjetoReceptor;
  LTransporteLog := TTransporteHTTPComLog.Create(LTransporteBase,
    LReceptor, CProvedorTeste);

  LTransporteLog.Enviar(CriarRequisicaoHTTP(LJSONRequisicao));

  Assert.IsFalse(LObjetoReceptor.Evento(CIndiceEventoRequisicao).Mensagem.
    Contains('segredo-chave'));
  Assert.IsTrue(LObjetoReceptor.Evento(CIndiceEventoRequisicao).Mensagem.
    Contains('pergunta-visivel'));
  Assert.IsFalse(LObjetoReceptor.Evento(CIndiceEventoResultado).Mensagem.
    Contains('senha-secreta'));
  Assert.IsTrue(LObjetoReceptor.Evento(CIndiceEventoResultado).Mensagem.
    Contains('resposta-visivel'));
end;

procedure TTestesLog.Transporte_DeveTratarJSONInvalido;
var
  LCorpoInvalido: string;
  LObjetoReceptor: TReceptorLogTeste;
  LObjetoTransporte: TTransporteHTTPFalso;
  LReceptor: IReceptorLogIA;
  LTransporteBase: ITransporteHTTP;
  LTransporteLog: ITransporteHTTP;
begin
  LCorpoInvalido := '{api_key:segredo';
  LObjetoTransporte := TTransporteHTTPFalso.Create;
  LTransporteBase := LObjetoTransporte;
  LObjetoTransporte.ProgramarResposta(CriarRespostaHTTP(LCorpoInvalido));
  LObjetoReceptor := TReceptorLogTeste.Create;
  LReceptor := LObjetoReceptor;
  LTransporteLog := TTransporteHTTPComLog.Create(LTransporteBase,
    LReceptor, CProvedorTeste);

  LTransporteLog.Enviar(CriarRequisicaoHTTP);

  Assert.IsTrue(LObjetoReceptor.Evento(CIndiceEventoResultado).Mensagem.
    Contains(CJSONInvalidoRemovido));
  Assert.IsFalse(LObjetoReceptor.Evento(CIndiceEventoResultado).Mensagem.
    Contains('segredo'));
end;

procedure TTestesLog.Transporte_DevePreservarExcecaoOriginal;
var
  LObjetoTransporte: TTransporteHTTPFalso;
  LTransporteBase: ITransporteHTTP;
  LTransporteLog: ITransporteHTTP;
  LObjetoReceptor: TReceptorLogTeste;
  LReceptor: IReceptorLogIA;
begin
  LObjetoTransporte := TTransporteHTTPFalso.Create;
  LTransporteBase := LObjetoTransporte;
  LObjetoTransporte.ProgramarErro(CMensagemErroTransporte);
  LObjetoReceptor := TReceptorLogTeste.Create;
  LReceptor := LObjetoReceptor;
  LTransporteLog := TTransporteHTTPComLog.Create(LTransporteBase,
    LReceptor, CProvedorTeste);

  try
    LTransporteLog.Enviar(CriarRequisicaoHTTP);
    Assert.Fail('Era esperada uma ETransporteHTTP.');
  except
    on E: ETransporteHTTP do
      Assert.AreEqual(CMensagemErroTransporte, E.Message);
  end;
  Assert.IsTrue(LObjetoReceptor.Evento(CIndiceEventoResultado).Tipo =
    TTipoEventoLogIA.Erro);
  Assert.IsTrue(LObjetoReceptor.Evento(CIndiceEventoResultado).Mensagem.
    Contains(CMensagemErroTransporte));
end;

procedure TTestesLog.Transporte_DevePreservarCancelamento;
var
  LObjetoTransporte: TTransporteHTTPFalso;
  LTransporteBase: ITransporteHTTP;
  LTransporteLog: ITransporteHTTP;
  LObjetoReceptor: TReceptorLogTeste;
  LReceptor: IReceptorLogIA;
  LCancelamento: ITokenCancelamentoIA;
begin
  LObjetoTransporte := TTransporteHTTPFalso.Create;
  LTransporteBase := LObjetoTransporte;
  LObjetoReceptor := TReceptorLogTeste.Create;
  LReceptor := LObjetoReceptor;
  LTransporteLog := TTransporteHTTPComLog.Create(LTransporteBase,
    LReceptor, CProvedorTeste);
  LCancelamento := TTokenCancelamentoIA.Create;
  LCancelamento.Cancelar;

  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      LTransporteLog.Enviar(CriarRequisicaoHTTP, LCancelamento);
    end), EOperacaoCanceladaIA);
  Assert.IsTrue(LObjetoReceptor.Evento(CIndiceEventoResultado).Tipo =
    TTipoEventoLogIA.Cancelamento);
end;

procedure TTestesLog.Transporte_DevePropagarFalhaDoReceptor;
var
  LObjetoTransporte: TTransporteHTTPFalso;
  LTransporteBase: ITransporteHTTP;
  LTransporteLog: ITransporteHTTP;
begin
  LObjetoTransporte := TTransporteHTTPFalso.Create;
  LTransporteBase := LObjetoTransporte;
  LObjetoTransporte.ProgramarResposta(CriarRespostaHTTP);
  LTransporteLog := TTransporteHTTPComLog.Create(LTransporteBase,
    TReceptorLogComFalha.Create, CProvedorTeste);

  Assert.WillRaiseWithMessage(
    TTestLocalMethod(procedure
    begin
      LTransporteLog.Enviar(CriarRequisicaoHTTP);
    end), Exception, CMensagemErroReceptor);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesLog);

end.
