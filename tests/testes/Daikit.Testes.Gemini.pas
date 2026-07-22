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
  Daikit.Adaptadores.Interfaces,
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
  LTransporteHTTPFalso: ITransporteHTTP;
  LFonteChaveAPI: IFonteChaveAPI;
  LConfiguracaoGemini: IConfiguracaoGemini;
  LMapeadorGemini: IMapeadorGemini;
  LArmazenamentoContextoGemini: IArmazenamentoContextoGemini;
begin
  ATransporte := TTransporteHTTPFalso.Create;
  LTransporteHTTPFalso := ATransporte;
  LArmazenamentoContextoGemini := TArmazenamentoContextoGemini.Create;
  LFonteChaveAPI := TFonteChaveAPIMemoria.Create(AChave);
  LConfiguracaoGemini := TConfiguracaoGemini.Create;
  LMapeadorGemini := TMapeadorGemini.Create(LArmazenamentoContextoGemini);
  Result := TAdaptadorGemini.Create(LTransporteHTTPFalso, LFonteChaveAPI,
    LConfiguracaoGemini, LMapeadorGemini);
end;

function CriarMapeador: IMapeadorGemini;
begin
  Result := TMapeadorGemini.Create(TArmazenamentoContextoGemini.Create);
end;

function RespostaHTTP(AStatus: Integer; const ACorpo: string;
  const AId: string = ''): IRespostaHTTP;
var
  LCabecalhosHTTP: TArray<TCabecalhoHTTP>;
begin
  if AId <> '' then
  begin
    SetLength(LCabecalhosHTTP, 1);
    LCabecalhosHTTP[0] := TCabecalhoHTTP.Criar(CCabecalhoIdRequisicaoGemini, AId);
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

procedure TTestesGemini.Configuracao_DeveExigirHTTPS;
var
  LOpcoesConfiguracaoGemini: TOpcoesConfiguracaoGemini;
begin
  LOpcoesConfiguracaoGemini := TOpcoesConfiguracaoGemini.Padrao;
  LOpcoesConfiguracaoGemini.Comum.Endpoint := 'http://api.exemplo.test';
  Assert.WillRaise(TTestLocalMethod(procedure
    begin TConfiguracaoGemini.Create(LOpcoesConfiguracaoGemini).Free; end),
    EConfiguracaoGemini);
end;

procedure TTestesGemini.Mapeador_DeveOmitirSistemaAusente;
var LTransporteHTTPFalso: TTransporteHTTPFalso; LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(RespostaHTTP(200, CRespostaGeminiSucesso));
  LAdaptador.Concluir(CriarRequisicao);
  Assert.IsFalse(LTransporteHTTPFalso.UltimaRequisicao.Corpo.Contains(
    '"system_instruction"'));
end;

procedure TTestesGemini.Mapeador_DeveRejeitarMensagemFerramenta;
var LMapeadorGemini: IMapeadorGemini;
begin
  LMapeadorGemini := CriarMapeador;
  Assert.WillRaise(TTestLocalMethod(procedure begin
    LMapeadorGemini.CriarContratoRequisicao(CriarRequisicao('modelo',
      TPapelMensagemIA.Ferramenta), 'padrao', 100).Free; end), EContratoGemini);
end;

procedure TTestesGemini.Mapeador_DeveRejeitarSomenteMensagemSistema;
var LMapeadorGemini: IMapeadorGemini;
begin
  LMapeadorGemini := CriarMapeador;
  Assert.WillRaise(TTestLocalMethod(procedure begin
    LMapeadorGemini.CriarContratoRequisicao(CriarRequisicao('modelo',
      TPapelMensagemIA.Sistema), 'padrao', 100).Free; end), EContratoGemini);
end;

procedure TTestesGemini.Mapeador_DeveSepararMensagemSistema;
var
  LMensagens: TArray<IMensagemIA>;
  LRequisicaoChat: IRequisicaoChatIA;
  LContratoRequisicaoGemini: TRequisicaoInteracaoGemini;
  LMapeadorGemini: IMapeadorGemini;
begin
  SetLength(LMensagens, 2);
  LMensagens[0] := TMensagemIA.CriarTexto(TPapelMensagemIA.Sistema, 'instrucao');
  LMensagens[1] := TMensagemIA.CriarTexto(TPapelMensagemIA.Usuario, 'pergunta');
  LRequisicaoChat := TRequisicaoChatIA.Create('modelo', LMensagens);
  LMapeadorGemini := CriarMapeador;
  LContratoRequisicaoGemini := LMapeadorGemini.CriarContratoRequisicao(LRequisicaoChat, 'padrao', 100);
  try
    Assert.AreEqual('instrucao', LContratoRequisicaoGemini.InstrucaoSistema);
    Assert.AreEqual(1, Integer(Length(LContratoRequisicaoGemini.Entrada)));
    Assert.AreEqual(CTipoEntradaUsuarioGemini, LContratoRequisicaoGemini.Entrada[0].Tipo);
  finally
    LContratoRequisicaoGemini.Free;
  end;
