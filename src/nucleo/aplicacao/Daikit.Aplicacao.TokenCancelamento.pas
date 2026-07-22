unit Daikit.Aplicacao.TokenCancelamento;

interface

uses
  Daikit.Aplicacao.Interfaces;

type
  TTokenCancelamentoIA = class(TInterfacedObject, ITokenCancelamentoIA)
  private
    FCancelado: Integer;
  public
    procedure Cancelar;
    function FoiCancelado: Boolean;
  end;

implementation

uses
  System.SyncObjs,
  Daikit.Aplicacao.Constantes;

procedure TTokenCancelamentoIA.Cancelar;
begin
  TInterlocked.Exchange(FCancelado, CEstadoCancelamentoSolicitado);
end;

function TTokenCancelamentoIA.FoiCancelado: Boolean;
begin
  Result := TInterlocked.CompareExchange(FCancelado,
    CEstadoCancelamentoNaoSolicitado,
    CEstadoCancelamentoNaoSolicitado) <> CEstadoCancelamentoNaoSolicitado;
end;

end.
