unit Daikit.Testes.Componentes;

interface

uses
  System.Classes,
  System.SysUtils,
  DUnitX.TestFramework,
  Daikit.Dominio.Interfaces,
  Daikit.Aplicacao.Interfaces,
  Daikit.Aplicacao.Log,
  Daikit.Componentes.OperacaoChat,
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
    FUltimaResposta: IRespostaChatIA;
    FUltimoErro: IErroChatIA;
    FThreadResposta: Cardinal;
    FThreadErro: Cardinal;
    FThreadConclusao: Cardinal;
    FThreadLog: Cardinal;
  public
    procedure AoIniciar(Sender: TObject);
    procedure AoResponder(Sender: TObject;
      const AResposta: IRespostaChatIA);
    procedure AoErro(Sender: TObject; const AErro: IErroChatIA);
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
    [Test] procedure Chat_DeveEnviarComProvedorFalsoEManterHistorico;
    [Test] procedure Chat_MensagemIsoladaNaoDeveAlterarHistorico;
    [Test] procedure Chat_DeveExigirConversa;
    [Test] procedure Chat_DeveNotificarErroEConclusao;
    [Test] procedure Chat_DevePermitirDestruicaoNoEventoConclusao;
    [Test] procedure Chat_DeveLimparReferenciasDeComponentesDestruidos;
    [Test] procedure Chat_DevePublicarLogDoProvedor;
    [Test] procedure Chat_DeveRecusarSegundoEnvioEnquantoExecuta;
    [Test] procedure Chat_DeveCancelarOperacaoEmAndamento;
    [Test] procedure Chat_DestruicaoDuranteEnvioNaoDevePublicarCallbacks;
    [Test] procedure Componentes_DevemPreservarReferenciasNoDFM;
  end;

implementation

uses
  Winapi.Windows,
  System.Diagnostics,
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
  Daikit.Testes.ProvedorFalso,
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
  FThreadConclusao := GetCurrentThreadId;
  FEstadoNaConclusao := TChatIA(Sender).Estado;
end;

procedure TObservadorChatIA.AoConcluirDestruindo(Sender: TObject);
begin
  AoConcluir(Sender);
  FChatParaDestruir.Free;
  FChatParaDestruir := nil;
end;
procedure TObservadorChatIA.AoErro(Sender: TObject;
  const AErro: IErroChatIA);
begin
  Inc(FErros);
  FThreadErro := GetCurrentThreadId;
  FUltimoErro := AErro;
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
  FThreadLog := GetCurrentThreadId;
  FUltimoLog := AEvento;
end;

procedure TObservadorChatIA.AoResponder(Sender: TObject;
  const AResposta: IRespostaChatIA);
begin
  Inc(FRespostas);
  FThreadResposta := GetCurrentThreadId;
  Assert.IsNotNull(AResposta);
  FUltimaResposta := AResposta;
end;

procedure AguardarConclusao(AObservador: TObservadorChatIA;
  AQuantidadeEsperada: Integer = 1);
const
  CTimeoutTesteMS = 5000;
var
  LCronometro: TStopwatch;
begin
  LCronometro := TStopwatch.StartNew;
  while (AObservador.FConclusoes < AQuantidadeEsperada) and
    (LCronometro.ElapsedMilliseconds < CTimeoutTesteMS) do
  begin
    CheckSynchronize(10);
    TThread.Sleep(1);
  end;
  Assert.AreEqual(AQuantidadeEsperada, AObservador.FConclusoes,
    'A operacao assincrona do chat nao foi concluida no tempo esperado.');
end;

class function TTestesComponentes.ComponenteComoTexto(
  AComponente: TComponent): string;
var
  LStreamBinario: TMemoryStream;
  LStreamTexto: TStringStream;
begin
  LStreamBinario := TMemoryStream.Create;
  LStreamTexto := TStringStream.Create('', TEncoding.UTF8);
  try
    LStreamBinario.WriteComponent(AComponente);
    LStreamBinario.Position := 0;
    ObjectBinaryToText(LStreamBinario, LStreamTexto);
    Result := LStreamTexto.DataString;
  finally
    LStreamTexto.Free;
    LStreamBinario.Free;
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

procedure TTestesComponentes.Chat_DeveEnviarComProvedorFalsoEManterHistorico;
var
  LChat: TChatIA;
  LObjetoAdaptadorFalso: TAdaptadorIAFalso;
  LAdaptadorFalso: IAdaptadorIA;
  LObservador: TObservadorChatIA;
  LProvedor: TProvedorIAFalso;
  LConversa: TConversaIA;
  LThreadPrincipal: Cardinal;
