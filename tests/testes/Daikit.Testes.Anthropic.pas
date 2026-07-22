unit Daikit.Testes.Anthropic;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesAnthropic = class
  public
    [Test] procedure Adaptador_DeveCriarRequisicaoAutenticadaEVersionada;
    [Test] procedure Mapeador_DeveSepararMensagemSistema;
    [Test] procedure Mapeador_DeveOmitirSistemaAusente;
    [Test] procedure Mapeador_DeveRejeitarSomenteMensagemSistema;
    [Test] procedure Mapeador_DeveRejeitarMensagemFerramenta;
    [Test] procedure Adaptador_DeveUsarModeloPadrao;
    [Test] procedure Adaptador_DeveMapearRespostaEUso;
    [Test] procedure Adaptador_DevePreservarMultiplosTextos;
    [Test] procedure Adaptador_DeveMapearErroSemExporMensagem;
    [Test] procedure Adaptador_DeveFalharSemChaveAntesDoTransporte;
    [Test] procedure Adaptador_DeveRespeitarCancelamento;
    [Test] procedure Adaptador_DeveInformarCapacidadesImplementadas;
    [Test] procedure Configuracao_DeveExigirHTTPS;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  Daikit.Dominio.Interfaces,
  Daikit.Dominio.Mensagem,
  Daikit.Dominio.RequisicaoResposta,
  Daikit.Dominio.Excecoes,
  Daikit.Aplicacao.Interfaces,
  Daikit.Aplicacao.TokenCancelamento,
  Daikit.Adaptadores.ChaveAPI,
  Daikit.Infraestrutura.HTTP.Interfaces,
  Daikit.Infraestrutura.HTTP.Modelos,
  Daikit.Adaptadores.Anthropic.Constantes,
  Daikit.Adaptadores.Anthropic.Contratos,
  Daikit.Adaptadores.Anthropic.Excecoes,
  Daikit.Adaptadores.Anthropic.Interfaces,
  Daikit.Adaptadores.Anthropic.Configuracao,
  Daikit.Adaptadores.Anthropic.Mapeador,
  Daikit.Adaptadores.Anthropic.Adaptador,
  Daikit.Testes.TransporteHTTPFalso,
  Daikit.Testes.Fixtures.Anthropic;

function CriarRequisicao(const AModelo: string = 'modelo-explicito';
  APapel: TPapelMensagemIA = TPapelMensagemIA.Usuario): IRequisicaoChatIA;
var
  LMensagens: TArray<IMensagemIA>;
begin
  SetLength(LMensagens, 1);
  LMensagens[0] := TMensagemIA.CriarTexto(APapel, 'mensagem de teste');
  Result := TRequisicaoChatIA.Create(AModelo, LMensagens);
end;

function CriarAdaptador(out ATransporte: TTransporteHTTPFalso;
  const AChave: string = 'chave-anthropic-falsa'): IAdaptadorIA;
var
  LTransporte: ITransporteHTTP;
begin
  ATransporte := TTransporteHTTPFalso.Create;
  LTransporte := ATransporte;
  Result := TAdaptadorAnthropic.Create(LTransporte,
    TFonteChaveAPIMemoria.Create(AChave),
    TConfiguracaoAnthropic.Create, TMapeadorAnthropic.Create);
end;

function RespostaHTTP(AStatus: Integer; const ACorpo: string;
  const AId: string = ''): IRespostaHTTP;
var
  LCabecalhos: TArray<TCabecalhoHTTP>;
begin
  if AId <> '' then
  begin
    SetLength(LCabecalhos, 1);
    LCabecalhos[0] := TCabecalhoHTTP.Criar(
      CCabecalhoIdRequisicaoAnthropic, AId);
  end;
  Result := TRespostaHTTP.Create(AStatus, '', LCabecalhos, ACorpo);
end;

function ObterCabecalho(const ARequisicao: IRequisicaoHTTP;
  const ANome: string): string;
var
  LCabecalho: TCabecalhoHTTP;
begin
  Result := '';
  for LCabecalho in ARequisicao.Cabecalhos do
    if SameText(LCabecalho.Nome, ANome) then
      Exit(LCabecalho.Valor);
end;

procedure TTestesAnthropic.Configuracao_DeveExigirHTTPS;
begin
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TConfiguracaoAnthropic.Create('http://api.exemplo.test').Free;
    end), EConfiguracaoAnthropic);
end;

procedure TTestesAnthropic.Mapeador_DeveOmitirSistemaAusente;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(RespostaHTTP(200, CRespostaAnthropicSucesso));
  LAdaptador.Concluir(CriarRequisicao);
  Assert.IsFalse(LTransporte.UltimaRequisicao.Corpo.Contains('"system"'));
end;

procedure TTestesAnthropic.Mapeador_DeveRejeitarMensagemFerramenta;
var
  LMapeador: IMapeadorAnthropic;
begin
  LMapeador := TMapeadorAnthropic.Create;
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      LMapeador.CriarContratoRequisicao(
        CriarRequisicao('modelo', TPapelMensagemIA.Ferramenta), 'padrao',
        100).Free;
    end), EContratoAnthropic);
end;

procedure TTestesAnthropic.Mapeador_DeveRejeitarSomenteMensagemSistema;
var
  LMapeador: IMapeadorAnthropic;
begin
  LMapeador := TMapeadorAnthropic.Create;
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      LMapeador.CriarContratoRequisicao(
        CriarRequisicao('modelo', TPapelMensagemIA.Sistema), 'padrao',
        100).Free;
    end), EContratoAnthropic);
end;

procedure TTestesAnthropic.Mapeador_DeveSepararMensagemSistema;
var
  LMensagens: TArray<IMensagemIA>;
  LRequisicao: IRequisicaoChatIA;
  LContrato: TRequisicaoMensagensAnthropic;
  LMapeador: IMapeadorAnthropic;
