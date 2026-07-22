unit Daikit.Testes.OpenAI;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesOpenAI = class
  public
    [Test] procedure Adaptador_DeveCriarRequisicaoResponsesAutenticada;
    [Test] procedure Adaptador_DeveUsarModeloPadraoQuandoModeloVazio;
    [Test] procedure Adaptador_DeveMapearRespostaTextualEUso;
    [Test] procedure Adaptador_DevePreservarMultiplasPartesDeTexto;
    [Test] procedure Adaptador_DeveMapearErroSemExporCorpo;
    [Test] procedure Adaptador_DeveRejeitarJSONSucessoInvalidoSemExporCorpo;
    [Test] procedure Adaptador_DeveFalharSemChaveAntesDoTransporte;
    [Test] procedure Adaptador_DeveRespeitarCancelamentoAntesDoTransporte;
    [Test] procedure Mapeador_DeveRejeitarMensagemDeFerramenta;
    [Test] procedure Configuracao_DeveExigirEndpointHTTPS;
    [Test] procedure Adaptador_DeveInformarCapacidadesImplementadas;
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
  Daikit.Adaptadores.Configuracao,
  Daikit.Infraestrutura.HTTP.Interfaces,
  Daikit.Infraestrutura.HTTP.Modelos,
  Daikit.Adaptadores.OpenAI.Constantes,
  Daikit.Adaptadores.OpenAI.Excecoes,
  Daikit.Adaptadores.OpenAI.Interfaces,
  Daikit.Adaptadores.OpenAI.Configuracao,
  Daikit.Adaptadores.OpenAI.Mapeador,
  Daikit.Adaptadores.OpenAI.Adaptador,
  Daikit.Testes.TransporteHTTPFalso,
  Daikit.Testes.Fixtures.OpenAI;

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
  const AChave: string = 'sk-chave-falsa-de-teste'): IAdaptadorIA;
var
  LTransporteHTTPFalso: ITransporteHTTP;
  LFonteChaveAPI: IFonteChaveAPI;
  LConfiguracaoOpenAI: IConfiguracaoOpenAI;
  LMapeadorOpenAI: IMapeadorOpenAI;
begin
  ATransporte := TTransporteHTTPFalso.Create;
  LTransporteHTTPFalso := ATransporte;
  LFonteChaveAPI := TFonteChaveAPIMemoria.Create(AChave);
  LConfiguracaoOpenAI := TConfiguracaoOpenAI.Create;
  LMapeadorOpenAI := TMapeadorOpenAI.Create;
  Result := TAdaptadorOpenAI.Create(LTransporteHTTPFalso, LFonteChaveAPI,
    LConfiguracaoOpenAI, LMapeadorOpenAI);
end;

function RespostaHTTP(AStatus: Integer; const ACorpo: string;
  const AIdRequisicao: string = ''): IRespostaHTTP;
var
  LCabecalhosHTTP: TArray<TCabecalhoHTTP>;
begin
  if AIdRequisicao <> '' then
  begin
    SetLength(LCabecalhosHTTP, 1);
    LCabecalhosHTTP[0] := TCabecalhoHTTP.Criar(
      CCabecalhoIdRequisicaoOpenAI, AIdRequisicao);
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

procedure TTestesOpenAI.Configuracao_DeveExigirEndpointHTTPS;
var
  LOpcoesConfiguracaoOpenAI: TOpcoesConfiguracaoAdaptadorIA;
begin
  LOpcoesConfiguracaoOpenAI := TOpcoesConfiguracaoAdaptadorIA.Padrao(
    CEndpointRespostasOpenAI, CModeloOpenAIRecomendado);
  LOpcoesConfiguracaoOpenAI.Endpoint := 'http://api.exemplo.test';
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TConfiguracaoOpenAI.Create(LOpcoesConfiguracaoOpenAI).Free;
    end), EConfiguracaoOpenAI);
end;

procedure TTestesOpenAI.Mapeador_DeveRejeitarMensagemDeFerramenta;
var
  LMapeadorOpenAI: IMapeadorOpenAI;
begin
  LMapeadorOpenAI := TMapeadorOpenAI.Create;
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      LMapeadorOpenAI.CriarContratoRequisicao(
        CriarRequisicao('modelo', TPapelMensagemIA.Ferramenta),
        'padrao').Free;
    end), EContratoOpenAI);
end;

procedure TTestesOpenAI.Adaptador_DeveCriarRequisicaoResponsesAutenticada;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LObjetoJSON: TJSONObject;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(RespostaHTTP(200, CRespostaOpenAISucesso));
  LAdaptador.Concluir(CriarRequisicao);

  Assert.AreEqual(CEndpointRespostasOpenAI, LTransporteHTTPFalso.UltimaRequisicao.URL);
  Assert.AreEqual(TMetodoHTTP.Post, LTransporteHTTPFalso.UltimaRequisicao.Metodo);
  Assert.AreEqual('Bearer sk-chave-falsa-de-teste',
    ObterCabecalho(LTransporteHTTPFalso.UltimaRequisicao, CCabecalhoAutorizacao));
  Assert.AreEqual(CTipoConteudoJSON,
    ObterCabecalho(LTransporteHTTPFalso.UltimaRequisicao, CCabecalhoTipoConteudo));
  LObjetoJSON := TJSONObject.ParseJSONValue(
    LTransporteHTTPFalso.UltimaRequisicao.Corpo) as TJSONObject;
  try
    Assert.IsNotNull(LObjetoJSON);
    Assert.AreEqual('modelo-explicito', LObjetoJSON.GetValue<string>('model'));
    Assert.IsFalse(LObjetoJSON.GetValue<Boolean>('store'));
    Assert.IsNotNull(LObjetoJSON.GetValue('input'));
    Assert.IsFalse(LTransporteHTTPFalso.UltimaRequisicao.Corpo.Contains('papel'));
    Assert.IsFalse(LTransporteHTTPFalso.UltimaRequisicao.Corpo.Contains('conteudo'));
  finally
    LObjetoJSON.Free;
  end;
