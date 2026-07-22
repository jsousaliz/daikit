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
  Daikit.Adaptadores.Interfaces,
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
  LTransporteHTTPFalso: ITransporteHTTP;
  LFonteChaveAPI: IFonteChaveAPI;
  LConfiguracaoAnthropic: IConfiguracaoAnthropic;
  LMapeadorAnthropic: IMapeadorAnthropic;
begin
  ATransporte := TTransporteHTTPFalso.Create;
  LTransporteHTTPFalso := ATransporte;
  LFonteChaveAPI := TFonteChaveAPIMemoria.Create(AChave);
  LConfiguracaoAnthropic := TConfiguracaoAnthropic.Create;
  LMapeadorAnthropic := TMapeadorAnthropic.Create;
  Result := TAdaptadorAnthropic.Create(LTransporteHTTPFalso, LFonteChaveAPI,
    LConfiguracaoAnthropic, LMapeadorAnthropic);
end;

function RespostaHTTP(AStatus: Integer; const ACorpo: string;
  const AId: string = ''): IRespostaHTTP;
var
  LCabecalhosHTTP: TArray<TCabecalhoHTTP>;
begin
  if AId <> '' then
  begin
    SetLength(LCabecalhosHTTP, 1);
    LCabecalhosHTTP[0] := TCabecalhoHTTP.Criar(
      CCabecalhoIdRequisicaoAnthropic, AId);
  end;
  Result := TRespostaHTTP.Create(AStatus, '', LCabecalhosHTTP, ACorpo);
end;

function ObterCabecalho(const ARequisicao: IRequisicaoHTTP;
  const ANome: string): string;
var
  LCabecalhoHTTP: TCabecalhoHTTP;
begin
  Result := '';
  for LCabecalhoHTTP in ARequisicao.Cabecalhos do
    if SameText(LCabecalhoHTTP.Nome, ANome) then
      Exit(LCabecalhoHTTP.Valor);
end;

procedure TTestesAnthropic.Configuracao_DeveExigirHTTPS;
var
  LOpcoesConfiguracaoAnthropic: TOpcoesConfiguracaoAnthropic;
begin
  LOpcoesConfiguracaoAnthropic := TOpcoesConfiguracaoAnthropic.Padrao;
  LOpcoesConfiguracaoAnthropic.Comum.Endpoint :=
    'http://api.exemplo.test';
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TConfiguracaoAnthropic.Create(LOpcoesConfiguracaoAnthropic).Free;
    end), EConfiguracaoAnthropic);
end;

procedure TTestesAnthropic.Mapeador_DeveOmitirSistemaAusente;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(RespostaHTTP(200, CRespostaAnthropicSucesso));
  LAdaptador.Concluir(CriarRequisicao);
  Assert.IsFalse(LTransporteHTTPFalso.UltimaRequisicao.Corpo.Contains('"system"'));
end;

procedure TTestesAnthropic.Mapeador_DeveRejeitarMensagemFerramenta;
var
  LMapeadorAnthropic: IMapeadorAnthropic;
begin
  LMapeadorAnthropic := TMapeadorAnthropic.Create;
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      LMapeadorAnthropic.CriarContratoRequisicao(
        CriarRequisicao('modelo', TPapelMensagemIA.Ferramenta), 'padrao',
        100).Free;
    end), EContratoAnthropic);
end;

procedure TTestesAnthropic.Mapeador_DeveRejeitarSomenteMensagemSistema;
var
  LMapeadorAnthropic: IMapeadorAnthropic;
begin
  LMapeadorAnthropic := TMapeadorAnthropic.Create;
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      LMapeadorAnthropic.CriarContratoRequisicao(
        CriarRequisicao('modelo', TPapelMensagemIA.Sistema), 'padrao',
        100).Free;
    end), EContratoAnthropic);
end;

procedure TTestesAnthropic.Mapeador_DeveSepararMensagemSistema;
var
  LMensagens: TArray<IMensagemIA>;
  LRequisicaoChat: IRequisicaoChatIA;
  LContratoRequisicaoAnthropic: TRequisicaoMensagensAnthropic;
  LMapeadorAnthropic: IMapeadorAnthropic;
begin
  SetLength(LMensagens, 2);
  LMensagens[0] := TMensagemIA.CriarTexto(TPapelMensagemIA.Sistema,
    'instrucao');
  LMensagens[1] := TMensagemIA.CriarTexto(TPapelMensagemIA.Usuario,
    'pergunta');
  LRequisicaoChat := TRequisicaoChatIA.Create('modelo', LMensagens);
  LMapeadorAnthropic := TMapeadorAnthropic.Create;
  LContratoRequisicaoAnthropic := LMapeadorAnthropic.CriarContratoRequisicao(LRequisicaoChat, 'padrao', 100);
  try
    Assert.AreEqual('instrucao', LContratoRequisicaoAnthropic.Sistema);
    Assert.AreEqual(1, Integer(Length(LContratoRequisicaoAnthropic.Mensagens)));
    Assert.AreEqual(CPapelUsuarioAnthropic, LContratoRequisicaoAnthropic.Mensagens[0].Papel);
  finally
    LContratoRequisicaoAnthropic.Free;
  end;
