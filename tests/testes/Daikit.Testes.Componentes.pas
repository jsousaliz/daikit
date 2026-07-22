unit Daikit.Testes.Componentes;

interface

uses
  System.Classes,
  System.SysUtils,
  DUnitX.TestFramework,
  Daikit.Dominio.Interfaces,
  Daikit.Aplicacao.Interfaces,
  Daikit.Aplicacao.Log,
  Daikit.Componentes.Chat;

type
  TObservadorChatIA = class
  private
    FInicios: Integer;
    FRespostas: Integer;
    FErros: Integer;
    FConclusoes: Integer;
    FEstadoNoInicio: TEstadoChatIA;
    FEstadoNaConclusao: TEstadoChatIA;
    FChatParaDestruir: TChatIA;
    FLogs: Integer;
    FUltimoLog: IEventoLogIA;
  public
    procedure AoIniciar(Sender: TObject);
    procedure AoResponder(Sender: TObject;
      const AResposta: IRespostaChatIA);
    procedure AoErro(Sender: TObject; const AExcecao: Exception);
    procedure AoConcluir(Sender: TObject);
    procedure AoConcluirDestruindo(Sender: TObject);
    procedure AoLog(Sender: TObject; const AEvento: IEventoLogIA);
  end;

  TObservadorConversaIA = class
  private
    FAdicoes: Integer;
    FLimpezas: Integer;
    FAlteracoes: Integer;
    FUltimaMensagem: IMensagemIA;
  public
    procedure AoAdicionar(Sender: TObject;
      const AMensagem: IMensagemIA);
    procedure AoLimpar(Sender: TObject);
    procedure AoAlterar(Sender: TObject);
  end;

  [TestFixture]
  TTestesComponentes = class
  private
    class function ComponenteComoTexto(AComponente: TComponent): string;
      static;
  public
    [Test] procedure Paleta_DeveUsarNomeDaikit;
    [Test] procedure Provedores_DevemExporPadroesSeguros;
    [Test] procedure Provedores_DevemPersistirConfiguracoesComunsAlteradas;
    [Test] procedure Provedores_DevemCriarAdaptadoresCanonicos;
    [Test] procedure ProvedorGemini_DeveRejeitarContextoRemoto;
    [Test] procedure ChaveAPI_NaoDeveSerExpostaNemPersistidaNoDFM;
    [Test] procedure Conversa_DeveGerenciarHistoricoEmMemoria;
    [Test] procedure Conversa_DeveNotificarAdicaoEAlteracao;
    [Test] procedure Conversa_DeveNotificarLimpezaSomenteQuandoAlterada;
    [Test] procedure Conversa_DeveNotificarTrocaDeArmazenamento;
    [Test] procedure Chat_DeveEnviarComProvedorInjetadoEManterHistorico;
    [Test] procedure Chat_MensagemIsoladaNaoDeveAlterarHistorico;
    [Test] procedure Chat_DeveNotificarErroEConclusao;
    [Test] procedure Chat_DevePermitirDestruicaoNoEventoConclusao;
    [Test] procedure Chat_DeveLimparReferenciasDeComponentesDestruidos;
    [Test] procedure Chat_DevePublicarLogDoProvedor;
    [Test] procedure Componentes_DevemPreservarReferenciasNoDFM;
  end;

implementation

uses
  Daikit.Componentes.Constantes,
  Daikit.Componentes.Excecoes,
  Daikit.Componentes.Provedores,
  Daikit.Componentes.Conversa,
  Daikit.Dominio.ArmazenamentoContexto,
  Daikit.Dominio.Excecoes,
  Daikit.Adaptadores.OpenAI.Constantes,
  Daikit.Adaptadores.Anthropic.Constantes,
  Daikit.Adaptadores.Gemini.Constantes,
  Daikit.Adaptadores.Gemini.Excecoes,
  Daikit.Adaptadores.Gemini.Interfaces,
  Daikit.Infraestrutura.HTTP.Interfaces,
  Daikit.Infraestrutura.HTTP.Modelos,
  Daikit.Testes.AdaptadorFalso,
  Daikit.Testes.TransporteHTTPFalso,
  Daikit.Testes.Fixtures.OpenAI;

procedure TObservadorConversaIA.AoAdicionar(Sender: TObject;
  const AMensagem: IMensagemIA);