begin
  SetLength(LMensagens, 2);
  LMensagens[0] := TMensagemIA.CriarTexto(TPapelMensagemIA.Sistema,
    'instrucao');
  LMensagens[1] := TMensagemIA.CriarTexto(TPapelMensagemIA.Usuario,
    'pergunta');
  LRequisicao := TRequisicaoChatIA.Create('modelo', LMensagens);
  LMapeador := TMapeadorAnthropic.Create;
  LContrato := LMapeador.CriarContratoRequisicao(LRequisicao, 'padrao', 100);
  try
    Assert.AreEqual('instrucao', LContrato.Sistema);
    Assert.AreEqual(1, Integer(Length(LContrato.Mensagens)));
    Assert.AreEqual(CPapelUsuarioAnthropic, LContrato.Mensagens[0].Papel);
  finally
    LContrato.Free;
  end;
end;

procedure TTestesAnthropic.Adaptador_DeveCriarRequisicaoAutenticadaEVersionada;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LJSON: TJSONObject;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(RespostaHTTP(200, CRespostaAnthropicSucesso));
  LAdaptador.Concluir(CriarRequisicao);
  Assert.AreEqual(CEndpointMensagensAnthropic,
    LTransporte.UltimaRequisicao.URL);
  Assert.AreEqual('chave-anthropic-falsa', ObterCabecalho(
    LTransporte.UltimaRequisicao, CCabecalhoChaveAnthropic));
  Assert.AreEqual(CVersaoAPIAnthropic, ObterCabecalho(
    LTransporte.UltimaRequisicao, CCabecalhoVersaoAnthropic));
  LJSON := TJSONObject.ParseJSONValue(
    LTransporte.UltimaRequisicao.Corpo) as TJSONObject;
  try
    Assert.AreEqual('modelo-explicito', LJSON.GetValue<string>('model'));
    Assert.AreEqual(CMaximoTokensSaidaPadraoAnthropic,
      LJSON.GetValue<Integer>('max_tokens'));
    Assert.IsNotNull(LJSON.GetValue('messages'));
  finally
    LJSON.Free;
  end;
end;

procedure TTestesAnthropic.Adaptador_DeveFalharSemChaveAntesDoTransporte;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporte, '');
  Assert.WillRaise(
    TTestLocalMethod(procedure begin LAdaptador.Concluir(CriarRequisicao); end),
    EConfiguracaoAnthropic);
  Assert.AreEqual(0, LTransporte.QuantidadeChamadas);
end;

procedure TTestesAnthropic.Adaptador_DeveInformarCapacidadesImplementadas;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  Assert.IsTrue(LAdaptador.Capacidades.SuportaTextoSincrono);
  Assert.IsFalse(LAdaptador.Capacidades.SuportaFluxoContinuo);
  Assert.IsFalse(LAdaptador.Capacidades.SuportaFerramentas);
  Assert.IsFalse(LAdaptador.Capacidades.SuportaImagemEntrada);
  Assert.IsFalse(LAdaptador.Capacidades.SuportaSaidaEstruturada);
end;

procedure TTestesAnthropic.Adaptador_DeveMapearErroSemExporMensagem;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LCapturou: Boolean;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(RespostaHTTP(400, CRespostaAnthropicErro));
  LCapturou := False;
  try
    LAdaptador.Concluir(CriarRequisicao);
  except
    on E: ERespostaAnthropic do
    begin
      LCapturou := True;
      Assert.AreEqual('invalid_request_error', E.TipoErro);
      Assert.AreEqual('req_corpo_123', E.IdRequisicao);
      Assert.IsFalse(E.Message.Contains('conteudo-sensivel-anthropic'));
    end;
  end;
  Assert.IsTrue(LCapturou);
end;

procedure TTestesAnthropic.Adaptador_DeveMapearRespostaEUso;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LResposta: IRespostaChatIA;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(RespostaHTTP(200, CRespostaAnthropicSucesso));
  LResposta := LAdaptador.Concluir(CriarRequisicao);
  Assert.AreEqual('msg_teste_123', LResposta.Id);
  Assert.AreEqual('Ola do Claude', LResposta.Mensagem.Texto);
  Assert.AreEqual(Int64(13), LResposta.Uso.UnidadesEntrada);
  Assert.AreEqual(Int64(8), LResposta.Uso.UnidadesSaida);
end;

procedure TTestesAnthropic.Adaptador_DevePreservarMultiplosTextos;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LResposta: IRespostaChatIA;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(
    RespostaHTTP(200, CRespostaAnthropicMultiplosTextos));
  LResposta := LAdaptador.Concluir(CriarRequisicao);
  Assert.AreEqual(2, Integer(Length(LResposta.Mensagem.Partes)));
  Assert.AreEqual('primeira segunda', LResposta.Mensagem.Texto);
end;

procedure TTestesAnthropic.Adaptador_DeveRespeitarCancelamento;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LToken: ITokenCancelamentoIA;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LToken := TTokenCancelamentoIA.Create;
  LToken.Cancelar;
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin LAdaptador.Concluir(CriarRequisicao, LToken); end),
    EOperacaoCanceladaIA);
  Assert.AreEqual(0, LTransporte.QuantidadeChamadas);
end;

procedure TTestesAnthropic.Adaptador_DeveUsarModeloPadrao;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(RespostaHTTP(200, CRespostaAnthropicSucesso));
  LAdaptador.Concluir(CriarRequisicao(''));
  Assert.IsTrue(LTransporte.UltimaRequisicao.Corpo.Contains(
    '"model":"' + CModeloAnthropicPadrao + '"'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesAnthropic);

end.
