unit Daikit.Testes.Gemini;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesGemini = class
  public
    [Test] procedure Adaptador_DeveCriarRequisicaoAutenticadaStateless;
    [Test] procedure Mapeador_DeveSepararMensagemSistema;
    [Test] procedure Mapeador_DeveOmitirSistemaAusente;
    [Test] procedure Mapeador_DeveRejeitarSomenteMensagemSistema;
    [Test] procedure Mapeador_DeveRejeitarMensagemFerramenta;
    [Test] procedure Adaptador_DeveUsarModeloPadrao;
    [Test] procedure Adaptador_DeveMapearRespostaEUso;
    [Test] procedure Adaptador_DevePreservarMultiplosTextos;
    [Test] procedure Adaptador_DeveMapearErroSemExporMensagem;
    [Test] procedure Adaptador_DeveMapearErroEmListaSemExporMensagem;
    [Test] procedure Adaptador_DeveFalharSemChaveAntesDoTransporte;
    [Test] procedure Adaptador_DeveRespeitarCancelamento;
    [Test] procedure Adaptador_DeveInformarCapacidadesImplementadas;
    [Test] procedure Configuracao_DeveExigirHTTPS;
    [Test] procedure Adaptador_DevePreservarPensamentoNoSegundoTurno;
    [Test] procedure Mapeador_DeveFalharQuandoContextoLocalNaoExiste;
    [Test] procedure Adaptador_DeveRejeitarStepDesconhecido;
    [Test] procedure Armazenamento_DeveGuardarRemoverELimpar;
    [Test] procedure Configuracao_DeveRejeitarModoRemotoAindaNaoImplementado;
    [Test] procedure Adaptador_DeveCriarCorrelacaoLocalQuandoRespostaNaoTemId;
    [Test] procedure Adaptador_DeveRejeitarPensamentoSemAssinatura;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,
  Daikit.Dominio.Interfaces,
  Daikit.Dominio.Mensagem,
  Daikit.Dominio.RequisicaoResposta,
  Daikit.Dominio.Excecoes,
  Daikit.Aplicacao.Interfaces,
  Daikit.Aplicacao.TokenCancelamento,
  Daikit.Adaptadores.ChaveAPI,
  Daikit.Infraestrutura.HTTP.Interfaces,
  Daikit.Infraestrutura.HTTP.Constantes,
  Daikit.Infraestrutura.HTTP.Modelos,
  Daikit.Adaptadores.Gemini.Constantes,
  Daikit.Adaptadores.Gemini.Contratos,
  Daikit.Adaptadores.Gemini.Excecoes,
  Daikit.Adaptadores.Gemini.Interfaces,
  Daikit.Adaptadores.Gemini.Configuracao,
  Daikit.Adaptadores.Gemini.Armazenamento,
  Daikit.Adaptadores.Gemini.Mapeador,
  Daikit.Adaptadores.Gemini.Adaptador,
  Daikit.Testes.TransporteHTTPFalso,
  Daikit.Testes.Fixtures.Gemini;

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
  const AChave: string = 'chave-gemini-falsa'): IAdaptadorIA;
var
  LTransporte: ITransporteHTTP;
  LArmazenamento: IArmazenamentoContextoGemini;
begin
  ATransporte := TTransporteHTTPFalso.Create;
  LTransporte := ATransporte;
  LArmazenamento := TArmazenamentoContextoGemini.Create;
  Result := TAdaptadorGemini.Create(LTransporte,
    TFonteChaveAPIMemoria.Create(AChave),
    TConfiguracaoGemini.Create, TMapeadorGemini.Create(LArmazenamento));
end;

function CriarMapeador: IMapeadorGemini;
begin
  Result := TMapeadorGemini.Create(TArmazenamentoContextoGemini.Create);
end;

function RespostaHTTP(AStatus: Integer; const ACorpo: string;
  const AId: string = ''): IRespostaHTTP;
var
  LCabecalhos: TArray<TCabecalhoHTTP>;
begin
  if AId <> '' then
  begin
    SetLength(LCabecalhos, 1);
    LCabecalhos[0] := TCabecalhoHTTP.Criar(CCabecalhoIdRequisicaoGemini, AId);
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

procedure TTestesGemini.Configuracao_DeveExigirHTTPS;
begin
  Assert.WillRaise(TTestLocalMethod(procedure
    begin TConfiguracaoGemini.Create('http://api.exemplo.test').Free; end),
    EConfiguracaoGemini);
end;

procedure TTestesGemini.Mapeador_DeveOmitirSistemaAusente;
var LTransporte: TTransporteHTTPFalso; LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(RespostaHTTP(200, CRespostaGeminiSucesso));
  LAdaptador.Concluir(CriarRequisicao);
  Assert.IsFalse(LTransporte.UltimaRequisicao.Corpo.Contains(
    '"system_instruction"'));
