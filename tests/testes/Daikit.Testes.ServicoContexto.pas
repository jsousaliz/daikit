unit Daikit.Testes.ServicoContexto;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesServicoContextoIA = class
  public
    [Test] procedure Servico_NaoDeveAceitarProvedorNulo;
    [Test] procedure Servico_NaoDeveAceitarContextoNulo;
    [Test] procedure EnviarMensagemIsolada_DeveEnviarSomenteMensagemAtual;
    [Test] procedure EnviarMantendoHistorico_DeveEnviarEPersistirHistorico;
    [Test] procedure EnviarCancelado_NaoDeveChamarProvedor;
    [Test] procedure RespostaNula_NaoDeveAlterarHistorico;
  end;

implementation

uses
  Daikit.Dominio.Excecoes,
  Daikit.Dominio.Interfaces,
  Daikit.Dominio.ArmazenamentoContexto,
  Daikit.Dominio.Contexto,
  Daikit.Aplicacao.Interfaces,
  Daikit.Aplicacao.TokenCancelamento,
  Daikit.Aplicacao.ServicoContexto,
  Daikit.Testes.AdaptadorFalso;

procedure TTestesServicoContextoIA.EnviarCancelado_NaoDeveChamarProvedor;
var
  LContexto: IContextoIA;
  LAdaptadorObjeto: TAdaptadorIAFalso;
  LAdaptador: IAdaptadorIA;
  LServico: TServicoContextoIA;
  LToken: ITokenCancelamentoIA;
begin
  LContexto := TContextoIA.Create(TArmazenamentoContextoIA.Create);
  LAdaptadorObjeto := TAdaptadorIAFalso.Create;
  LAdaptador := LAdaptadorObjeto;
  LServico := TServicoContextoIA.Create(LAdaptador, LContexto);
  try
    LToken := TTokenCancelamentoIA.Create;
    LToken.Cancelar;
    Assert.WillRaise(
      TTestLocalMethod(procedure
      begin
        LServico.Enviar('modelo', 'ola', TModoConversaIA.ManterHistorico, LToken);
      end),
      EOperacaoCanceladaIA);
    Assert.AreEqual(0, LAdaptadorObjeto.QuantidadeChamadas);
    Assert.AreEqual(0, LContexto.Quantidade);
  finally
    LServico.Free;
  end;
end;

procedure TTestesServicoContextoIA.EnviarMantendoHistorico_DeveEnviarEPersistirHistorico;
var
  LContexto: IContextoIA;
  LAdaptadorObjeto: TAdaptadorIAFalso;
  LAdaptador: IAdaptadorIA;
  LServico: TServicoContextoIA;
  LResposta: IRespostaChatIA;
begin
  LContexto := TContextoIA.Create(TArmazenamentoContextoIA.Create);
  LContexto.AdicionarSistema('seja breve');
  LAdaptadorObjeto := TAdaptadorIAFalso.Create('Eco: ');
  LAdaptador := LAdaptadorObjeto;
  LServico := TServicoContextoIA.Create(LAdaptador, LContexto);
  try
    LResposta := LServico.Enviar('modelo', 'primeira',
      TModoConversaIA.ManterHistorico);
    Assert.AreEqual('Eco: primeira', LResposta.Mensagem.Texto);
    Assert.AreEqual(2,
      Integer(Length(LAdaptadorObjeto.UltimaRequisicao.Mensagens)));
    Assert.AreEqual(3, LContexto.Quantidade);

    LServico.Enviar('modelo', 'segunda', TModoConversaIA.ManterHistorico);
    Assert.AreEqual(4,
      Integer(Length(LAdaptadorObjeto.UltimaRequisicao.Mensagens)));
    Assert.AreEqual(5, LContexto.Quantidade);
  finally
    LServico.Free;
  end;
end;

procedure TTestesServicoContextoIA.EnviarMensagemIsolada_DeveEnviarSomenteMensagemAtual;
var
  LContexto: IContextoIA;
  LAdaptadorObjeto: TAdaptadorIAFalso;
  LAdaptador: IAdaptadorIA;
  LServico: TServicoContextoIA;
  LResposta: IRespostaChatIA;
begin
  LContexto := TContextoIA.Create(TArmazenamentoContextoIA.Create);
  LContexto.AdicionarSistema('nao deve ser enviado');
  LAdaptadorObjeto := TAdaptadorIAFalso.Create;
  LAdaptador := LAdaptadorObjeto;
  LServico := TServicoContextoIA.Create(LAdaptador, LContexto);
  try
    LResposta := LServico.Enviar('modelo', 'pergunta',
      TModoConversaIA.MensagemIsolada);
    Assert.AreEqual('Resposta: pergunta', LResposta.Mensagem.Texto);
    Assert.AreEqual(1,
      Integer(Length(LAdaptadorObjeto.UltimaRequisicao.Mensagens)));
    Assert.AreEqual(1, LContexto.Quantidade);
  finally
    LServico.Free;
  end;
end;

procedure TTestesServicoContextoIA.RespostaNula_NaoDeveAlterarHistorico;
var
  LContexto: IContextoIA;
  LAdaptadorObjeto: TAdaptadorIAFalso;
  LAdaptador: IAdaptadorIA;
  LServico: TServicoContextoIA;
begin
  LContexto := TContextoIA.Create(TArmazenamentoContextoIA.Create);
  LAdaptadorObjeto := TAdaptadorIAFalso.Create;
  LAdaptadorObjeto.RetornarNulo := True;
  LAdaptador := LAdaptadorObjeto;
  LServico := TServicoContextoIA.Create(LAdaptador, LContexto);
  try
    Assert.WillRaise(
      TTestLocalMethod(procedure
      begin
        LServico.Enviar('modelo', 'ola', TModoConversaIA.ManterHistorico);
      end),
      EValidacaoDominioIA);
    Assert.AreEqual(0, LContexto.Quantidade);
  finally
    LServico.Free;
  end;
end;

procedure TTestesServicoContextoIA.Servico_NaoDeveAceitarContextoNulo;
var
  LAdaptador: IAdaptadorIA;
begin
  LAdaptador := TAdaptadorIAFalso.Create;
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TServicoContextoIA.Create(LAdaptador, nil).Free;
    end),
    EValidacaoDominioIA);
end;

procedure TTestesServicoContextoIA.Servico_NaoDeveAceitarProvedorNulo;
var
  LContexto: IContextoIA;
begin
  LContexto := TContextoIA.Create(TArmazenamentoContextoIA.Create);
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TServicoContextoIA.Create(nil, LContexto).Free;
    end),
    EValidacaoDominioIA);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesServicoContextoIA);

end.
