unit Daikit.Testes.Adaptadores;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesAdaptadores = class
  public
    [Test] procedure FonteMemoria_DevePreservarChave;
    [Test] procedure FonteAmbiente_DevePermitirNomeConfiguravel;
    [Test] procedure FonteAmbiente_DeveExigirNome;
  end;

implementation

uses
  System.SysUtils,
  Daikit.Adaptadores.Interfaces,
  Daikit.Adaptadores.ChaveAPI;

procedure TTestesAdaptadores.FonteAmbiente_DeveExigirNome;
begin
  Assert.WillRaise(
    procedure
    begin
      TFonteChaveAPIAmbiente.Create('');
    end,
    EArgumentException);
end;

procedure TTestesAdaptadores.FonteAmbiente_DevePermitirNomeConfiguravel;
const
  CVariavelInexistente = 'DAIKIT_TESTE_VARIAVEL_INEXISTENTE_98F1';
var
  LFonte: IFonteChaveAPI;
begin
  LFonte := TFonteChaveAPIAmbiente.Create(CVariavelInexistente);
  Assert.AreEqual('', LFonte.ObterChaveAPI);
end;

procedure TTestesAdaptadores.FonteMemoria_DevePreservarChave;
const
  CChave = 'chave-compartilhada-de-teste';
var
  LFonte: IFonteChaveAPI;
begin
  LFonte := TFonteChaveAPIMemoria.Create(CChave);
  Assert.AreEqual(CChave, LFonte.ObterChaveAPI);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesAdaptadores);

end.
