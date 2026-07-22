unit Daikit.Testes.HTTP;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesHTTP = class
  public
    [Test] procedure Requisicao_DevePreservarDados;
    [Test] procedure Requisicao_DeveProtegerCabecalhos;
    [Test] procedure Requisicao_NaoDeveAceitarURLVazia;
    [Test] procedure Requisicao_NaoDeveAceitarEsquemaInvalido;
    [Test] procedure Requisicao_NaoDeveAceitarURLSemHost;
    [Test] procedure Requisicao_NaoDeveAceitarTimeoutInvalido;
    [Test] procedure Requisicao_NaoDeveAceitarQuebraLinhaEmCabecalho;
    [Test] procedure Resposta_DeveIdentificarSucesso;
    [Test] procedure Resposta_DeveIdentificarFalha;
    [Test] procedure Resposta_NaoDeveAceitarStatusInvalido;
    [Test] procedure Cabecalho_DeveObterValorSemDiferenciarMaiusculas;
    [Test] procedure Timeout_DeveEspecializarFalhaTransporte;
    [Test] procedure FluxoLimitado_DeveAceitarConteudoDentroDoLimite;
    [Test] procedure FluxoLimitado_DeveRecusarConteudoAcimaDoLimite;
    [Test] procedure Sanitizador_DeveOcultarCabecalhosSensiveis;
    [Test] procedure Sanitizador_DeveRemoverConsultaCompleta;
    [Test] procedure Sanitizador_DeveRemoverConsultaCodificada;
    [Test] procedure Sanitizador_DeveRemoverFragmentoDaURL;
    [Test] procedure TransporteNativo_DeveDesabilitarRedirecionamentos;
    [Test] procedure TransporteNativo_DeveRespeitarCancelamentoPreExecutado;
    [Test] procedure TransporteFalso_DeveRetornarRespostaProgramada;
    [Test] procedure TransporteFalso_DeveSimularErro;
    [Test] procedure TransporteFalso_DeveAceitarChamadasConcorrentes;
  end;

implementation

uses
  System.Classes,
  System.SysUtils,
  System.Net.HttpClient,
  Daikit.Testes.Constantes,
  Daikit.Testes.TransporteHTTPFalso,
  Daikit.Dominio.Excecoes,
  Daikit.Aplicacao.Interfaces,
  Daikit.Aplicacao.TokenCancelamento,
  Daikit.Infraestrutura.HTTP.Constantes,
  Daikit.Infraestrutura.HTTP.Interfaces,
  Daikit.Infraestrutura.HTTP.Excecoes,
  Daikit.Infraestrutura.HTTP.Modelos,
  Daikit.Infraestrutura.HTTP.FluxoLimitado,
  Daikit.Infraestrutura.HTTP.Sanitizador,
  Daikit.Infraestrutura.HTTP.Transporte;

type
  TTransporteHTTPClientExposto = class(TTransporteHTTPClient)
  public
    function CriarClienteParaTeste: THTTPClient;
  end;

procedure TTestesHTTP.Cabecalho_DeveObterValorSemDiferenciarMaiusculas;
var
  LCabecalhos: TArray<TCabecalhoHTTP>;
begin
  SetLength(LCabecalhos, 1);
  LCabecalhos[0] := TCabecalhoHTTP.Criar('X-Request-Id', 'req-123');
  Assert.AreEqual('req-123',
    TCabecalhoHTTP.ObterValor(LCabecalhos, 'x-request-id'));
  Assert.AreEqual('',
    TCabecalhoHTTP.ObterValor(LCabecalhos, 'cabecalho-ausente'));
end;

function TTransporteHTTPClientExposto.CriarClienteParaTeste: THTTPClient;
begin
  Result := CriarCliente;
end;

function CriarRequisicaoHTTP: IRequisicaoHTTP;
var
  LCabecalhos: TArray<TCabecalhoHTTP>;
begin
  SetLength(LCabecalhos, 1);
  LCabecalhos[Low(LCabecalhos)] := TCabecalhoHTTP.Criar(
    'Content-Type', 'application/json');
  Result := TRequisicaoHTTP.Create(TMetodoHTTP.Post,
    'https://api.exemplo.test/v1/chat', LCabecalhos, '{"texto":"ola"}');
end;