end;

procedure TTestesGemini.Mapeador_DeveRejeitarMensagemFerramenta;
var LMapeador: IMapeadorGemini;
begin
  LMapeador := CriarMapeador;
  Assert.WillRaise(TTestLocalMethod(procedure begin
    LMapeador.CriarContratoRequisicao(CriarRequisicao('modelo',
      TPapelMensagemIA.Ferramenta), 'padrao', 100).Free; end), EContratoGemini);
end;

procedure TTestesGemini.Mapeador_DeveRejeitarSomenteMensagemSistema;
var LMapeador: IMapeadorGemini;
begin
  LMapeador := CriarMapeador;
  Assert.WillRaise(TTestLocalMethod(procedure begin
    LMapeador.CriarContratoRequisicao(CriarRequisicao('modelo',
      TPapelMensagemIA.Sistema), 'padrao', 100).Free; end), EContratoGemini);
end;

procedure TTestesGemini.Mapeador_DeveSepararMensagemSistema;
var
  LMensagens: TArray<IMensagemIA>;
  LRequisicao: IRequisicaoChatIA;
  LContrato: TRequisicaoInteracaoGemini;
  LMapeador: IMapeadorGemini;
begin
  SetLength(LMensagens, 2);
  LMensagens[0] := TMensagemIA.CriarTexto(TPapelMensagemIA.Sistema, 'instrucao');
  LMensagens[1] := TMensagemIA.CriarTexto(TPapelMensagemIA.Usuario, 'pergunta');
  LRequisicao := TRequisicaoChatIA.Create('modelo', LMensagens);
  LMapeador := CriarMapeador;
  LContrato := LMapeador.CriarContratoRequisicao(LRequisicao, 'padrao', 100);
  try
    Assert.AreEqual('instrucao', LContrato.InstrucaoSistema);
    Assert.AreEqual(1, Integer(Length(LContrato.Entrada)));
    Assert.AreEqual(CTipoEntradaUsuarioGemini, LContrato.Entrada[0].Tipo);
  finally
    LContrato.Free;
  end;
end;

procedure TTestesGemini.Adaptador_DeveCriarRequisicaoAutenticadaStateless;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LJSON: TJSONObject;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(RespostaHTTP(200, CRespostaGeminiSucesso));
  LAdaptador.Concluir(CriarRequisicao);
  Assert.AreEqual(CEndpointInteracoesGemini, LTransporte.UltimaRequisicao.URL);
  Assert.AreEqual('chave-gemini-falsa', ObterCabecalho(
    LTransporte.UltimaRequisicao, CCabecalhoChaveGemini));
  LJSON := TJSONObject.ParseJSONValue(LTransporte.UltimaRequisicao.Corpo)
    as TJSONObject;
  try
    Assert.AreEqual('modelo-explicito', LJSON.GetValue<string>('model'));
    Assert.IsFalse(LJSON.GetValue<Boolean>('store'));
    Assert.IsNotNull(LJSON.GetValue('input'));
    Assert.AreEqual(CMaximoTokensSaidaPadraoGemini,
      LJSON.GetValue<Integer>('generation_config.max_output_tokens'));
  finally
    LJSON.Free;
  end;
end;

procedure TTestesGemini.Adaptador_DeveFalharSemChaveAntesDoTransporte;
var LTransporte: TTransporteHTTPFalso; LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporte, '');
  Assert.WillRaise(TTestLocalMethod(procedure begin
    LAdaptador.Concluir(CriarRequisicao); end), EConfiguracaoGemini);
  Assert.AreEqual(0, LTransporte.QuantidadeChamadas);
end;

procedure TTestesGemini.Adaptador_DeveInformarCapacidadesImplementadas;
var LTransporte: TTransporteHTTPFalso; LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  Assert.IsTrue(LAdaptador.Capacidades.SuportaTextoSincrono);
  Assert.IsFalse(LAdaptador.Capacidades.SuportaFluxoContinuo);
  Assert.IsFalse(LAdaptador.Capacidades.SuportaFerramentas);
  Assert.IsFalse(LAdaptador.Capacidades.SuportaImagemEntrada);
  Assert.IsFalse(LAdaptador.Capacidades.SuportaSaidaEstruturada);
end;