end;

procedure TTestesGemini.Adaptador_DeveCriarRequisicaoAutenticadaStateless;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LObjetoJSON: TJSONObject;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(RespostaHTTP(200, CRespostaGeminiSucesso));
  LAdaptador.Concluir(CriarRequisicao);
  Assert.AreEqual(CEndpointInteracoesGemini, LTransporteHTTPFalso.UltimaRequisicao.URL);
  Assert.AreEqual('chave-gemini-falsa', ObterCabecalho(
    LTransporteHTTPFalso.UltimaRequisicao, CCabecalhoChaveGemini));
  LObjetoJSON := TJSONObject.ParseJSONValue(LTransporteHTTPFalso.UltimaRequisicao.Corpo)
    as TJSONObject;
  try
    Assert.AreEqual('modelo-explicito', LObjetoJSON.GetValue<string>('model'));
    Assert.IsFalse(LObjetoJSON.GetValue<Boolean>('store'));
    Assert.IsNotNull(LObjetoJSON.GetValue('input'));
    Assert.AreEqual(CMaximoTokensSaidaPadraoGemini,
      LObjetoJSON.GetValue<Integer>('generation_config.max_output_tokens'));
  finally
    LObjetoJSON.Free;
  end;
end;

procedure TTestesGemini.Adaptador_DeveFalharSemChaveAntesDoTransporte;
var LTransporteHTTPFalso: TTransporteHTTPFalso; LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso, '');
  Assert.WillRaise(TTestLocalMethod(procedure begin
    LAdaptador.Concluir(CriarRequisicao); end), EConfiguracaoGemini);
  Assert.AreEqual(0, LTransporteHTTPFalso.QuantidadeChamadas);
end;

procedure TTestesGemini.Adaptador_DeveInformarCapacidadesImplementadas;
var LTransporteHTTPFalso: TTransporteHTTPFalso; LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  Assert.IsTrue(LAdaptador.Capacidades.SuportaTextoSincrono);
  Assert.IsFalse(LAdaptador.Capacidades.SuportaFluxoContinuo);
  Assert.IsFalse(LAdaptador.Capacidades.SuportaFerramentas);
  Assert.IsFalse(LAdaptador.Capacidades.SuportaImagemEntrada);
  Assert.IsFalse(LAdaptador.Capacidades.SuportaSaidaEstruturada);
end;