begin
  LThreadPrincipal := GetCurrentThreadId;
  LChat := TChatIA.Create(nil);
  LObservador := TObservadorChatIA.Create;
  try
    LObjetoAdaptadorFalso := TAdaptadorIAFalso.Create('Eco: ');
    LAdaptadorFalso := LObjetoAdaptadorFalso;
    LProvedor := TProvedorIAFalso.Create(LChat, LAdaptadorFalso);
    LConversa := TConversaIA.Create(LChat);
    LChat.Provedor := LProvedor;
    LChat.Conversa := LConversa;
    LChat.Modelo := 'modelo-teste';
    LChat.AoIniciarRequisicao := LObservador.AoIniciar;
    LChat.AoReceberResposta := LObservador.AoResponder;
    LChat.AoConcluir := LObservador.AoConcluir;
    LChat.Enviar('primeira');
    Assert.AreEqual(TEstadoChatIA.Executando, LChat.Estado);
    Assert.AreEqual(0, LObservador.FConclusoes);
    AguardarConclusao(LObservador);
    Assert.AreEqual('Eco: primeira',
      LObservador.FUltimaResposta.Mensagem.Texto);
    Assert.AreEqual(2, Integer(Length(LChat.ObterMensagens)));
    Assert.AreEqual('modelo-teste', LObjetoAdaptadorFalso.UltimaRequisicao.Modelo);
    Assert.AreEqual(TEstadoChatIA.Executando,
      LObservador.FEstadoNoInicio);
    Assert.AreEqual(TEstadoChatIA.Ocioso,
      LObservador.FEstadoNaConclusao);
    Assert.AreEqual(1, LObservador.FInicios);
    Assert.AreEqual(1, LObservador.FRespostas);
    Assert.AreEqual(1, LObservador.FConclusoes);
    Assert.AreEqual(LThreadPrincipal, LObservador.FThreadResposta);
    Assert.AreEqual(LThreadPrincipal, LObservador.FThreadConclusao);
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
  LTransporteHTTPFalso: TTransporteHTTPFalso;
  LObservador: TObservadorChatIA;
  LProvedor: TProvedorOpenAI;
  LTransporteHTTP: ITransporteHTTP;
  LThreadPrincipal: Cardinal;
begin
  LThreadPrincipal := GetCurrentThreadId;
  LChat := TChatIA.Create(nil);
  LProvedor := TProvedorOpenAI.Create(nil);
  LObservador := TObservadorChatIA.Create;
  try
    LTransporteHTTPFalso := TTransporteHTTPFalso.Create;
    LTransporteHTTP := LTransporteHTTPFalso;
    LTransporteHTTPFalso.ProgramarResposta(TRespostaHTTP.Create(200, 'OK',
      LCabecalhos, CRespostaOpenAISucesso));
    LProvedor.DefinirTransporte(LTransporteHTTP);
    LProvedor.ChaveAPI := CChaveAPITeste;
    LChat.Provedor := LProvedor;
    LChat.Conversa := TConversaIA.Create(LChat);
    LChat.AoRegistrarLog := LObservador.AoLog;
    LChat.AoConcluir := LObservador.AoConcluir;

    LChat.Enviar('pergunta que deve ficar visivel');
    AguardarConclusao(LObservador);

    Assert.AreEqual(2, LObservador.FLogs);
    Assert.IsNotNull(LObservador.FUltimoLog);
    Assert.AreEqual(CNomeProvedorLogOpenAI,
      LObservador.FUltimoLog.Provedor);
    Assert.IsTrue(LObservador.FUltimoLog.Mensagem.Contains(
      'Ola do OpenAI'));
    Assert.IsFalse(LObservador.FUltimoLog.Mensagem.Contains(
      CChaveAPITeste));
    Assert.AreEqual(LThreadPrincipal, LObservador.FThreadLog);
  finally
    LObservador.Free;
    LChat.Free;
    LProvedor.Free;
  end;
end;

procedure TTestesComponentes.Chat_DeveLimparReferenciasDeComponentesDestruidos;
var
  LProprietarioComponentes: TComponent;
  LChat: TChatIA;
  LProvedor: TProvedorOpenAI;
  LConversa: TConversaIA;
begin
  LProprietarioComponentes := TComponent.Create(nil);
  try
    LChat := TChatIA.Create(LProprietarioComponentes);
    LProvedor := TProvedorOpenAI.Create(LProprietarioComponentes);
    LConversa := TConversaIA.Create(LProprietarioComponentes);
    LChat.Provedor := LProvedor;
    LChat.Conversa := LConversa;
    LProvedor.Free;
    LConversa.Free;
    Assert.IsNull(LChat.Provedor);
    Assert.IsNull(LChat.Conversa);
  finally
    LProprietarioComponentes.Free;
  end;
