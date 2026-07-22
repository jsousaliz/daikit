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
  Daikit.Adaptadores.ChaveAPI,
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
  LTransporte: ITransporteHTTP;
begin
  ATransporte := TTransporteHTTPFalso.Create;
  LTransporte := ATransporte;
  Result := TAdaptadorOpenAI.Create(LTransporte,
    TFonteChaveAPIMemoria.Create(AChave), TConfiguracaoOpenAI.Create,
    TMapeadorOpenAI.Create);
end;

function RespostaHTTP(AStatus: Integer; const ACorpo: string;
  const AIdRequisicao: string = ''): IRespostaHTTP;
var
  LCabecalhos: TArray<TCabecalhoHTTP>;
begin
  if AIdRequisicao <> '' then
  begin
    SetLength(LCabecalhos, 1);
    LCabecalhos[0] := TCabecalhoHTTP.Criar(
      CCabecalhoIdRequisicaoOpenAI, AIdRequisicao);
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

procedure TTestesOpenAI.Configuracao_DeveExigirEndpointHTTPS;
begin
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TConfiguracaoOpenAI.Create('http://api.exemplo.test').Free;
    end), EConfiguracaoOpenAI);
end;

procedure TTestesOpenAI.Mapeador_DeveRejeitarMensagemDeFerramenta;
var
  LMapeador: IMapeadorOpenAI;
begin
  LMapeador := TMapeadorOpenAI.Create;
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      LMapeador.CriarContratoRequisicao(
        CriarRequisicao('modelo', TPapelMensagemIA.Ferramenta),
        'padrao').Free;
    end), EContratoOpenAI);
end;

procedure TTestesOpenAI.Adaptador_DeveCriarRequisicaoResponsesAutenticada;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LJSON: TJSONObject;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(RespostaHTTP(200, CRespostaOpenAISucesso));
  LAdaptador.Concluir(CriarRequisicao);

  Assert.AreEqual(CEndpointRespostasOpenAI, LTransporte.UltimaRequisicao.URL);
  Assert.AreEqual(TMetodoHTTP.Post, LTransporte.UltimaRequisicao.Metodo);
  Assert.AreEqual('Bearer sk-chave-falsa-de-teste',
    ObterCabecalho(LTransporte.UltimaRequisicao, CCabecalhoAutorizacao));
  Assert.AreEqual(CTipoConteudoJSON,
    ObterCabecalho(LTransporte.UltimaRequisicao, CCabecalhoTipoConteudo));
  LJSON := TJSONObject.ParseJSONValue(
    LTransporte.UltimaRequisicao.Corpo) as TJSONObject;
  try
    Assert.IsNotNull(LJSON);
    Assert.AreEqual('modelo-explicito', LJSON.GetValue<string>('model'));
    Assert.IsFalse(LJSON.GetValue<Boolean>('store'));
    Assert.IsNotNull(LJSON.GetValue('input'));
    Assert.IsFalse(LTransporte.UltimaRequisicao.Corpo.Contains('papel'));
    Assert.IsFalse(LTransporte.UltimaRequisicao.Corpo.Contains('conteudo'));
  finally
    LJSON.Free;
  end;
end;

procedure TTestesOpenAI.Adaptador_DeveInformarCapacidadesImplementadas;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LCapacidades: ICapacidadesAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LCapacidades := LAdaptador.Capacidades;
  Assert.IsNotNull(LCapacidades);
  Assert.IsTrue(LCapacidades.SuportaTextoSincrono);
  Assert.IsFalse(LCapacidades.SuportaFluxoContinuo);
  Assert.IsFalse(LCapacidades.SuportaFerramentas);
  Assert.IsFalse(LCapacidades.SuportaImagemEntrada);
  Assert.IsFalse(LCapacidades.SuportaSaidaEstruturada);
  Assert.AreEqual(0, LTransporte.QuantidadeChamadas);
end;

procedure TTestesOpenAI.Adaptador_DeveUsarModeloPadraoQuandoModeloVazio;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LJSON: TJSONObject;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(RespostaHTTP(200, CRespostaOpenAISucesso));
  LAdaptador.Concluir(CriarRequisicao(''));
  LJSON := TJSONObject.ParseJSONValue(
    LTransporte.UltimaRequisicao.Corpo) as TJSONObject;
  try
    Assert.AreEqual(CModeloOpenAIRecomendado,
      LJSON.GetValue<string>('model'));
  finally
    LJSON.Free;
  end;
end;

procedure TTestesOpenAI.Adaptador_DeveMapearRespostaTextualEUso;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LResposta: IRespostaChatIA;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(RespostaHTTP(200, CRespostaOpenAISucesso));
  LResposta := LAdaptador.Concluir(CriarRequisicao);
  Assert.AreEqual('resp_teste_123', LResposta.Id);
  Assert.AreEqual('Ola do OpenAI', LResposta.Mensagem.Texto);
  Assert.AreEqual(TPapelMensagemIA.Assistente, LResposta.Mensagem.Papel);
  Assert.AreEqual(Int64(11), LResposta.Uso.UnidadesEntrada);
  Assert.AreEqual(Int64(7), LResposta.Uso.UnidadesSaida);
  Assert.AreEqual(Int64(18), LResposta.Uso.UnidadesTotal);
end;

procedure TTestesOpenAI.Adaptador_DevePreservarMultiplasPartesDeTexto;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LResposta: IRespostaChatIA;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(
    RespostaHTTP(200, CRespostaOpenAIMultiplosTextos));
  LResposta := LAdaptador.Concluir(CriarRequisicao);
  Assert.AreEqual(2, Integer(Length(LResposta.Mensagem.Partes)));
  Assert.AreEqual('primeira segunda', LResposta.Mensagem.Texto);
end;

procedure TTestesOpenAI.Adaptador_DeveMapearErroSemExporCorpo;
const
  CIdRequisicao = 'req_teste_456';
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LCapturou: Boolean;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(
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
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LMensagem: string;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(RespostaHTTP(200, CCorpoInvalido));
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
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporte, '');
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      LAdaptador.Concluir(CriarRequisicao);
    end), EConfiguracaoOpenAI);
  Assert.AreEqual(0, LTransporte.QuantidadeChamadas);
end;

procedure TTestesOpenAI.Adaptador_DeveRespeitarCancelamentoAntesDoTransporte;
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
    begin
      LAdaptador.Concluir(CriarRequisicao, LToken);
    end), EOperacaoCanceladaIA);
  Assert.AreEqual(0, LTransporte.QuantidadeChamadas);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesOpenAI);

end.