procedure TTestesGemini.Adaptador_DeveMapearErroEmListaSemExporMensagem;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LCapturou: Boolean;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(RespostaHTTP(400,
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
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LCapturou: Boolean;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(RespostaHTTP(400, CRespostaGeminiErro,
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
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LRespostaChat: IRespostaChatIA;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(RespostaHTTP(200, CRespostaGeminiSucesso));
  LRespostaChat := LAdaptador.Concluir(CriarRequisicao);
  Assert.AreEqual('int_teste_123', LRespostaChat.Id);
  Assert.AreEqual('Ola do Gemini', LRespostaChat.Mensagem.Texto);
  Assert.AreEqual(Int64(12), LRespostaChat.Uso.UnidadesEntrada);
  Assert.AreEqual(Int64(8), LRespostaChat.Uso.UnidadesSaida);
end;

procedure TTestesGemini.Adaptador_DevePreservarMultiplosTextos;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LRespostaChat: IRespostaChatIA;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(
    RespostaHTTP(200, CRespostaGeminiMultiplosTextos));
  LRespostaChat := LAdaptador.Concluir(CriarRequisicao);
  Assert.AreEqual(2, Integer(Length(LRespostaChat.Mensagem.Partes)));
  Assert.AreEqual('primeira segunda', LRespostaChat.Mensagem.Texto);
end;

procedure TTestesGemini.Adaptador_DeveRespeitarCancelamento;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LTokenCancelamento: ITokenCancelamentoIA;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTokenCancelamento := TTokenCancelamentoIA.Create;
  LTokenCancelamento.Cancelar;
  Assert.WillRaise(TTestLocalMethod(procedure begin
    LAdaptador.Concluir(CriarRequisicao, LTokenCancelamento); end), EOperacaoCanceladaIA);
  Assert.AreEqual(0, LTransporteHTTPFalso.QuantidadeChamadas);
end;

procedure TTestesGemini.Adaptador_DeveUsarModeloPadrao;
var LTransporteHTTPFalso: TTransporteHTTPFalso; LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(RespostaHTTP(200, CRespostaGeminiSucesso));
  LAdaptador.Concluir(CriarRequisicao(''));
  Assert.IsTrue(LTransporteHTTPFalso.UltimaRequisicao.Corpo.Contains(
    '"model":"' + CModeloGeminiPadrao + '"'));
end;

procedure TTestesGemini.Adaptador_DevePreservarPensamentoNoSegundoTurno;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LPrimeiraResposta: IRespostaChatIA;
  LMensagens: TArray<IMensagemIA>;
  LSegundaRequisicao: IRequisicaoChatIA;
  LObjetoJSON: TJSONObject;
  LEntrada: TJSONArray;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(
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
  LTransporteHTTPFalso.ProgramarResposta(RespostaHTTP(200, CRespostaGeminiSucesso));
  LAdaptador.Concluir(LSegundaRequisicao);

  LObjetoJSON := TJSONObject.ParseJSONValue(
    LTransporteHTTPFalso.UltimaRequisicao.Corpo) as TJSONObject;
  try
    LEntrada := LObjetoJSON.GetValue<TJSONArray>('input');
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
    LObjetoJSON.Free;
  end;
end;

procedure TTestesGemini.Mapeador_DeveFalharQuandoContextoLocalNaoExiste;
var
  LMapeadorGemini: IMapeadorGemini;
  LMensagens: TArray<IMensagemIA>;
  LRequisicaoChat: IRequisicaoChatIA;
begin
  LMapeadorGemini := CriarMapeador;
  SetLength(LMensagens, 2);
  LMensagens[0] := TMensagemIA.CriarTexto(TPapelMensagemIA.Usuario,
    'pergunta');
  LMensagens[1] := TMensagemIA.CriarTexto(TPapelMensagemIA.Assistente,
    'resposta', '', CPrefixoContextoGemini + 'inexistente');
  LRequisicaoChat := TRequisicaoChatIA.Create('modelo', LMensagens);
  Assert.WillRaise(TTestLocalMethod(procedure begin
    LMapeadorGemini.CriarContratoRequisicao(LRequisicaoChat, 'padrao', 100).Free;
  end), EContratoGemini);
end;

procedure TTestesGemini.Adaptador_DeveRejeitarStepDesconhecido;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(
    RespostaHTTP(200, CRespostaGeminiStepDesconhecido));
  Assert.WillRaise(TTestLocalMethod(procedure begin
    LAdaptador.Concluir(CriarRequisicao);
  end), EContratoGemini);
end;

procedure TTestesGemini.Adaptador_DeveCriarCorrelacaoLocalQuandoRespostaNaoTemId;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
  LRespostaChat: IRespostaChatIA;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(RespostaHTTP(200, CRespostaGeminiSemId));
  LRespostaChat := LAdaptador.Concluir(CriarRequisicao);
  Assert.AreEqual('', LRespostaChat.Id);
  Assert.IsTrue(LRespostaChat.Mensagem.IdCorrelacao.StartsWith(
    CPrefixoContextoGemini));
  Assert.IsTrue(Length(LRespostaChat.Mensagem.IdCorrelacao) >
    Length(CPrefixoContextoGemini));
end;

procedure TTestesGemini.Adaptador_DeveRejeitarPensamentoSemAssinatura;
var
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LAdaptador: IAdaptadorIA;
begin
  LAdaptador := CriarAdaptador(LTransporteHTTPFalso);
  LTransporteHTTPFalso.ProgramarResposta(
    RespostaHTTP(200, CRespostaGeminiPensamentoSemAssinatura));
  Assert.WillRaise(TTestLocalMethod(procedure begin
    LAdaptador.Concluir(CriarRequisicao);
  end), EContratoGemini);
end;

procedure TTestesGemini.Armazenamento_DeveGuardarRemoverELimpar;
var
  LArmazenamentoContextoGemini: IArmazenamentoContextoGemini;
  LContexto: string;
begin
  LArmazenamentoContextoGemini := TArmazenamentoContextoGemini.Create;
  LArmazenamentoContextoGemini.Guardar('id-1', '{"steps":[]}');
  LArmazenamentoContextoGemini.Guardar('id-2', '{"steps":[]}');
  Assert.AreEqual(2, LArmazenamentoContextoGemini.Quantidade);
  Assert.IsTrue(LArmazenamentoContextoGemini.TentarObter('id-1', LContexto));
  Assert.AreEqual('{"steps":[]}', LContexto);
  LArmazenamentoContextoGemini.Remover('id-1');
  Assert.IsFalse(LArmazenamentoContextoGemini.TentarObter('id-1', LContexto));
  LArmazenamentoContextoGemini.Limpar;
  Assert.AreEqual(0, LArmazenamentoContextoGemini.Quantidade);
end;

procedure TTestesGemini.Configuracao_DeveRejeitarModoRemotoAindaNaoImplementado;
var
  LOpcoesConfiguracaoGemini: TOpcoesConfiguracaoGemini;
begin
  LOpcoesConfiguracaoGemini := TOpcoesConfiguracaoGemini.Padrao;
  LOpcoesConfiguracaoGemini.ModoContexto :=
    TModoContextoGemini.RemotoGoogle;
  Assert.WillRaise(TTestLocalMethod(procedure begin
    TConfiguracaoGemini.Create(LOpcoesConfiguracaoGemini).Free;
  end), EConfiguracaoGemini);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesGemini);

end.