end;

procedure TTestesComponentes.Chat_DeveNotificarErroEConclusao;
var
  LChat: TChatIA;
  LObjetoAdaptadorFalso: TAdaptadorIAFalso;
  LAdaptadorFalso: IAdaptadorIA;
  LObservador: TObservadorChatIA;
  LThreadPrincipal: Cardinal;
begin
  LThreadPrincipal := GetCurrentThreadId;
  LChat := TChatIA.Create(nil);
  LObservador := TObservadorChatIA.Create;
  try
    LObjetoAdaptadorFalso := TAdaptadorIAFalso.Create;
    LObjetoAdaptadorFalso.RetornarNulo := True;
    LAdaptadorFalso := LObjetoAdaptadorFalso;
    LChat.Provedor := TProvedorIAFalso.Create(LChat, LAdaptadorFalso);
    LChat.Conversa := TConversaIA.Create(LChat);
    LChat.AoOcorrerErro := LObservador.AoErro;
    LChat.AoConcluir := LObservador.AoConcluir;
    LChat.Enviar('resposta nula');
    AguardarConclusao(LObservador);
    Assert.AreEqual(1, LObservador.FErros);
    Assert.AreEqual(1, LObservador.FConclusoes);
    Assert.IsNotNull(LObservador.FUltimoErro);
    Assert.AreEqual('EValidacaoDominioIA', LObservador.FUltimoErro.Classe);
    Assert.AreEqual(LThreadPrincipal, LObservador.FThreadErro);
    Assert.AreEqual(TEstadoChatIA.Ocioso, LChat.Estado);
  finally
    LObservador.Free;
    LChat.Free;
  end;
end;

procedure TTestesComponentes.Chat_DeveExigirConversa;
var
  LChat: TChatIA;
  LAdaptadorFalso: IAdaptadorIA;
begin
  LChat := TChatIA.Create(nil);
  try
    LAdaptadorFalso := TAdaptadorIAFalso.Create;
    LChat.Provedor := TProvedorIAFalso.Create(LChat, LAdaptadorFalso);
    Assert.WillRaise(
      TTestLocalMethod(procedure
      begin
        LChat.Enviar('sem conversa');
      end),
      EConfiguracaoComponenteIA);
  finally
    LChat.Free;
  end;
end;

procedure TTestesComponentes.Chat_DevePermitirDestruicaoNoEventoConclusao;
var
  LChat: TChatIA;
  LAdaptadorFalso: IAdaptadorIA;
  LObservador: TObservadorChatIA;
begin
  LChat := TChatIA.Create(nil);
  LObservador := TObservadorChatIA.Create;
  try
    LAdaptadorFalso := TAdaptadorIAFalso.Create;
    LChat.Provedor := TProvedorIAFalso.Create(LChat, LAdaptadorFalso);
    LChat.Conversa := TConversaIA.Create(LChat);
    LObservador.FChatParaDestruir := LChat;
    LChat.AoConcluir := LObservador.AoConcluirDestruindo;
    LChat.Enviar('mensagem');
    AguardarConclusao(LObservador);
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
  LAdaptadorFalso: IAdaptadorIA;
  LObservador: TObservadorChatIA;
begin
  LChat := TChatIA.Create(nil);
  LObservador := TObservadorChatIA.Create;
  try
    LAdaptadorFalso := TAdaptadorIAFalso.Create;
    LChat.Provedor := TProvedorIAFalso.Create(LChat, LAdaptadorFalso);
    LChat.Conversa := TConversaIA.Create(LChat);
    LChat.ModoConversa := TModoConversaIA.MensagemIsolada;
    LChat.AoConcluir := LObservador.AoConcluir;
    LChat.Enviar('mensagem');
    AguardarConclusao(LObservador);
    Assert.AreEqual(0, Integer(Length(LChat.ObterMensagens)));
  finally
    LObservador.Free;
    LChat.Free;
  end;
end;

procedure TTestesComponentes.Chat_DeveRecusarSegundoEnvioEnquantoExecuta;
var
  LChat: TChatIA;
  LAdaptadorFalso: IAdaptadorIA;
  LObservador: TObservadorChatIA;