procedure TTestesGemini.Adaptador_DeveMapearErroEmListaSemExporMensagem;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LCapturou: Boolean;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(RespostaHTTP(400,
    CRespostaGeminiErroEmLista, 'req_gemini_lista_123'));
  LCapturou := False;
  try
    LAdaptador.Concluir(CriarRequisicao);
  except
    on E: ERespostaGemini do
    begin
      LCapturou := True;
      Assert.AreEqual(400, E.CodigoErro);
      Assert.AreEqual('INVALID_ARGUMENT', E.TipoErro);
      Assert.AreEqual('req_gemini_lista_123', E.IdRequisicao);
      Assert.IsFalse(E.Message.Contains('conteudo-sensivel-gemini'));
    end;
  end;
  Assert.IsTrue(LCapturou);
end;
procedure TTestesGemini.Adaptador_DeveMapearErroSemExporMensagem;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LCapturou: Boolean;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(RespostaHTTP(400, CRespostaGeminiErro,
    'req_gemini_123'));
  LCapturou := False;
  try
    LAdaptador.Concluir(CriarRequisicao);
  except
    on E: ERespostaGemini do
    begin
      LCapturou := True;
      Assert.AreEqual(400, E.CodigoErro);
      Assert.AreEqual('INVALID_ARGUMENT', E.TipoErro);
      Assert.AreEqual('req_gemini_123', E.IdRequisicao);
      Assert.IsFalse(E.Message.Contains('conteudo-sensivel-gemini'));
    end;
  end;
  Assert.IsTrue(LCapturou);
end;

procedure TTestesGemini.Adaptador_DeveMapearRespostaEUso;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LResposta: IRespostaChatIA;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(RespostaHTTP(200, CRespostaGeminiSucesso));
  LResposta := LAdaptador.Concluir(CriarRequisicao);
  Assert.AreEqual('int_teste_123', LResposta.Id);
  Assert.AreEqual('Ola do Gemini', LResposta.Mensagem.Texto);
  Assert.AreEqual(Int64(12), LResposta.Uso.UnidadesEntrada);
  Assert.AreEqual(Int64(8), LResposta.Uso.UnidadesSaida);
end;

procedure TTestesGemini.Adaptador_DevePreservarMultiplosTextos;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LResposta: IRespostaChatIA;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(
    RespostaHTTP(200, CRespostaGeminiMultiplosTextos));
  LResposta := LAdaptador.Concluir(CriarRequisicao);
  Assert.AreEqual(2, Integer(Length(LResposta.Mensagem.Partes)));
  Assert.AreEqual('primeira segunda', LResposta.Mensagem.Texto);
end;

procedure TTestesGemini.Adaptador_DeveRespeitarCancelamento;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LToken: ITokenCancelamentoIA;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LToken := TTokenCancelamentoIA.Create;
  LToken.Cancelar;
  Assert.WillRaise(TTestLocalMethod(procedure begin
    LAdaptador.Concluir(CriarRequisicao, LToken); end), EOperacaoCanceladaIA);
  Assert.AreEqual(0, LTransporte.QuantidadeChamadas);
end;

procedure TTestesGemini.Adaptador_DeveUsarModeloPadrao;
var LTransporte: TTransporteHTTPFalso; LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(RespostaHTTP(200, CRespostaGeminiSucesso));
  LAdaptador.Concluir(CriarRequisicao(''));
  Assert.IsTrue(LTransporte.UltimaRequisicao.Corpo.Contains(
    '"model":"' + CModeloGeminiPadrao + '"'));
end;

procedure TTestesGemini.Adaptador_DevePreservarPensamentoNoSegundoTurno;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LPrimeiraResposta: IRespostaChatIA;
  LMensagens: TArray<IMensagemIA>;
  LSegundaRequisicao: IRequisicaoChatIA;
  LJSON: TJSONObject;
  LEntrada: TJSONArray;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(
    RespostaHTTP(200, CRespostaGeminiComPensamento));
  LPrimeiraResposta := LAdaptador.Concluir(CriarRequisicao);
  Assert.AreEqual(CPrefixoContextoGemini + 'int_pensamento_123',
    LPrimeiraResposta.Mensagem.IdCorrelacao);

  SetLength(LMensagens, 3);
  LMensagens[0] := TMensagemIA.CriarTexto(TPapelMensagemIA.Usuario,
    'mensagem de teste');
  LMensagens[1] := LPrimeiraResposta.Mensagem;
  LMensagens[2] := TMensagemIA.CriarTexto(TPapelMensagemIA.Usuario,
    'segunda pergunta');
  LSegundaRequisicao := TRequisicaoChatIA.Create('modelo-explicito',
    LMensagens);
  LTransporte.ProgramarResposta(RespostaHTTP(200, CRespostaGeminiSucesso));
  LAdaptador.Concluir(LSegundaRequisicao);

  LJSON := TJSONObject.ParseJSONValue(
    LTransporte.UltimaRequisicao.Corpo) as TJSONObject;
  try
    LEntrada := LJSON.GetValue<TJSONArray>('input');
    Assert.AreEqual(4, LEntrada.Count);
    Assert.AreEqual(CTipoPensamentoGemini,
      (LEntrada.Items[1] as TJSONObject).GetValue<string>('type'));
    Assert.AreEqual('assinatura-opaca-123',
      (LEntrada.Items[1] as TJSONObject).GetValue<string>('signature'));
    Assert.AreEqual(CTipoSaidaModeloGemini,
      (LEntrada.Items[2] as TJSONObject).GetValue<string>('type'));
    Assert.AreEqual(CTipoEntradaUsuarioGemini,
      (LEntrada.Items[3] as TJSONObject).GetValue<string>('type'));
  finally
    LJSON.Free;
  end;
