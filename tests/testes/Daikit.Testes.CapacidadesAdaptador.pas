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
  LCapacidadesAdaptador: ICapacidadesAdaptadorIA;
begin
  LCapacidadesAdaptador := TCapacidadesAdaptadorIA.Create([
    TCapacidadeAdaptadorIA.FluxoContinuo,
    TCapacidadeAdaptadorIA.Ferramentas,
    TCapacidadeAdaptadorIA.ImagemEntrada,
    TCapacidadeAdaptadorIA.SaidaEstruturada]);
  Assert.IsFalse(LCapacidadesAdaptador.SuportaTextoSincrono);
  Assert.IsTrue(LCapacidadesAdaptador.SuportaFluxoContinuo);
  Assert.IsTrue(LCapacidadesAdaptador.SuportaFerramentas);
  Assert.IsTrue(LCapacidadesAdaptador.SuportaImagemEntrada);
  Assert.IsTrue(LCapacidadesAdaptador.SuportaSaidaEstruturada);
end;

procedure TTestesCapacidadesAdaptadorIA.SomenteTextoSincrono_DeveExporApenasCapacidadeImplementada;
var
  LCapacidadesAdaptador: ICapacidadesAdaptadorIA;
begin
  LCapacidadesAdaptador := TCapacidadesAdaptadorIA.SomenteTextoSincrono;
  Assert.IsTrue(LCapacidadesAdaptador.SuportaTextoSincrono);
  Assert.IsFalse(LCapacidadesAdaptador.SuportaFluxoContinuo);
  Assert.IsFalse(LCapacidadesAdaptador.SuportaFerramentas);
  Assert.IsFalse(LCapacidadesAdaptador.SuportaImagemEntrada);
  Assert.IsFalse(LCapacidadesAdaptador.SuportaSaidaEstruturada);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesCapacidadesAdaptadorIA);

end.