begin
  LChat := TChatIA.Create(nil);
  LObservador := TObservadorChatIA.Create;
  try
    LAdaptadorFalso := TAdaptadorIAFalso.Create;
    LChat.Provedor := TProvedorIAFalso.Create(LChat, LAdaptadorFalso);
    LChat.Conversa := TConversaIA.Create(LChat);
    LChat.AoConcluir := LObservador.AoConcluir;
    LChat.Enviar('primeira');
    Assert.WillRaise(
      TTestLocalMethod(procedure
      begin
        LChat.Enviar('segunda');
      end), EEstadoComponenteIA);
    AguardarConclusao(LObservador);
  finally
    LObservador.Free;
    LChat.Free;
  end;
end;

procedure TTestesComponentes.Chat_DeveCancelarOperacaoEmAndamento;
var
  LChat: TChatIA;
  LObjetoAdaptadorFalso: TAdaptadorIAFalso;
  LAdaptadorFalso: IAdaptadorIA;
  LObservador: TObservadorChatIA;
begin
  LChat := TChatIA.Create(nil);
  LObservador := TObservadorChatIA.Create;
  try
    LObjetoAdaptadorFalso := TAdaptadorIAFalso.Create;
    LObjetoAdaptadorFalso.AtrasoMS := 500;
    LAdaptadorFalso := LObjetoAdaptadorFalso;
    LChat.Provedor := TProvedorIAFalso.Create(LChat, LAdaptadorFalso);
    LChat.Conversa := TConversaIA.Create(LChat);
    LChat.AoOcorrerErro := LObservador.AoErro;
    LChat.AoConcluir := LObservador.AoConcluir;
    LChat.Enviar('cancelar');
    LChat.Cancelar;
    Assert.AreEqual(TEstadoChatIA.Cancelando, LChat.Estado);
    AguardarConclusao(LObservador);
    Assert.AreEqual(1, LObservador.FErros);
    Assert.AreEqual('EOperacaoCanceladaIA', LObservador.FUltimoErro.Classe);
    Assert.AreEqual(TEstadoChatIA.Ocioso, LChat.Estado);
  finally
    LObservador.Free;
    LChat.Free;
  end;
end;

procedure TTestesComponentes.Chat_DestruicaoDuranteEnvioNaoDevePublicarCallbacks;
var
  LChat: TChatIA;
  LObjetoAdaptadorFalso: TAdaptadorIAFalso;
  LAdaptadorFalso: IAdaptadorIA;
  LObservador: TObservadorChatIA;
begin
  LChat := TChatIA.Create(nil);
  LObservador := TObservadorChatIA.Create;
  try
    LObjetoAdaptadorFalso := TAdaptadorIAFalso.Create;
    LObjetoAdaptadorFalso.AtrasoMS := 500;
    LAdaptadorFalso := LObjetoAdaptadorFalso;
    LChat.Provedor := TProvedorIAFalso.Create(LChat, LAdaptadorFalso);
    LChat.Conversa := TConversaIA.Create(LChat);
    LChat.AoReceberResposta := LObservador.AoResponder;
    LChat.AoOcorrerErro := LObservador.AoErro;
    LChat.AoConcluir := LObservador.AoConcluir;
    LChat.Enviar('destruir');
    LChat.Free;
    LChat := nil;
    CheckSynchronize(20);
    Assert.AreEqual(0, LObservador.FRespostas);
    Assert.AreEqual(0, LObservador.FErros);
    Assert.AreEqual(0, LObservador.FConclusoes);
  finally
    LChat.Free;
    LObservador.Free;
  end;
end;

procedure TTestesComponentes.Componentes_DevemPreservarReferenciasNoDFM;
var
  LComponenteRaiz: TComponent;
  LCopiaComponente: TComponent;
  LChat: TChatIA;
  LChatCopia: TChatIA;
  LProvedor: TProvedorOpenAI;
  LConversa: TConversaIA;
  LStreamBinario: TMemoryStream;
