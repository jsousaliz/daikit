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
  LCabecalhosHTTP: TArray<TCabecalhoHTTP>;
begin
  SetLength(LCabecalhosHTTP, 1);
  LCabecalhosHTTP[0] := TCabecalhoHTTP.Criar('X-Request-Id', 'req-123');
  Assert.AreEqual('req-123',
    TCabecalhoHTTP.ObterValor(LCabecalhosHTTP, 'x-request-id'));
  Assert.AreEqual('',
    TCabecalhoHTTP.ObterValor(LCabecalhosHTTP, 'cabecalho-ausente'));
end;

function TTransporteHTTPClientExposto.CriarClienteParaTeste: THTTPClient;
begin
  Result := CriarCliente;
end;

function CriarRequisicaoHTTP: IRequisicaoHTTP;
var
  LCabecalhosHTTP: TArray<TCabecalhoHTTP>;
  LOpcoesRequisicaoHTTP: TOpcoesRequisicaoHTTP;
begin
  SetLength(LCabecalhosHTTP, 1);
  LCabecalhosHTTP[Low(LCabecalhosHTTP)] := TCabecalhoHTTP.Criar(
    'Content-Type', 'application/json');
  LOpcoesRequisicaoHTTP := TOpcoesRequisicaoHTTP.Padrao;
  LOpcoesRequisicaoHTTP.Metodo := TMetodoHTTP.Post;
  LOpcoesRequisicaoHTTP.URL := 'https://api.exemplo.test/v1/chat';
  LOpcoesRequisicaoHTTP.Cabecalhos := LCabecalhosHTTP;
  LOpcoesRequisicaoHTTP.Corpo := '{"texto":"ola"}';
  Result := TRequisicaoHTTP.Create(LOpcoesRequisicaoHTTP);
end;

procedure TTestesHTTP.FluxoLimitado_DeveAceitarConteudoDentroDoLimite;
var
  LFluxoRespostaLimitado: TFluxoRespostaLimitado;
  LConteudo: TBytes;
  LResultado: Integer;
begin
  LFluxoRespostaLimitado := TFluxoRespostaLimitado.Create(4);
  try
    LConteudo := TEncoding.UTF8.GetBytes('1234');
    LResultado := LFluxoRespostaLimitado.Write(LConteudo[Low(LConteudo)], Length(LConteudo));
    Assert.AreEqual(Integer(Length(LConteudo)), LResultado);
  finally
    LFluxoRespostaLimitado.Free;
  end;
end;

procedure TTestesHTTP.FluxoLimitado_DeveRecusarConteudoAcimaDoLimite;
var
  LFluxoRespostaLimitado: TFluxoRespostaLimitado;
  LConteudo: TBytes;
  LAcao: TTestLocalMethod;
begin
  LFluxoRespostaLimitado := TFluxoRespostaLimitado.Create(3);
  try
    LConteudo := TEncoding.UTF8.GetBytes('1234');
    LAcao := procedure
    begin
      LFluxoRespostaLimitado.Write(LConteudo[Low(LConteudo)], Length(LConteudo));
    end;
    Assert.WillRaise(LAcao, ELimiteRespostaHTTP);
  finally
    LFluxoRespostaLimitado.Free;
  end;
end;

procedure TTestesHTTP.Requisicao_DevePreservarDados;
var
  LRequisicaoHTTP: IRequisicaoHTTP;
begin
  LRequisicaoHTTP := CriarRequisicaoHTTP;
  Assert.AreEqual(Integer(TMetodoHTTP.Post), Integer(LRequisicaoHTTP.Metodo));
  Assert.AreEqual('https://api.exemplo.test/v1/chat', LRequisicaoHTTP.URL);
  Assert.AreEqual('{"texto":"ola"}', LRequisicaoHTTP.Corpo);
  Assert.AreEqual(CTimeoutConexaoPadraoMS, LRequisicaoHTTP.TimeoutConexaoMS);
  Assert.AreEqual(CTimeoutRespostaPadraoMS, LRequisicaoHTTP.TimeoutRespostaMS);
  Assert.AreEqual(Int64(CLimiteRespostaPadraoBytes),
    LRequisicaoHTTP.LimiteRespostaBytes);
end;

procedure TTestesHTTP.Requisicao_DeveProtegerCabecalhos;
var
  LRequisicaoHTTP: IRequisicaoHTTP;
  LCabecalhosHTTP: TArray<TCabecalhoHTTP>;