begin
  Inc(FAdicoes);
  FUltimaMensagem := AMensagem;
end;

procedure TObservadorConversaIA.AoAlterar(Sender: TObject);
begin
  Inc(FAlteracoes);
end;

procedure TObservadorConversaIA.AoLimpar(Sender: TObject);
begin
  Inc(FLimpezas);
end;

procedure TObservadorChatIA.AoConcluir(Sender: TObject);
begin
  Inc(FConclusoes);
  FEstadoNaConclusao := TChatIA(Sender).Estado;
end;

procedure TObservadorChatIA.AoConcluirDestruindo(Sender: TObject);
begin
  AoConcluir(Sender);
  FChatParaDestruir.Free;
  FChatParaDestruir := nil;
end;
procedure TObservadorChatIA.AoErro(Sender: TObject;
  const AExcecao: Exception);
begin
  Inc(FErros);
end;

procedure TObservadorChatIA.AoIniciar(Sender: TObject);
begin
  Inc(FInicios);
  FEstadoNoInicio := TChatIA(Sender).Estado;
end;

procedure TObservadorChatIA.AoLog(Sender: TObject;
  const AEvento: IEventoLogIA);
begin
  Inc(FLogs);
  FUltimoLog := AEvento;
end;

procedure TObservadorChatIA.AoResponder(Sender: TObject;
  const AResposta: IRespostaChatIA);
begin
  Inc(FRespostas);
  Assert.IsNotNull(AResposta);
end;

class function TTestesComponentes.ComponenteComoTexto(
  AComponente: TComponent): string;
var
  LBinario: TMemoryStream;
  LTexto: TStringStream;
begin
  LBinario := TMemoryStream.Create;
  LTexto := TStringStream.Create('', TEncoding.UTF8);
  try
    LBinario.WriteComponent(AComponente);
    LBinario.Position := 0;
    ObjectBinaryToText(LBinario, LTexto);
    Result := LTexto.DataString;
  finally
    LTexto.Free;
    LBinario.Free;
  end;
end;

procedure TTestesComponentes.ChaveAPI_NaoDeveSerExpostaNemPersistidaNoDFM;
const
  CChaveTeste = 'chave-secreta-que-nao-pode-ser-persistida';
var
  LProvedor: TProvedorOpenAI;
  LDFM: string;
begin
  LProvedor := TProvedorOpenAI.Create(nil);
  try
    LProvedor.Name := 'ProvedorOpenAI';
    LProvedor.ChaveAPI := CChaveTeste;
    Assert.AreEqual(CValorChaveAPIMascarada, LProvedor.ChaveAPI);
    Assert.IsTrue(LProvedor.TemChaveAPIEmMemoria);
    LDFM := ComponenteComoTexto(LProvedor);
    Assert.AreEqual(0, Pos(CChaveTeste, LDFM));
    Assert.AreEqual(0, Pos('ChaveAPI', LDFM));
    LProvedor.LimparChaveAPI;
    Assert.AreEqual('', LProvedor.ChaveAPI);
  finally
    LProvedor.Free;
  end;
end;

procedure TTestesComponentes.Chat_DeveEnviarComProvedorInjetadoEManterHistorico;
var
  LChat: TChatIA;
  LFalsoObjeto: TAdaptadorIAFalso;
  LFalso: IAdaptadorIA;
  LObservador: TObservadorChatIA;
begin
  LChat := TChatIA.Create(nil);
  LObservador := TObservadorChatIA.Create;
  try
    LFalsoObjeto := TAdaptadorIAFalso.Create('Eco: ');
    LFalso := LFalsoObjeto;
    LChat.DefinirAdaptadorInjetado(LFalso);
    LChat.Modelo := 'modelo-teste';
    LChat.AoIniciarRequisicao := LObservador.AoIniciar;
    LChat.AoReceberResposta := LObservador.AoResponder;
    LChat.AoConcluir := LObservador.AoConcluir;
    Assert.AreEqual('Eco: primeira', LChat.EnviarTexto('primeira'));
    Assert.AreEqual(2, Integer(Length(LChat.ObterMensagens)));
    Assert.AreEqual('modelo-teste', LFalsoObjeto.UltimaRequisicao.Modelo);
    Assert.AreEqual(TEstadoChatIA.Executando,
      LObservador.FEstadoNoInicio);
    Assert.AreEqual(TEstadoChatIA.Ocioso,
      LObservador.FEstadoNaConclusao);
    Assert.AreEqual(1, LObservador.FInicios);
    Assert.AreEqual(1, LObservador.FRespostas);
    Assert.AreEqual(1, LObservador.FConclusoes);
  finally
    LObservador.Free;
    LChat.Free;
  end;