begin
  LComponenteRaiz := TDataModule.Create(nil);
  LStreamBinario := TMemoryStream.Create;
  LCopiaComponente := nil;
  try
    LComponenteRaiz.Name := 'Raiz';
    LProvedor := TProvedorOpenAI.Create(LComponenteRaiz);
    LProvedor.Name := 'ProvedorOpenAI';
    LConversa := TConversaIA.Create(LComponenteRaiz);
    LConversa.Name := 'ConversaIA';
    LChat := TChatIA.Create(LComponenteRaiz);
    LChat.Name := 'ChatIA';
    LChat.Provedor := LProvedor;
    LChat.Conversa := LConversa;
    LStreamBinario.WriteComponent(LComponenteRaiz);
    LStreamBinario.Position := 0;
    LCopiaComponente := LStreamBinario.ReadComponent(nil);
    Assert.IsNotNull(LCopiaComponente);
    Assert.IsNotNull(LCopiaComponente.FindComponent('ChatIA'));
    LChatCopia := LCopiaComponente.FindComponent('ChatIA') as TChatIA;
    Assert.AreSame(LCopiaComponente.FindComponent('ProvedorOpenAI'),
      LChatCopia.Provedor);
    Assert.AreSame(LCopiaComponente.FindComponent('ConversaIA'),
      LChatCopia.Conversa);
  finally
    LCopiaComponente.Free;
    LStreamBinario.Free;
    LComponenteRaiz.Free;
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
    LConversa.AdicionarMensagemSistema('instrucao');
    LConversa.AdicionarMensagemUsuario('pergunta');
    LConversa.AdicionarMensagemAssistente('resposta');
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
    LConversa.AdicionarMensagemUsuario('mensagem');
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
    LConversa.AdicionarMensagemUsuario('mensagem preservada');
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
    LConversa.AdicionarMensagemSistema('instrucao');
    LConversa.AdicionarMensagemUsuario('pergunta');
    LConversa.AdicionarMensagemAssistente('resposta');
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
  LProvedorOpenAI: TProvedorOpenAI;
  LProvedorAnthropic: TProvedorAnthropic;
  LProvedorGemini: TProvedorGemini;
begin
  LProvedorOpenAI := TProvedorOpenAI.Create(nil);
  LProvedorAnthropic := TProvedorAnthropic.Create(nil);
  LProvedorGemini := TProvedorGemini.Create(nil);
  try
    Assert.IsNotNull(LProvedorOpenAI.CriarAdaptador);
    Assert.IsNotNull(LProvedorAnthropic.CriarAdaptador);
    Assert.IsNotNull(LProvedorGemini.CriarAdaptador);
  finally
    LProvedorGemini.Free;
    LProvedorAnthropic.Free;
    LProvedorOpenAI.Free;
  end;
end;

procedure TTestesComponentes.Provedores_DevemExporPadroesSeguros;
var
  LProvedorOpenAI: TProvedorOpenAI;
  LProvedorAnthropic: TProvedorAnthropic;
  LProvedorGemini: TProvedorGemini;
begin
  LProvedorOpenAI := TProvedorOpenAI.Create(nil);
  LProvedorAnthropic := TProvedorAnthropic.Create(nil);
  LProvedorGemini := TProvedorGemini.Create(nil);
  try
    Assert.AreEqual(CEndpointRespostasOpenAI, LProvedorOpenAI.Endpoint);
    Assert.AreEqual(CModeloOpenAIRecomendado, LProvedorOpenAI.ModeloPadrao);
    Assert.AreEqual(CVariavelAmbienteChaveOpenAI,
      LProvedorOpenAI.VariavelAmbienteChaveAPI);
    Assert.AreEqual(CEndpointMensagensAnthropic, LProvedorAnthropic.Endpoint);
    Assert.AreEqual(CModeloAnthropicPadrao, LProvedorAnthropic.ModeloPadrao);
    Assert.AreEqual(CVariavelAmbienteChaveAnthropic,
      LProvedorAnthropic.VariavelAmbienteChaveAPI);
    Assert.AreEqual(CEndpointInteracoesGemini, LProvedorGemini.Endpoint);
    Assert.AreEqual(CModeloGeminiPadrao, LProvedorGemini.ModeloPadrao);
    Assert.AreEqual(CVariavelAmbienteChaveGemini,
      LProvedorGemini.VariavelAmbienteChaveAPI);
    Assert.AreEqual(CTimeoutConexaoComponentePadraoMS,
      LProvedorOpenAI.TimeoutConexaoMS);
    Assert.AreEqual(CTimeoutRespostaComponentePadraoMS,
      LProvedorAnthropic.TimeoutRespostaMS);
    Assert.AreEqual(Int64(CLimiteRespostaComponentePadraoBytes),
      LProvedorGemini.LimiteRespostaBytes);
    Assert.AreEqual('', LProvedorOpenAI.ChaveAPI);
    Assert.AreEqual('', LProvedorAnthropic.ChaveAPI);
    Assert.AreEqual('', LProvedorGemini.ChaveAPI);
  finally
    LProvedorGemini.Free;
    LProvedorAnthropic.Free;
    LProvedorOpenAI.Free;
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
  System.Classes.RegisterClass(TDataModule);
  System.Classes.RegisterClasses([TProvedorOpenAI, TProvedorAnthropic,
    TProvedorGemini, TConversaIA, TChatIA]);
  TDUnitX.RegisterTestFixture(TTestesComponentes);

end.