begin
  LRequisicaoHTTP := CriarRequisicaoHTTP;
  LCabecalhosHTTP := LRequisicaoHTTP.Cabecalhos;
  LCabecalhosHTTP[Low(LCabecalhosHTTP)].Valor := 'alterado';
  Assert.AreEqual('application/json',
    LRequisicaoHTTP.Cabecalhos[Low(LRequisicaoHTTP.Cabecalhos)].Valor);
end;

procedure TTestesHTTP.Requisicao_NaoDeveAceitarQuebraLinhaEmCabecalho;
var
  LCabecalhosHTTP: TArray<TCabecalhoHTTP>;
  LOpcoesRequisicaoHTTP: TOpcoesRequisicaoHTTP;
  LAcao: TTestLocalMethod;
begin
  SetLength(LCabecalhosHTTP, 1);
  LCabecalhosHTTP[Low(LCabecalhosHTTP)] := TCabecalhoHTTP.Criar(
    'Authorization', 'segredo' + #13#10 + 'Injetado: sim');
  LOpcoesRequisicaoHTTP := TOpcoesRequisicaoHTTP.Padrao;
  LOpcoesRequisicaoHTTP.URL := 'https://exemplo.test';
  LOpcoesRequisicaoHTTP.Cabecalhos := LCabecalhosHTTP;
  LAcao := procedure
  begin
    TRequisicaoHTTP.Create(LOpcoesRequisicaoHTTP).Free;
  end;
  Assert.WillRaise(LAcao, EValidacaoHTTP);
end;

procedure TTestesHTTP.Requisicao_NaoDeveAceitarEsquemaInvalido;
var
  LOpcoesRequisicaoHTTP: TOpcoesRequisicaoHTTP;
  LAcao: TTestLocalMethod;
begin
  LOpcoesRequisicaoHTTP := TOpcoesRequisicaoHTTP.Padrao;
  LOpcoesRequisicaoHTTP.URL := 'file://arquivo-local';
  LAcao := procedure
  begin
    TRequisicaoHTTP.Create(LOpcoesRequisicaoHTTP).Free;
  end;
  Assert.WillRaise(LAcao, EValidacaoHTTP);
end;

procedure TTestesHTTP.Requisicao_NaoDeveAceitarURLSemHost;
var
  LOpcoesRequisicaoHTTP: TOpcoesRequisicaoHTTP;
  LAcao: TTestLocalMethod;
begin
  LOpcoesRequisicaoHTTP := TOpcoesRequisicaoHTTP.Padrao;
  LOpcoesRequisicaoHTTP.URL := 'https://';
  LAcao := procedure
  begin
    TRequisicaoHTTP.Create(LOpcoesRequisicaoHTTP).Free;
  end;
  Assert.WillRaise(LAcao, EValidacaoHTTP);
end;

procedure TTestesHTTP.Requisicao_NaoDeveAceitarTimeoutInvalido;
var
  LOpcoesRequisicaoHTTP: TOpcoesRequisicaoHTTP;
  LAcao: TTestLocalMethod;
begin
  LOpcoesRequisicaoHTTP := TOpcoesRequisicaoHTTP.Padrao;
  LOpcoesRequisicaoHTTP.URL := 'https://exemplo.test';
  LOpcoesRequisicaoHTTP.TimeoutConexaoMS := 0;
  LAcao := procedure
  begin
    TRequisicaoHTTP.Create(LOpcoesRequisicaoHTTP).Free;
  end;
  Assert.WillRaise(LAcao, EValidacaoHTTP);
end;

procedure TTestesHTTP.Requisicao_NaoDeveAceitarURLVazia;
var
  LOpcoesRequisicaoHTTP: TOpcoesRequisicaoHTTP;
  LAcao: TTestLocalMethod;
begin
  LOpcoesRequisicaoHTTP := TOpcoesRequisicaoHTTP.Padrao;
  LOpcoesRequisicaoHTTP.URL := '';
  LAcao := procedure
  begin
    TRequisicaoHTTP.Create(LOpcoesRequisicaoHTTP).Free;
  end;
  Assert.WillRaise(LAcao, EValidacaoHTTP);
end;

procedure TTestesHTTP.Resposta_DeveIdentificarFalha;
var
  LRespostaHTTP: IRespostaHTTP;
begin
  LRespostaHTTP := TRespostaHTTP.Create(429, 'Too Many Requests', nil, '{}');
  Assert.IsFalse(LRespostaHTTP.FoiSucesso);
  Assert.AreEqual(429, LRespostaHTTP.Status);
end;

procedure TTestesHTTP.Resposta_DeveIdentificarSucesso;
var
  LRespostaHTTP: IRespostaHTTP;
begin
  LRespostaHTTP := TRespostaHTTP.Create(200, 'OK', nil, '{"ok":true}');
  Assert.IsTrue(LRespostaHTTP.FoiSucesso);
  Assert.AreEqual('{"ok":true}', LRespostaHTTP.Corpo);
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
  LTransporteHTTP: TTransporteHTTPClientExposto;
  LHTTPCliente: THTTPClient;
begin
  LTransporteHTTP := TTransporteHTTPClientExposto.Create;
  try
    LHTTPCliente := LTransporteHTTP.CriarClienteParaTeste;
    try
      Assert.IsFalse(LHTTPCliente.HandleRedirects);
      Assert.IsTrue(THTTPSecureProtocol.TLS12 in LHTTPCliente.SecureProtocols);
      Assert.IsTrue(THTTPSecureProtocol.TLS13 in LHTTPCliente.SecureProtocols);
    finally
      LHTTPCliente.Free;
    end;
  finally
    LTransporteHTTP.Free;
  end;
end;

procedure TTestesHTTP.TransporteFalso_DeveAceitarChamadasConcorrentes;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LTransporteHTTP: ITransporteHTTP;
  LRequisicaoHTTP: IRequisicaoHTTP;
  LThreads: array of TThread;
  I: Integer;
begin
  LTransporteHTTPFalso := TTransporteHTTPFalso.Create;
  LTransporteHTTP := LTransporteHTTPFalso;
  LTransporteHTTPFalso.ProgramarResposta(TRespostaHTTP.Create(200, 'OK', nil, '{}'));
  LRequisicaoHTTP := CriarRequisicaoHTTP;
  SetLength(LThreads, CQuantidadeThreadsConcorrenciaHTTP);
  for I := Low(LThreads) to High(LThreads) do
  begin
    LThreads[I] := TThread.CreateAnonymousThread(
      procedure
      begin
        LTransporteHTTP.Enviar(LRequisicaoHTTP);
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
    LTransporteHTTPFalso.QuantidadeChamadas);
end;

procedure TTestesHTTP.TransporteFalso_DeveRetornarRespostaProgramada;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LTransporteHTTP: ITransporteHTTP;
  LRequisicaoHTTP: IRequisicaoHTTP;
  LRespostaHTTP: IRespostaHTTP;
begin
  LTransporteHTTPFalso := TTransporteHTTPFalso.Create;
  LTransporteHTTP := LTransporteHTTPFalso;
  LTransporteHTTPFalso.ProgramarResposta(TRespostaHTTP.Create(201, 'Created', nil, '{}'));
  LRequisicaoHTTP := CriarRequisicaoHTTP;
  LRespostaHTTP := LTransporteHTTP.Enviar(LRequisicaoHTTP);
  Assert.AreEqual(201, LRespostaHTTP.Status);
  Assert.AreEqual(1, LTransporteHTTPFalso.QuantidadeChamadas);
  Assert.AreEqual(LRequisicaoHTTP.URL, LTransporteHTTPFalso.UltimaRequisicao.URL);
end;

procedure TTestesHTTP.TransporteFalso_DeveSimularErro;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LTransporteHTTP: ITransporteHTTP;
  LAcao: TTestLocalMethod;
begin
  LTransporteHTTPFalso := TTransporteHTTPFalso.Create;
  LTransporteHTTP := LTransporteHTTPFalso;
  LTransporteHTTPFalso.ProgramarErro('falha programada');
  LAcao := procedure
  begin
    LTransporteHTTP.Enviar(CriarRequisicaoHTTP);
  end;
  Assert.WillRaise(LAcao, ETransporteHTTP);
end;

procedure TTestesHTTP.TransporteNativo_DeveRespeitarCancelamentoPreExecutado;
var
  LTransporteHTTP: ITransporteHTTP;
  LTokenCancelamento: ITokenCancelamentoIA;
  LAcao: TTestLocalMethod;
begin
  LTransporteHTTP := TTransporteHTTPClient.Create;
  LTokenCancelamento := TTokenCancelamentoIA.Create;
  LTokenCancelamento.Cancelar;
  LAcao := procedure
  begin
    LTransporteHTTP.Enviar(CriarRequisicaoHTTP, LTokenCancelamento);
  end;
  Assert.WillRaise(LAcao, EOperacaoCanceladaIA);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesHTTP);

end.