end;

procedure TTestesComponentes.Chat_DevePublicarLogDoProvedor;
const
  CChaveAPITeste = 'chave-api-componente-log';
var
  LCabecalhos: TArray<TCabecalhoHTTP>;
  LChat: TChatIA;
  LObjetoTransporte: TTransporteHTTPFalso;
  LObservador: TObservadorChatIA;
  LProvedor: TProvedorOpenAI;
  LTransporte: ITransporteHTTP;
begin
  LChat := TChatIA.Create(nil);
  LProvedor := TProvedorOpenAI.Create(nil);
  LObservador := TObservadorChatIA.Create;
  try
    LObjetoTransporte := TTransporteHTTPFalso.Create;
    LTransporte := LObjetoTransporte;
    LObjetoTransporte.ProgramarResposta(TRespostaHTTP.Create(200, 'OK',
      LCabecalhos, CRespostaOpenAISucesso));
    LProvedor.DefinirTransporte(LTransporte);
    LProvedor.ChaveAPI := CChaveAPITeste;
    LChat.Provedor := LProvedor;
    LChat.AoRegistrarLog := LObservador.AoLog;

    LChat.EnviarTexto('pergunta que deve ficar visivel');

    Assert.AreEqual(2, LObservador.FLogs);
    Assert.IsNotNull(LObservador.FUltimoLog);
    Assert.AreEqual(CNomeProvedorLogOpenAI,
      LObservador.FUltimoLog.Provedor);
    Assert.IsTrue(LObservador.FUltimoLog.Mensagem.Contains(
      'Ola do OpenAI'));
    Assert.IsFalse(LObservador.FUltimoLog.Mensagem.Contains(
      CChaveAPITeste));
  finally
    LObservador.Free;
    LChat.Free;
    LProvedor.Free;
  end;
end;

procedure TTestesComponentes.Chat_DeveLimparReferenciasDeComponentesDestruidos;
var
  LOwner: TComponent;
  LChat: TChatIA;
  LProvedor: TProvedorOpenAI;
  LConversa: TConversaIA;
begin
  LOwner := TComponent.Create(nil);
  try
    LChat := TChatIA.Create(LOwner);
    LProvedor := TProvedorOpenAI.Create(LOwner);
    LConversa := TConversaIA.Create(LOwner);
    LChat.Provedor := LProvedor;
    LChat.Conversa := LConversa;
    LProvedor.Free;
    LConversa.Free;
    Assert.IsNull(LChat.Provedor);
    Assert.IsNull(LChat.Conversa);
  finally
    LOwner.Free;
  end;
end;

procedure TTestesComponentes.Chat_DeveNotificarErroEConclusao;
var
  LChat: TChatIA;
  LObservador: TObservadorChatIA;
begin
  LChat := TChatIA.Create(nil);
  LObservador := TObservadorChatIA.Create;
  try
    LChat.AoOcorrerErro := LObservador.AoErro;
    LChat.AoConcluir := LObservador.AoConcluir;
    Assert.WillRaise(
      TTestLocalMethod(procedure
      begin
        LChat.Enviar('sem provedor');
      end),
      EConfiguracaoComponenteIA);
    Assert.AreEqual(1, LObservador.FErros);
    Assert.AreEqual(1, LObservador.FConclusoes);
    Assert.AreEqual(TEstadoChatIA.Ocioso, LChat.Estado);
  finally
    LObservador.Free;
    LChat.Free;
  end;
end;

procedure TTestesComponentes.Chat_DevePermitirDestruicaoNoEventoConclusao;
var
  LChat: TChatIA;
  LFalso: IAdaptadorIA;
  LObservador: TObservadorChatIA;
