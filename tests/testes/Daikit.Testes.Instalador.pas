unit Daikit.Testes.Instalador;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesInstalador = class
  public
    [Test] procedure AdicionarCaminho_DevePreservarConfiguracaoExistente;
    [Test] procedure AdicionarCaminho_NaoDeveDuplicarEntrada;
    [Test] procedure AdicionarCaminho_DevePreservarEspacosSemAspas;
    [Test] procedure RemoverCaminho_DeveRemoverSomenteDaikit;
  end;

implementation

uses
  System.SysUtils,
  Daikit.Instalador.Servico;

const
  CAMINHO_PADRAO = '$(BDSLIB)\$(Platform)\release';
  CAMINHO_DAIKIT = '$(BDSCOMMONDIR)\Dcp\Daikit\Win32';

procedure TTestesInstalador.AdicionarCaminho_DevePreservarConfiguracaoExistente;
begin
  Assert.AreEqual(CAMINHO_PADRAO + ';' + CAMINHO_DAIKIT,
    TServicoInstalacaoDaikit.AdicionarCaminhoPesquisa(
      CAMINHO_PADRAO, CAMINHO_DAIKIT));
end;

procedure TTestesInstalador.AdicionarCaminho_DevePreservarEspacosSemAspas;
begin
  Assert.AreEqual('C:\Bibliotecas Delphi;' + CAMINHO_DAIKIT,
    TServicoInstalacaoDaikit.AdicionarCaminhoPesquisa(
      'C:\Bibliotecas Delphi', CAMINHO_DAIKIT));
end;
procedure TTestesInstalador.AdicionarCaminho_NaoDeveDuplicarEntrada;
begin
  Assert.AreEqual(CAMINHO_PADRAO + ';' + CAMINHO_DAIKIT,
    TServicoInstalacaoDaikit.AdicionarCaminhoPesquisa(
      CAMINHO_PADRAO + ';' + CAMINHO_DAIKIT, LowerCase(CAMINHO_DAIKIT)));
end;

procedure TTestesInstalador.RemoverCaminho_DeveRemoverSomenteDaikit;
begin
  Assert.AreEqual(CAMINHO_PADRAO,
    TServicoInstalacaoDaikit.RemoverCaminhoPesquisa(
      CAMINHO_PADRAO + ';' + CAMINHO_DAIKIT, CAMINHO_DAIKIT));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesInstalador);

end.
