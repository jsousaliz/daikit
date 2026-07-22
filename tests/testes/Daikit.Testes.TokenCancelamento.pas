unit Daikit.Testes.TokenCancelamento;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestesTokenCancelamentoIA = class
  public
    [Test] procedure Token_DeveIniciarNaoCancelado;
    [Test] procedure Token_DeveRegistrarCancelamento;
  end;

implementation

uses
  Daikit.Aplicacao.Interfaces,
  Daikit.Aplicacao.TokenCancelamento;

procedure TTestesTokenCancelamentoIA.Token_DeveIniciarNaoCancelado;
var
  LToken: ITokenCancelamentoIA;
begin
  LToken := TTokenCancelamentoIA.Create;
  Assert.IsFalse(LToken.FoiCancelado);
end;

procedure TTestesTokenCancelamentoIA.Token_DeveRegistrarCancelamento;
var
  LToken: ITokenCancelamentoIA;
begin
  LToken := TTokenCancelamentoIA.Create;
  LToken.Cancelar;
  Assert.IsTrue(LToken.FoiCancelado);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestesTokenCancelamentoIA);

end.