procedure TTestesHTTP.FluxoLimitado_DeveAceitarConteudoDentroDoLimite;
var
  LFluxo: TFluxoRespostaLimitado;
  LConteudo: TBytes;
  LResultado: Integer;
begin
  LFluxo := TFluxoRespostaLimitado.Create(4);
  try
    LConteudo := TEncoding.UTF8.GetBytes('1234');
    LResultado := LFluxo.Write(LConteudo[Low(LConteudo)], Length(LConteudo));
    Assert.AreEqual(Integer(Length(LConteudo)), LResultado);
  finally
    LFluxo.Free;
  end;
end;

procedure TTestesHTTP.FluxoLimitado_DeveRecusarConteudoAcimaDoLimite;
var
  LFluxo: TFluxoRespostaLimitado;
  LConteudo: TBytes;
  LAcao: TTestLocalMethod;
begin
  LFluxo := TFluxoRespostaLimitado.Create(3);
  try
    LConteudo := TEncoding.UTF8.GetBytes('1234');
    LAcao := procedure
    begin
      LFluxo.Write(LConteudo[Low(LConteudo)], Length(LConteudo));
    end;
    Assert.WillRaise(LAcao, ELimiteRespostaHTTP);
  finally
    LFluxo.Free;
  end;
end;

procedure TTestesHTTP.Requisicao_DevePreservarDados;
var
  LRequisicao: IRequisicaoHTTP;
begin
  LRequisicao := CriarRequisicaoHTTP;
  Assert.AreEqual(Integer(TMetodoHTTP.Post), Integer(LRequisicao.Metodo));
  Assert.AreEqual('https://api.exemplo.test/v1/chat', LRequisicao.URL);
  Assert.AreEqual('{"texto":"ola"}', LRequisicao.Corpo);
  Assert.AreEqual(CTimeoutConexaoPadraoMS, LRequisicao.TimeoutConexaoMS);
  Assert.AreEqual(CTimeoutRespostaPadraoMS, LRequisicao.TimeoutRespostaMS);
  Assert.AreEqual(Int64(CLimiteRespostaPadraoBytes),
    LRequisicao.LimiteRespostaBytes);
end;

procedure TTestesHTTP.Requisicao_DeveProtegerCabecalhos;
var
  LRequisicao: IRequisicaoHTTP;
  LCabecalhos: TArray<TCabecalhoHTTP>;
begin
  LRequisicao := CriarRequisicaoHTTP;
  LCabecalhos := LRequisicao.Cabecalhos;
  LCabecalhos[Low(LCabecalhos)].Valor := 'alterado';
  Assert.AreEqual('application/json',
    LRequisicao.Cabecalhos[Low(LRequisicao.Cabecalhos)].Valor);
end;

procedure TTestesHTTP.Requisicao_NaoDeveAceitarQuebraLinhaEmCabecalho;
var
  LCabecalhos: TArray<TCabecalhoHTTP>;
  LAcao: TTestLocalMethod;