end;

procedure TTestesGemini.Mapeador_DeveFalharQuandoContextoLocalNaoExiste;
var
  LMapeador: IMapeadorGemini;
  LMensagens: TArray<IMensagemIA>;
  LRequisicao: IRequisicaoChatIA;
begin
  LMapeador := CriarMapeador;
  SetLength(LMensagens, 2);
  LMensagens[0] := TMensagemIA.CriarTexto(TPapelMensagemIA.Usuario,
    'pergunta');
  LMensagens[1] := TMensagemIA.CriarTexto(TPapelMensagemIA.Assistente,
    'resposta', '', CPrefixoContextoGemini + 'inexistente');
  LRequisicao := TRequisicaoChatIA.Create('modelo', LMensagens);
  Assert.WillRaise(TTestLocalMethod(procedure begin
    LMapeador.CriarContratoRequisicao(LRequisicao, 'padrao', 100).Free;
  end), EContratoGemini);
end;

procedure TTestesGemini.Adaptador_DeveRejeitarStepDesconhecido;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(
    RespostaHTTP(200, CRespostaGeminiStepDesconhecido));
  Assert.WillRaise(TTestLocalMethod(procedure begin
    LAdaptador.Concluir(CriarRequisicao);
  end), EContratoGemini);
end;

procedure TTestesGemini.Adaptador_DeveCriarCorrelacaoLocalQuandoRespostaNaoTemId;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LResposta: IRespostaChatIA;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(RespostaHTTP(200, CRespostaGeminiSemId));
  LResposta := LAdaptador.Concluir(CriarRequisicao);
  Assert.AreEqual('', LResposta.Id);
  Assert.IsTrue(LResposta.Mensagem.IdCorrelacao.StartsWith(
    CPrefixoContextoGemini));
  Assert.IsTrue(Length(LResposta.Mensagem.IdCorrelacao) >
    Length(CPrefixoContextoGemini));
end;

procedure TTestesGemini.Adaptador_DeveRejeitarPensamentoSemAssinatura;
var
  LTransporte: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporte);
  LTransporte.ProgramarResposta(
    RespostaHTTP(200, CRespostaGeminiPensamentoSemAssinatura));
  Assert.WillRaise(TTestLocalMethod(procedure begin
    LAdaptador.Concluir(CriarRequisicao);
  end), EContratoGemini);
end;

procedure TTestesGemini.Armazenamento_DeveGuardarRemoverELimpar;
var
  LArmazenamento: IArmazenamentoContextoGemini;
  LContexto: string;
begin
  LArmazenamento := TArmazenamentoContextoGemini.Create;
  LArmazenamento.Guardar('id-1', '{"steps":[]}');
  LArmazenamento.Guardar('id-2', '{"steps":[]}');
  Assert.AreEqual(2, LArmazenamento.Quantidade);
  Assert.IsTrue(LArmazenamento.TentarObter('id-1', LContexto));
  Assert.AreEqual('{"steps":[]}', LContexto);
  LArmazenamento.Remover('id-1');
  Assert.IsFalse(LArmazenamento.TentarObter('id-1', LContexto));
  LArmazenamento.Limpar;
  Assert.AreEqual(0, LArmazenamento.Quantidade);
end;

procedure TTestesGemini.Configuracao_DeveRejeitarModoRemotoAindaNaoImplementado;
begin
  Assert.WillRaise(TTestLocalMethod(procedure begin
    TConfiguracaoGemini.Create(CEndpointInteracoesGemini,
      CModeloGeminiPadrao, CMaximoTokensSaidaPadraoGemini,
      CTimeoutConexaoPadraoMS, CTimeoutRespostaPadraoMS,
      CLimiteRespostaPadraoBytes, TModoContextoGemini.RemotoGoogle).Free;
  end), EConfiguracaoGemini);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesGemini);

end.
