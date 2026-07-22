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
  LFonteChaveAPI: IFonteChaveAPI;
begin
  LFonteChaveAPI := TFonteChaveAPIAmbiente.Create(CVariavelInexistente);
  Assert.AreEqual('', LFonteChaveAPI.ObterChaveAPI);
end;

procedure TTestesAdaptadores.FonteMemoria_DevePreservarChave;
const
  CChave = 'chave-compartilhada-de-teste';
var
  LFonteChaveAPI: IFonteChaveAPI;
begin
  LFonteChaveAPI := TFonteChaveAPIMemoria.Create(CChave);
  Assert.AreEqual(CChave, LFonteChaveAPI.ObterChaveAPI);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesAdaptadores);

end.