begin
  SetLength(LCabecalhos, 1);
  LCabecalhos[Low(LCabecalhos)] := TCabecalhoHTTP.Criar(
    'Authorization', 'segredo' + #13#10 + 'Injetado: sim');
  LAcao := procedure
  begin
    TRequisicaoHTTP.Create(TMetodoHTTP.Get, 'https://exemplo.test',
      LCabecalhos).Free;
  end;
  Assert.WillRaise(LAcao, EValidacaoHTTP);
end;

procedure TTestesHTTP.Requisicao_NaoDeveAceitarEsquemaInvalido;
var
  LAcao: TTestLocalMethod;
begin
  LAcao := procedure
  begin
    TRequisicaoHTTP.Create(TMetodoHTTP.Get, 'file://arquivo-local', nil).Free;
  end;
  Assert.WillRaise(LAcao, EValidacaoHTTP);
end;

procedure TTestesHTTP.Requisicao_NaoDeveAceitarURLSemHost;
var
  LAcao: TTestLocalMethod;
begin
  LAcao := procedure
  begin
    TRequisicaoHTTP.Create(TMetodoHTTP.Get, 'https://', nil).Free;
  end;
  Assert.WillRaise(LAcao, EValidacaoHTTP);
end;

procedure TTestesHTTP.Requisicao_NaoDeveAceitarTimeoutInvalido;
var
  LAcao: TTestLocalMethod;
begin
  LAcao := procedure
  begin
    TRequisicaoHTTP.Create(TMetodoHTTP.Get, 'https://exemplo.test', nil,
      '', 0).Free;
  end;
  Assert.WillRaise(LAcao, EValidacaoHTTP);
end;

procedure TTestesHTTP.Requisicao_NaoDeveAceitarURLVazia;
var
  LAcao: TTestLocalMethod;
begin
  LAcao := procedure
  begin
    TRequisicaoHTTP.Create(TMetodoHTTP.Get, '', nil).Free;
  end;
  Assert.WillRaise(LAcao, EValidacaoHTTP);
end;

procedure TTestesHTTP.Resposta_DeveIdentificarFalha;
var
  LResposta: IRespostaHTTP;
begin
  LResposta := TRespostaHTTP.Create(429, 'Too Many Requests', nil, '{}');
  Assert.IsFalse(LResposta.FoiSucesso);
  Assert.AreEqual(429, LResposta.Status);
end;

procedure TTestesHTTP.Resposta_DeveIdentificarSucesso;
var
  LResposta: IRespostaHTTP;
begin
  LResposta := TRespostaHTTP.Create(200, 'OK', nil, '{"ok":true}');
  Assert.IsTrue(LResposta.FoiSucesso);
  Assert.AreEqual('{"ok":true}', LResposta.Corpo);
end;

procedure TTestesHTTP.Resposta_NaoDeveAceitarStatusInvalido;
var
  LAcao: TTestLocalMethod;
begin
  LAcao := procedure
  begin
    TRespostaHTTP.Create(99, '', nil, '').Free;
  end;
  Assert.WillRaise(LAcao, EValidacaoHTTP);
end;

procedure TTestesHTTP.Sanitizador_DeveOcultarCabecalhosSensiveis;
var
  LOriginais: TArray<TCabecalhoHTTP>;
  LSanitizados: TArray<TCabecalhoHTTP>;
begin
  SetLength(LOriginais, 2);
  LOriginais[0] := TCabecalhoHTTP.Criar('Authorization', 'Bearer segredo');
  LOriginais[1] := TCabecalhoHTTP.Criar('Content-Type', 'application/json');
  LSanitizados := TSanitizadorHTTP.SanitizarCabecalhos(LOriginais);
  Assert.AreEqual(CValorSensivelRemovido, LSanitizados[0].Valor);
  Assert.AreEqual('application/json', LSanitizados[1].Valor);
  Assert.AreEqual('Bearer segredo', LOriginais[0].Valor);
end;

procedure TTestesHTTP.Sanitizador_DeveRemoverFragmentoDaURL;
var
  LResultado: string;
begin
  LResultado := TSanitizadorHTTP.SanitizarURL(
    'https://exemplo.test/chat#token-no-fragmento');
  Assert.IsFalse(LResultado.Contains('token-no-fragmento'));
  Assert.AreEqual('https://exemplo.test/chat', LResultado);
end;

procedure TTestesHTTP.Sanitizador_DeveRemoverConsultaCompleta;
var
  LResultado: string;
begin
  LResultado := TSanitizadorHTTP.SanitizarURL(
    'https://usuario:senha@exemplo.test/chat?api_key=segredo&modelo=teste');
  Assert.IsFalse(LResultado.Contains('senha'));
  Assert.IsFalse(LResultado.Contains('segredo'));
  Assert.IsTrue(LResultado.Contains(CValorSensivelRemovido));
  Assert.IsFalse(LResultado.Contains('modelo=teste'));
  Assert.AreEqual('https://' + CValorSensivelRemovido +
    '@exemplo.test/chat', LResultado);
end;

procedure TTestesHTTP.Sanitizador_DeveRemoverConsultaCodificada;
var
  LResultado: string;
begin
  LResultado := TSanitizadorHTTP.SanitizarURL(
    'https://exemplo.test/chat?api%5Fkey=segredo&modelo=teste');
  Assert.AreEqual('https://exemplo.test/chat', LResultado);
  Assert.IsFalse(LResultado.Contains('segredo'));
end;

procedure TTestesHTTP.Timeout_DeveEspecializarFalhaTransporte;
var
  LExcecao: Exception;
begin
  LExcecao := ETimeoutHTTP.Create('tempo excedido');
  try
    Assert.IsTrue(LExcecao is ETransporteHTTP);
  finally
    LExcecao.Free;
  end;
end;

procedure TTestesHTTP.TransporteNativo_DeveDesabilitarRedirecionamentos;
var
  LTransporte: TTransporteHTTPClientExposto;
  LCliente: THTTPClient;
begin
  LTransporte := TTransporteHTTPClientExposto.Create;
  try
    LCliente := LTransporte.CriarClienteParaTeste;
    try
      Assert.IsFalse(LCliente.HandleRedirects);
      Assert.IsTrue(THTTPSecureProtocol.TLS12 in LCliente.SecureProtocols);
      Assert.IsTrue(THTTPSecureProtocol.TLS13 in LCliente.SecureProtocols);
    finally
      LCliente.Free;
    end;
  finally
    LTransporte.Free;
  end;
end;

procedure TTestesHTTP.TransporteFalso_DeveAceitarChamadasConcorrentes;
var
  LObjeto: TTransporteHTTPFalso;
  LTransporte: ITransporteHTTP;
  LRequisicao: IRequisicaoHTTP;
  LThreads: array of TThread;
  I: Integer;
begin
  LObjeto := TTransporteHTTPFalso.Create;
  LTransporte := LObjeto;
  LObjeto.ProgramarResposta(TRespostaHTTP.Create(200, 'OK', nil, '{}'));
  LRequisicao := CriarRequisicaoHTTP;
  SetLength(LThreads, CQuantidadeThreadsConcorrenciaHTTP);
  for I := Low(LThreads) to High(LThreads) do
  begin
    LThreads[I] := TThread.CreateAnonymousThread(
      procedure
      begin
        LTransporte.Enviar(LRequisicao);
      end);
    LThreads[I].FreeOnTerminate := False;
    LThreads[I].Start;
  end;
  for I := Low(LThreads) to High(LThreads) do
  begin
    LThreads[I].WaitFor;
    LThreads[I].Free;
  end;
  Assert.AreEqual(CQuantidadeThreadsConcorrenciaHTTP,
    LObjeto.QuantidadeChamadas);
end;

procedure TTestesHTTP.TransporteFalso_DeveRetornarRespostaProgramada;
var
  LObjeto: TTransporteHTTPFalso;
  LTransporte: ITransporteHTTP;
  LRequisicao: IRequisicaoHTTP;
  LResposta: IRespostaHTTP;
begin
  LObjeto := TTransporteHTTPFalso.Create;
  LTransporte := LObjeto;
  LObjeto.ProgramarResposta(TRespostaHTTP.Create(201, 'Created', nil, '{}'));
  LRequisicao := CriarRequisicaoHTTP;
  LResposta := LTransporte.Enviar(LRequisicao);
  Assert.AreEqual(201, LResposta.Status);
  Assert.AreEqual(1, LObjeto.QuantidadeChamadas);
  Assert.AreEqual(LRequisicao.URL, LObjeto.UltimaRequisicao.URL);
end;

procedure TTestesHTTP.TransporteFalso_DeveSimularErro;
var
  LObjeto: TTransporteHTTPFalso;
  LTransporte: ITransporteHTTP;
  LAcao: TTestLocalMethod;
begin
  LObjeto := TTransporteHTTPFalso.Create;
  LTransporte := LObjeto;
  LObjeto.ProgramarErro('falha programada');
  LAcao := procedure
  begin
    LTransporte.Enviar(CriarRequisicaoHTTP);
  end;
  Assert.WillRaise(LAcao, ETransporteHTTP);
end;

procedure TTestesHTTP.TransporteNativo_DeveRespeitarCancelamentoPreExecutado;
var
  LTransporte: ITransporteHTTP;
  LToken: ITokenCancelamentoIA;
  LAcao: TTestLocalMethod;
begin
  LTransporte := TTransporteHTTPClient.Create;
  LToken := TTokenCancelamentoIA.Create;
  LToken.Cancelar;
  LAcao := procedure
  begin
    LTransporte.Enviar(CriarRequisicaoHTTP, LToken);
  end;
  Assert.WillRaise(LAcao, EOperacaoCanceladaIA);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesHTTP);

end.
