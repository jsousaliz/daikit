unit Daikit.Testes.RequisicaoResposta;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesRequisicaoResposta = class
  public
    [Test] procedure Uso_DeveCalcularTotal;
    [Test] procedure Uso_NaoDeveAceitarEntradaNegativa;
    [Test] procedure Uso_NaoDeveAceitarSaidaNegativa;
    [Test] procedure Requisicao_DevePreservarModeloEMensagens;
    [Test] procedure Requisicao_NaoDeveAceitarMensagensAusentes;
    [Test] procedure Requisicao_NaoDeveAceitarMensagemNula;
    [Test] procedure Requisicao_DeveProtegerColecaoInterna;
    [Test] procedure Resposta_DevePreservarDados;
    [Test] procedure Resposta_DeveAceitarUsoAusente;
    [Test] procedure Resposta_NaoDeveAceitarMensagemNula;
  end;

implementation

uses
  Daikit.Dominio.Excecoes,
  Daikit.Dominio.Interfaces,
  Daikit.Dominio.Mensagem,
  Daikit.Dominio.RequisicaoResposta;

function CriarMensagens: TArray<IMensagemIA>;
begin
  SetLength(Result, 1);
  Result[0] := TMensagemIA.CriarTexto(TPapelMensagemIA.Usuario, 'ola');
end;

procedure TTestesRequisicaoResposta.Requisicao_DevePreservarModeloEMensagens;
var
  LRequisicao: IRequisicaoChatIA;
begin
  LRequisicao := TRequisicaoChatIA.Create('modelo', CriarMensagens);
  Assert.AreEqual('modelo', LRequisicao.Modelo);
  Assert.AreEqual('ola', LRequisicao.Mensagens[0].Texto);
end;

procedure TTestesRequisicaoResposta.Requisicao_DeveProtegerColecaoInterna;
var
  LRequisicao: IRequisicaoChatIA;
  LMensagens: TArray<IMensagemIA>;
begin
  LRequisicao := TRequisicaoChatIA.Create('modelo', CriarMensagens);
  LMensagens := LRequisicao.Mensagens;
  LMensagens[0] := nil;
  Assert.AreEqual('ola', LRequisicao.Mensagens[0].Texto);
end;

procedure TTestesRequisicaoResposta.Requisicao_NaoDeveAceitarMensagemNula;
var
  LMensagens: TArray<IMensagemIA>;
begin
  SetLength(LMensagens, 1);
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TRequisicaoChatIA.Create('modelo', LMensagens).Free;
    end),
    EValidacaoDominioIA);
end;

procedure TTestesRequisicaoResposta.Requisicao_NaoDeveAceitarMensagensAusentes;
var
  LMensagens: TArray<IMensagemIA>;
begin
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TRequisicaoChatIA.Create('modelo', LMensagens).Free;
    end),
    EValidacaoDominioIA);
end;

procedure TTestesRequisicaoResposta.Resposta_DeveAceitarUsoAusente;
var
  LResposta: IRespostaChatIA;
begin
  LResposta := TRespostaChatIA.Create('',
    TMensagemIA.CriarTexto(TPapelMensagemIA.Assistente, 'ok'));
  Assert.IsNull(LResposta.Uso);
end;

procedure TTestesRequisicaoResposta.Resposta_DevePreservarDados;
var
  LResposta: IRespostaChatIA;
begin
  LResposta := TRespostaChatIA.Create('id-1',
    TMensagemIA.CriarTexto(TPapelMensagemIA.Assistente, 'ok'),
    TUsoIA.Create(2, 3));
  Assert.AreEqual('id-1', LResposta.Id);
  Assert.AreEqual('ok', LResposta.Mensagem.Texto);
  Assert.AreEqual(Int64(5), LResposta.Uso.UnidadesTotal);
end;

procedure TTestesRequisicaoResposta.Resposta_NaoDeveAceitarMensagemNula;
begin
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TRespostaChatIA.Create('id', nil).Free;
    end),
    EValidacaoDominioIA);
end;

procedure TTestesRequisicaoResposta.Uso_DeveCalcularTotal;
var
  LUso: IUsoIA;
begin
  LUso := TUsoIA.Create(10, 4);
  Assert.AreEqual(Int64(10), LUso.UnidadesEntrada);
  Assert.AreEqual(Int64(4), LUso.UnidadesSaida);
  Assert.AreEqual(Int64(14), LUso.UnidadesTotal);
end;

procedure TTestesRequisicaoResposta.Uso_NaoDeveAceitarEntradaNegativa;
begin
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TUsoIA.Create(-1, 0).Free;
    end),
    EValidacaoDominioIA);
end;

procedure TTestesRequisicaoResposta.Uso_NaoDeveAceitarSaidaNegativa;
begin
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TUsoIA.Create(0, -1).Free;
    end),
    EValidacaoDominioIA);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesRequisicaoResposta);

end.