end;

procedure TTestesOpenAI.Adaptador_DeveInformarCapacidadesImplementadas;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LCapacidadesAdaptador: ICapacidadesAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LCapacidadesAdaptador := LAdaptador.Capacidades;
  Assert.IsNotNull(LCapacidadesAdaptador);
  Assert.IsTrue(LCapacidadesAdaptador.SuportaTextoSincrono);
  Assert.IsFalse(LCapacidadesAdaptador.SuportaFluxoContinuo);
  Assert.IsFalse(LCapacidadesAdaptador.SuportaFerramentas);
  Assert.IsFalse(LCapacidadesAdaptador.SuportaImagemEntrada);
  Assert.IsFalse(LCapacidadesAdaptador.SuportaSaidaEstruturada);
  Assert.AreEqual(0, LTransporteHTTPFalso.QuantidadeChamadas);
end;

procedure TTestesOpenAI.Adaptador_DeveUsarModeloPadraoQuandoModeloVazio;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LObjetoJSON: TJSONObject;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(RespostaHTTP(200, CRespostaOpenAISucesso));
  LAdaptador.Concluir(CriarRequisicao(''));
  LObjetoJSON := TJSONObject.ParseJSONValue(
    LTransporteHTTPFalso.UltimaRequisicao.Corpo) as TJSONObject;
  try
    Assert.AreEqual(CModeloOpenAIRecomendado,
      LObjetoJSON.GetValue<string>('model'));
  finally
    LObjetoJSON.Free;
  end;
end;

procedure TTestesOpenAI.Adaptador_DeveMapearRespostaTextualEUso;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LRespostaChat: IRespostaChatIA;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(RespostaHTTP(200, CRespostaOpenAISucesso));
  LRespostaChat := LAdaptador.Concluir(CriarRequisicao);
  Assert.AreEqual('resp_teste_123', LRespostaChat.Id);
  Assert.AreEqual('Ola do OpenAI', LRespostaChat.Mensagem.Texto);
  Assert.AreEqual(TPapelMensagemIA.Assistente, LRespostaChat.Mensagem.Papel);
  Assert.AreEqual(Int64(11), LRespostaChat.Uso.UnidadesEntrada);
  Assert.AreEqual(Int64(7), LRespostaChat.Uso.UnidadesSaida);
  Assert.AreEqual(Int64(18), LRespostaChat.Uso.UnidadesTotal);
end;

procedure TTestesOpenAI.Adaptador_DevePreservarMultiplasPartesDeTexto;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LRespostaChat: IRespostaChatIA;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(
    RespostaHTTP(200, CRespostaOpenAIMultiplosTextos));
  LRespostaChat := LAdaptador.Concluir(CriarRequisicao);
  Assert.AreEqual(2, Integer(Length(LRespostaChat.Mensagem.Partes)));
  Assert.AreEqual('primeira segunda', LRespostaChat.Mensagem.Texto);
end;

procedure TTestesOpenAI.Adaptador_DeveMapearErroSemExporCorpo;
const
  CIdRequisicao = 'req_teste_456';
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LCapturou: Boolean;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(
    RespostaHTTP(400, CRespostaOpenAIErro, CIdRequisicao));
  LCapturou := False;
  try
    LAdaptador.Concluir(CriarRequisicao);
  except
    on E: ERespostaOpenAI do
    begin
      LCapturou := True;
      Assert.AreEqual(400, E.StatusHTTP);
      Assert.AreEqual('invalid_request_error', E.TipoErro);
      Assert.AreEqual('model_not_found', E.CodigoErro);
      Assert.AreEqual(CIdRequisicao, E.IdRequisicao);
      Assert.IsFalse(E.Message.Contains('conteudo-sensivel-da-fixture'));
    end;
  end;
  Assert.IsTrue(LCapturou);
end;

procedure TTestesOpenAI.Adaptador_DeveRejeitarJSONSucessoInvalidoSemExporCorpo;
const
  CCorpoInvalido = '{"segredo":"nao-expor-este-valor"';
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LMensagem: string;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(RespostaHTTP(200, CCorpoInvalido));
  LMensagem := '';
  try
    LAdaptador.Concluir(CriarRequisicao);
  except
    on E: EContratoOpenAI do
      LMensagem := E.Message;
  end;
  Assert.IsNotEmpty(LMensagem);
  Assert.IsFalse(LMensagem.Contains('nao-expor-este-valor'));
end;

procedure TTestesOpenAI.Adaptador_DeveFalharSemChaveAntesDoTransporte;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso, '');
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      LAdaptador.Concluir(CriarRequisicao);
    end), EConfiguracaoOpenAI);
  Assert.AreEqual(0, LTransporteHTTPFalso.QuantidadeChamadas);
end;

procedure TTestesOpenAI.Adaptador_DeveRespeitarCancelamentoAntesDoTransporte;
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
    begin
      LAdaptador.Concluir(CriarRequisicao, LTokenCancelamento);
    end), EOperacaoCanceladaIA);
  Assert.AreEqual(0, LTransporteHTTPFalso.QuantidadeChamadas);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesOpenAI);

end.
