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
  LPartesConteudo: TArray<IParteConteudoIA>;
  LMensagem: IMensagemIA;
begin
  SetLength(LPartesConteudo, 2);
  LPartesConteudo[0] := TParteConteudoTextoIA.Create('Ola, ');
  LPartesConteudo[1] := TParteConteudoTextoIA.Create('mundo');
  LMensagem := TMensagemIA.Create(TPapelMensagemIA.Assistente, LPartesConteudo);

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
  LPartesConteudo: TArray<IParteConteudoIA>;
begin
  LMensagem := TMensagemIA.CriarTexto(TPapelMensagemIA.Usuario, 'texto');
  LPartesConteudo := LMensagem.Partes;
  LPartesConteudo[0] := nil;

  Assert.AreEqual('texto', LMensagem.Texto);
end;

procedure TTestesMensagemIA.Mensagem_NaoDeveAceitarParteNula;
var
  LPartesConteudo: TArray<IParteConteudoIA>;
begin
  SetLength(LPartesConteudo, 1);
  LPartesConteudo[0] := nil;
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TMensagemIA.Create(TPapelMensagemIA.Usuario, LPartesConteudo).Free;
    end),
    EValidacaoDominioIA);
end;

procedure TTestesMensagemIA.Mensagem_NaoDeveAceitarPartesAusentes;
var
  LPartesConteudo: TArray<IParteConteudoIA>;
begin
  Assert.WillRaise(
    TTestLocalMethod(procedure
    begin
      TMensagemIA.Create(TPapelMensagemIA.Usuario, LPartesConteudo).Free;
    end),
    EValidacaoDominioIA);
end;

procedure TTestesMensagemIA.ParteTexto_DeveExporTipoETexto;
var
  LParteConteudo: IParteConteudoIA;
begin
  LParteConteudo := TParteConteudoTextoIA.Create('conteudo');
  Assert.AreEqual(Integer(TTipoParteConteudoIA.Texto), Integer(LParteConteudo.Tipo));
  Assert.AreEqual('conteudo', LParteConteudo.Texto);
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
