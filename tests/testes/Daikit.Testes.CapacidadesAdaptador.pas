unit Daikit.Testes.CapacidadesAdaptador;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesCapacidadesAdaptadorIA = class
  public
    [Test] procedure SomenteTextoSincrono_DeveExporApenasCapacidadeImplementada;
    [Test] procedure Capacidades_DevePreservarConfiguracaoInformada;
  end;

implementation

uses
  Daikit.Aplicacao.Interfaces,
  Daikit.Aplicacao.CapacidadesAdaptador;

procedure TTestesCapacidadesAdaptadorIA.Capacidades_DevePreservarConfiguracaoInformada;
var
  LCapacidades: ICapacidadesAdaptadorIA;
begin
  LCapacidades := TCapacidadesAdaptadorIA.Create(False, True, True, True,
    True);
  Assert.IsFalse(LCapacidades.SuportaTextoSincrono);
  Assert.IsTrue(LCapacidades.SuportaFluxoContinuo);
  Assert.IsTrue(LCapacidades.SuportaFerramentas);
  Assert.IsTrue(LCapacidades.SuportaImagemEntrada);
  Assert.IsTrue(LCapacidades.SuportaSaidaEstruturada);
end;

procedure TTestesCapacidadesAdaptadorIA.SomenteTextoSincrono_DeveExporApenasCapacidadeImplementada;
var
  LCapacidades: ICapacidadesAdaptadorIA;
begin
  LCapacidades := TCapacidadesAdaptadorIA.SomenteTextoSincrono;
  Assert.IsTrue(LCapacidades.SuportaTextoSincrono);
  Assert.IsFalse(LCapacidades.SuportaFluxoContinuo);
  Assert.IsFalse(LCapacidades.SuportaFerramentas);
  Assert.IsFalse(LCapacidades.SuportaImagemEntrada);
  Assert.IsFalse(LCapacidades.SuportaSaidaEstruturada);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesCapacidadesAdaptadorIA);

end.
