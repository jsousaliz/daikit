unit Daikit.Testes.ArmazenamentoContexto;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesArmazenamentoContextoIA = class
  public
    [Test] procedure Armazenamento_DeveAdicionarObterELimpar;
    [Test] procedure Armazenamento_DeveProtegerColecaoInterna;
    [Test] procedure Armazenamento_NaoDeveAceitarMensagemNula;
    [Test] procedure Contexto_DeveAdicionarPapeisConvenientes;
    [Test] procedure Contexto_NaoDeveAceitarArmazenamentoNulo;
  end;

implementation

uses
  Daikit.Dominio.Excecoes,
  Daikit.Dominio.Interfaces,
  Daikit.Dominio.Mensagem,
  Daikit.Dominio.ArmazenamentoContexto,
  Daikit.Dominio.Contexto;

procedure TTestesArmazenamentoContextoIA.Armazenamento_DeveAdicionarObterELimpar;
var
  LArmazenamento: IArmazenamentoContextoIA;
  LMensagens: TArray<IMensagemIA>;
begin
  LArmazenamento := TArmazenamentoContextoIA.Create;
  Assert.AreEqual(0, LArmazenamento.Quantidade);

  LArmazenamento.Adicionar(
    TMensagemIA.CriarTexto(TPapelMensagemIA.Usuario, 'ola'));
  LMensagens := LArmazenamento.ObterInstantaneo;
  Assert.AreEqual(1, LArmazenamento.Quantidade);
  Assert.AreEqual('ola', LMensagens[0].Texto);

  LArmazenamento.Limpar;
  Assert.AreEqual(0, LArmazenamento.Quantidade);
end;

procedure TTestesArmazenamentoContextoIA.Armazenamento_DeveProtegerColecaoInterna;
var
  LArmazenamento: IArmazenamentoContextoIA;
  LMensagens: TArray<IMensagemIA>;
begin
  LArmazenamento := TArmazenamentoContextoIA.Create;
  LArmazenamento.Adicionar(
    TMensagemIA.CriarTexto(TPapelMensagemIA.Usuario, 'ola'));
  LMensagens := LArmazenamento.ObterInstantaneo;
  LMensagens[0] := nil;

  Assert.AreEqual('ola', LArmazenamento.ObterInstantaneo[0].Texto);
end;

procedure TTestesArmazenamentoContextoIA.Armazenamento_NaoDeveAceitarMensagemNula;
var
  LArmazenamento: IArmazenamentoContextoIA;
begin
  LArmazenamento := TArmazenamentoContextoIA.Create;
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      LArmazenamento.Adicionar(nil);
    end),
    EValidacaoDominioIA);
end;

procedure TTestesArmazenamentoContextoIA.Contexto_DeveAdicionarPapeisConvenientes;
var
  LContexto: IContextoIA;
  LMensagens: TArray<IMensagemIA>;
begin
  LContexto := TContextoIA.Create(TArmazenamentoContextoIA.Create);
  LContexto.AdicionarSistema('instrucao');
  LContexto.AdicionarUsuario('pergunta');
  LContexto.AdicionarAssistente('resposta');
  LMensagens := LContexto.ObterMensagens;

  Assert.AreEqual(3, LContexto.Quantidade);
  Assert.AreEqual(Integer(TPapelMensagemIA.Sistema), Integer(LMensagens[0].Papel));
  Assert.AreEqual(Integer(TPapelMensagemIA.Usuario), Integer(LMensagens[1].Papel));
  Assert.AreEqual(Integer(TPapelMensagemIA.Assistente), Integer(LMensagens[2].Papel));

  LContexto.Limpar;
  Assert.AreEqual(0, LContexto.Quantidade);
end;

procedure TTestesArmazenamentoContextoIA.Contexto_NaoDeveAceitarArmazenamentoNulo;
begin
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TContextoIA.Create(nil).Free;
    end),
    EValidacaoDominioIA);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesArmazenamentoContextoIA);

end.