begin
  LChat := TChatIA.Create(nil);
  LObservador := TObservadorChatIA.Create;
  try
    LFalso := TAdaptadorIAFalso.Create;
    LChat.DefinirAdaptadorInjetado(LFalso);
    LObservador.FChatParaDestruir := LChat;
    LChat.AoConcluir := LObservador.AoConcluirDestruindo;
    LChat.Enviar('mensagem');
    Assert.IsNull(LObservador.FChatParaDestruir);
    Assert.AreEqual(1, LObservador.FConclusoes);
  finally
    LObservador.FChatParaDestruir.Free;
    LObservador.Free;
  end;
end;
procedure TTestesComponentes.Chat_MensagemIsoladaNaoDeveAlterarHistorico;
var
  LChat: TChatIA;
  LFalso: IAdaptadorIA;
begin
  LChat := TChatIA.Create(nil);
  try
    LFalso := TAdaptadorIAFalso.Create;
    LChat.DefinirAdaptadorInjetado(LFalso);
    LChat.ModoConversa := TModoConversaIA.MensagemIsolada;
    LChat.Enviar('mensagem');
    Assert.AreEqual(0, Integer(Length(LChat.ObterMensagens)));
  finally
    LChat.Free;
  end;
end;

procedure TTestesComponentes.Componentes_DevemPreservarReferenciasNoDFM;
var
  LRaiz: TComponent;
  LCopia: TComponent;
  LChat: TChatIA;
  LChatCopia: TChatIA;
  LProvedor: TProvedorOpenAI;
  LConversa: TConversaIA;
  LBinario: TMemoryStream;
begin
  LRaiz := TDataModule.Create(nil);
  LBinario := TMemoryStream.Create;
  LCopia := nil;
  try
    LRaiz.Name := 'Raiz';
    LProvedor := TProvedorOpenAI.Create(LRaiz);
    LProvedor.Name := 'ProvedorOpenAI';
    LConversa := TConversaIA.Create(LRaiz);
    LConversa.Name := 'ConversaIA';
    LChat := TChatIA.Create(LRaiz);
    LChat.Name := 'ChatIA';
    LChat.Provedor := LProvedor;
    LChat.Conversa := LConversa;
    LBinario.WriteComponent(LRaiz);
    LBinario.Position := 0;
    LCopia := LBinario.ReadComponent(nil);
    Assert.IsNotNull(LCopia);
    Assert.IsNotNull(LCopia.FindComponent('ChatIA'));
    LChatCopia := LCopia.FindComponent('ChatIA') as TChatIA;
    Assert.AreSame(LCopia.FindComponent('ProvedorOpenAI'),
      LChatCopia.Provedor);
    Assert.AreSame(LCopia.FindComponent('ConversaIA'),
      LChatCopia.Conversa);
  finally
    LCopia.Free;
    LBinario.Free;
    LRaiz.Free;
  end;
end;

procedure TTestesComponentes.Conversa_DeveNotificarAdicaoEAlteracao;
var
  LConversa: TConversaIA;
  LObservador: TObservadorConversaIA;
begin
  LConversa := TConversaIA.Create(nil);
  LObservador := TObservadorConversaIA.Create;
  try
    LConversa.AoAdicionar := LObservador.AoAdicionar;
    LConversa.AoAlterar := LObservador.AoAlterar;
    LConversa.AdicionarSistema('instrucao');
    LConversa.AdicionarUsuario('pergunta');
    LConversa.AdicionarAssistente('resposta');
    Assert.AreEqual(3, LObservador.FAdicoes);
    Assert.AreEqual(3, LObservador.FAlteracoes);
    Assert.IsNotNull(LObservador.FUltimaMensagem);
    Assert.AreEqual(Integer(TPapelMensagemIA.Assistente),
      Integer(LObservador.FUltimaMensagem.Papel));
    Assert.AreEqual('resposta', LObservador.FUltimaMensagem.Texto);
  finally
    LObservador.Free;
    LConversa.Free;
  end;
end;

procedure TTestesComponentes.Conversa_DeveNotificarLimpezaSomenteQuandoAlterada;
var
  LConversa: TConversaIA;
  LObservador: TObservadorConversaIA;
