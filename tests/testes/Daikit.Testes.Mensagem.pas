unit Daikit.Testes.Mensagem;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesMensagemIA = class
  public
    [Test] procedure ParteTexto_DeveExporTipoETexto;
    [Test] procedure ParteTexto_NaoDeveAceitarVazio;
    [Test] procedure Mensagem_DevePreservarDadosEPartes;
    [Test] procedure Mensagem_DeveConcatenarPartesTextuais;
    [Test] procedure Mensagem_NaoDeveAceitarPartesAusentes;
    [Test] procedure Mensagem_NaoDeveAceitarParteNula;
    [Test] procedure Mensagem_DeveProtegerColecaoInterna;
  end;

implementation

uses
  Daikit.Dominio.Excecoes,
  Daikit.Dominio.Interfaces,
  Daikit.Dominio.Mensagem;

procedure TTestesMensagemIA.Mensagem_DeveConcatenarPartesTextuais;
var
  LPartes: TArray<IParteConteudoIA>;
  LMensagem: IMensagemIA;
begin
  SetLength(LPartes, 2);
  LPartes[0] := TParteConteudoTextoIA.Create('Ola, ');
  LPartes[1] := TParteConteudoTextoIA.Create('mundo');
  LMensagem := TMensagemIA.Create(TPapelMensagemIA.Assistente, LPartes);

  Assert.AreEqual('Ola, mundo', LMensagem.Texto);
end;

procedure TTestesMensagemIA.Mensagem_DevePreservarDadosEPartes;
var
  LMensagem: IMensagemIA;
begin
  LMensagem := TMensagemIA.CriarTexto(TPapelMensagemIA.Ferramenta,
    'resultado', 'calculadora', 'chamada-1');

  Assert.AreEqual(Integer(TPapelMensagemIA.Ferramenta),
    Integer(LMensagem.Papel));
  Assert.AreEqual('resultado', LMensagem.Texto);
  Assert.AreEqual('calculadora', LMensagem.Nome);
  Assert.AreEqual('chamada-1', LMensagem.IdCorrelacao);
  Assert.AreEqual(1, Integer(Length(LMensagem.Partes)));
end;

procedure TTestesMensagemIA.Mensagem_DeveProtegerColecaoInterna;
var
  LMensagem: IMensagemIA;
  LPartes: TArray<IParteConteudoIA>;
begin
  LMensagem := TMensagemIA.CriarTexto(TPapelMensagemIA.Usuario, 'texto');
  LPartes := LMensagem.Partes;
  LPartes[0] := nil;

  Assert.AreEqual('texto', LMensagem.Texto);
end;

procedure TTestesMensagemIA.Mensagem_NaoDeveAceitarParteNula;
var
  LPartes: TArray<IParteConteudoIA>;
begin
  SetLength(LPartes, 1);
  LPartes[0] := nil;
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TMensagemIA.Create(TPapelMensagemIA.Usuario, LPartes).Free;
    end),
    EValidacaoDominioIA);
end;

procedure TTestesMensagemIA.Mensagem_NaoDeveAceitarPartesAusentes;
var
  LPartes: TArray<IParteConteudoIA>;
begin
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TMensagemIA.Create(TPapelMensagemIA.Usuario, LPartes).Free;
    end),
    EValidacaoDominioIA);
end;

procedure TTestesMensagemIA.ParteTexto_DeveExporTipoETexto;
var
  LParte: IParteConteudoIA;
begin
  LParte := TParteConteudoTextoIA.Create('conteudo');
  Assert.AreEqual(Integer(TTipoParteConteudoIA.Texto), Integer(LParte.Tipo));
  Assert.AreEqual('conteudo', LParte.Texto);
end;

procedure TTestesMensagemIA.ParteTexto_NaoDeveAceitarVazio;
begin
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TParteConteudoTextoIA.Create('  ').Free;
    end),
    EValidacaoDominioIA);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesMensagemIA);

end.