end;

procedure TTestesAnthropic.Adaptador_DeveCriarRequisicaoAutenticadaEVersionada;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LObjetoJSON: TJSONObject;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(RespostaHTTP(200, CRespostaAnthropicSucesso));
  LAdaptador.Concluir(CriarRequisicao);
  Assert.AreEqual(CEndpointMensagensAnthropic,
    LTransporteHTTPFalso.UltimaRequisicao.URL);
  Assert.AreEqual('chave-anthropic-falsa', ObterCabecalho(
    LTransporteHTTPFalso.UltimaRequisicao, CCabecalhoChaveAnthropic));
  Assert.AreEqual(CVersaoAPIAnthropic, ObterCabecalho(
    LTransporteHTTPFalso.UltimaRequisicao, CCabecalhoVersaoAnthropic));
  LObjetoJSON := TJSONObject.ParseJSONValue(
    LTransporteHTTPFalso.UltimaRequisicao.Corpo) as TJSONObject;
  try
    Assert.AreEqual('modelo-explicito', LObjetoJSON.GetValue<string>('model'));
    Assert.AreEqual(CMaximoTokensSaidaPadraoAnthropic,
      LObjetoJSON.GetValue<Integer>('max_tokens'));
    Assert.IsNotNull(LObjetoJSON.GetValue('messages'));
  finally
    LObjetoJSON.Free;
  end;
end;

procedure TTestesAnthropic.Adaptador_DeveFalharSemChaveAntesDoTransporte;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso, '');
  Assert.WillRaise(
    TTestLocalMethod(procedure begin LAdaptador.Concluir(CriarRequisicao); end),
    EConfiguracaoAnthropic);
  Assert.AreEqual(0, LTransporteHTTPFalso.QuantidadeChamadas);
end;

procedure TTestesAnthropic.Adaptador_DeveInformarCapacidadesImplementadas;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  Assert.IsTrue(LAdaptador.Capacidades.SuportaTextoSincrono);
  Assert.IsFalse(LAdaptador.Capacidades.SuportaFluxoContinuo);
  Assert.IsFalse(LAdaptador.Capacidades.SuportaFerramentas);
  Assert.IsFalse(LAdaptador.Capacidades.SuportaImagemEntrada);
  Assert.IsFalse(LAdaptador.Capacidades.SuportaSaidaEstruturada);
end;

procedure TTestesAnthropic.Adaptador_DeveMapearErroSemExporMensagem;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LCapturou: Boolean;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(RespostaHTTP(400, CRespostaAnthropicErro));
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
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LRespostaChat: IRespostaChatIA;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(RespostaHTTP(200, CRespostaAnthropicSucesso));
  LRespostaChat := LAdaptador.Concluir(CriarRequisicao);
  Assert.AreEqual('msg_teste_123', LRespostaChat.Id);
  Assert.AreEqual('Ola do Claude', LRespostaChat.Mensagem.Texto);
  Assert.AreEqual(Int64(13), LRespostaChat.Uso.UnidadesEntrada);
  Assert.AreEqual(Int64(8), LRespostaChat.Uso.UnidadesSaida);
end;

procedure TTestesAnthropic.Adaptador_DevePreservarMultiplosTextos;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LRespostaChat: IRespostaChatIA;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(
    RespostaHTTP(200, CRespostaAnthropicMultiplosTextos));
  LRespostaChat := LAdaptador.Concluir(CriarRequisicao);
  Assert.AreEqual(2, Integer(Length(LRespostaChat.Mensagem.Partes)));
  Assert.AreEqual('primeira segunda', LRespostaChat.Mensagem.Texto);
end;

procedure TTestesAnthropic.Adaptador_DeveRespeitarCancelamento;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LTokenCancelamento: ITokenCancelamentoIA;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTokenCancelamento := TTokenCancelamentoIA.Create;
  LTokenCancelamento.Cancelar;
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin LAdaptador.Concluir(CriarRequisicao, LTokenCancelamento); end),
    EOperacaoCanceladaIA);
  Assert.AreEqual(0, LTransporteHTTPFalso.QuantidadeChamadas);
end;

procedure TTestesAnthropic.Adaptador_DeveUsarModeloPadrao;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(RespostaHTTP(200, CRespostaAnthropicSucesso));
  LAdaptador.Concluir(CriarRequisicao(''));
  Assert.IsTrue(LTransporteHTTPFalso.UltimaRequisicao.Corpo.Contains(
    '"model":"' + CModeloAnthropicPadrao + '"'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesAnthropic);

end.