begin
  LConversa := TConversaIA.Create(nil);
  LObservador := TObservadorConversaIA.Create;
  try
    LConversa.AdicionarUsuario('mensagem');
    LConversa.AoLimpar := LObservador.AoLimpar;
    LConversa.AoAlterar := LObservador.AoAlterar;
    LConversa.Limpar;
    Assert.AreEqual(1, LObservador.FLimpezas);
    Assert.AreEqual(1, LObservador.FAlteracoes);
    Assert.AreEqual(0, LConversa.Quantidade);
    LConversa.Limpar;
    Assert.AreEqual(1, LObservador.FLimpezas);
    Assert.AreEqual(1, LObservador.FAlteracoes);
  finally
    LObservador.Free;
    LConversa.Free;
  end;
end;

procedure TTestesComponentes.Conversa_DeveNotificarTrocaDeArmazenamento;
var
  LConversa: TConversaIA;
  LObservador: TObservadorConversaIA;
begin
  LConversa := TConversaIA.Create(nil);
  LObservador := TObservadorConversaIA.Create;
  try
    LConversa.AdicionarUsuario('mensagem preservada');
    LConversa.AoAlterar := LObservador.AoAlterar;
    Assert.WillRaise(
      TTestLocalMethod(procedure
      begin
        LConversa.DefinirArmazenamentoContexto(nil);
      end),
      EValidacaoDominioIA);
    Assert.AreEqual(1, LConversa.Quantidade);
    Assert.AreEqual(0, LObservador.FAlteracoes);
    LConversa.DefinirArmazenamentoContexto(TArmazenamentoContextoIA.Create);
    Assert.AreEqual(0, LConversa.Quantidade);
    Assert.AreEqual(1, LObservador.FAlteracoes);
  finally
    LObservador.Free;
    LConversa.Free;
  end;
end;

procedure TTestesComponentes.Conversa_DeveGerenciarHistoricoEmMemoria;
var
  LConversa: TConversaIA;
begin
  LConversa := TConversaIA.Create(nil);
  try
    LConversa.AdicionarSistema('instrucao');
    LConversa.AdicionarUsuario('pergunta');
    LConversa.AdicionarAssistente('resposta');
    Assert.AreEqual(3, LConversa.Quantidade);
    Assert.AreEqual(3, Integer(Length(LConversa.ObterMensagens)));
    LConversa.Limpar;
    Assert.AreEqual(0, LConversa.Quantidade);
  finally
    LConversa.Free;
  end;
end;

procedure TTestesComponentes.ProvedorGemini_DeveRejeitarContextoRemoto;
var
  LProvedor: TProvedorGemini;
begin
  LProvedor := TProvedorGemini.Create(nil);
  try
    LProvedor.ModoContexto := TModoContextoGemini.RemotoGoogle;
    Assert.WillRaise(
      TTestLocalMethod(procedure
      begin
        LProvedor.CriarAdaptador;
      end),
      EConfiguracaoGemini);
  finally
    LProvedor.Free;
  end;
end;

procedure TTestesComponentes.Paleta_DeveUsarNomeDaikit;
begin
  Assert.AreEqual('Daikit', CNomePaletaDaikit);
end;

procedure TTestesComponentes.Provedores_DevemCriarAdaptadoresCanonicos;
var
  LOpenAI: TProvedorOpenAI;
  LAnthropic: TProvedorAnthropic;
  LGemini: TProvedorGemini;
begin
  LOpenAI := TProvedorOpenAI.Create(nil);
  LAnthropic := TProvedorAnthropic.Create(nil);
  LGemini := TProvedorGemini.Create(nil);
  try
    Assert.IsNotNull(LOpenAI.CriarAdaptador);
    Assert.IsNotNull(LAnthropic.CriarAdaptador);
    Assert.IsNotNull(LGemini.CriarAdaptador);
  finally
    LGemini.Free;
    LAnthropic.Free;
    LOpenAI.Free;
  end;
end;

procedure TTestesComponentes.Provedores_DevemExporPadroesSeguros;
var
  LOpenAI: TProvedorOpenAI;
  LAnthropic: TProvedorAnthropic;
  LGemini: TProvedorGemini;
begin
  LOpenAI := TProvedorOpenAI.Create(nil);
  LAnthropic := TProvedorAnthropic.Create(nil);
  LGemini := TProvedorGemini.Create(nil);
  try
    Assert.AreEqual(CEndpointRespostasOpenAI, LOpenAI.Endpoint);
    Assert.AreEqual(CModeloOpenAIRecomendado, LOpenAI.ModeloPadrao);
    Assert.AreEqual(CVariavelAmbienteChaveOpenAI,
      LOpenAI.VariavelAmbienteChaveAPI);
    Assert.AreEqual(CEndpointMensagensAnthropic, LAnthropic.Endpoint);
    Assert.AreEqual(CModeloAnthropicPadrao, LAnthropic.ModeloPadrao);
    Assert.AreEqual(CVariavelAmbienteChaveAnthropic,
      LAnthropic.VariavelAmbienteChaveAPI);
    Assert.AreEqual(CEndpointInteracoesGemini, LGemini.Endpoint);
    Assert.AreEqual(CModeloGeminiPadrao, LGemini.ModeloPadrao);
    Assert.AreEqual(CVariavelAmbienteChaveGemini,
      LGemini.VariavelAmbienteChaveAPI);
    Assert.AreEqual(CTimeoutConexaoComponentePadraoMS,
      LOpenAI.TimeoutConexaoMS);
    Assert.AreEqual(CTimeoutRespostaComponentePadraoMS,
      LAnthropic.TimeoutRespostaMS);
    Assert.AreEqual(Int64(CLimiteRespostaComponentePadraoBytes),
      LGemini.LimiteRespostaBytes);
    Assert.AreEqual('', LOpenAI.ChaveAPI);
    Assert.AreEqual('', LAnthropic.ChaveAPI);
    Assert.AreEqual('', LGemini.ChaveAPI);
  finally
    LGemini.Free;
    LAnthropic.Free;
    LOpenAI.Free;
  end;
end;

procedure TTestesComponentes.Provedores_DevemPersistirConfiguracoesComunsAlteradas;
const
  CEndpointTeste = 'https://api.exemplo.test/v1';
  CModeloTeste = 'modelo-personalizado';
  CVariavelTeste = 'DAIKIT_API_KEY_TESTE';
var
  LProvedor: TProvedorOpenAI;
  LDFM: string;
begin
  LProvedor := TProvedorOpenAI.Create(nil);
  try
    LProvedor.Name := 'ProvedorOpenAI';
    LDFM := ComponenteComoTexto(LProvedor);
    Assert.AreEqual(0, Pos('Endpoint =', LDFM));
    Assert.AreEqual(0, Pos('ModeloPadrao =', LDFM));
    Assert.AreEqual(0, Pos('VariavelAmbienteChaveAPI =', LDFM));
    Assert.AreEqual(0, Pos('TimeoutConexaoMS =', LDFM));
    Assert.AreEqual(0, Pos('TimeoutRespostaMS =', LDFM));
    Assert.AreEqual(0, Pos('LimiteRespostaBytes =', LDFM));

    LProvedor.Endpoint := CEndpointTeste;
    LProvedor.ModeloPadrao := CModeloTeste;
    LProvedor.VariavelAmbienteChaveAPI := CVariavelTeste;
    LProvedor.TimeoutConexaoMS := CTimeoutConexaoComponentePadraoMS + 1;
    LProvedor.TimeoutRespostaMS := CTimeoutRespostaComponentePadraoMS + 1;
    LProvedor.LimiteRespostaBytes :=
      CLimiteRespostaComponentePadraoBytes + 1;

    LDFM := ComponenteComoTexto(LProvedor);
    Assert.IsTrue(Pos('Endpoint =', LDFM) > 0);
    Assert.IsTrue(Pos(CEndpointTeste, LDFM) > 0);
    Assert.IsTrue(Pos('ModeloPadrao =', LDFM) > 0);
    Assert.IsTrue(Pos(CModeloTeste, LDFM) > 0);
    Assert.IsTrue(Pos('VariavelAmbienteChaveAPI =', LDFM) > 0);
    Assert.IsTrue(Pos(CVariavelTeste, LDFM) > 0);
    Assert.IsTrue(Pos('TimeoutConexaoMS =', LDFM) > 0);
    Assert.IsTrue(Pos('TimeoutRespostaMS =', LDFM) > 0);
    Assert.IsTrue(Pos('LimiteRespostaBytes =', LDFM) > 0);
  finally
    LProvedor.Free;
  end;
end;

initialization
  RegisterClass(TDataModule);
  RegisterClasses([TProvedorOpenAI, TProvedorAnthropic, TProvedorGemini,
    TConversaIA, TChatIA]);
  TDUnitX.RegisterTestFixture(TTestesComponentes);

end.
