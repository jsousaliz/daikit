unit Daikit.Aplicacao.CapacidadesAdaptador;

interface

uses
  Daikit.Aplicacao.Interfaces;

type
  TCapacidadesAdaptadorIA = class(TInterfacedObject,
    ICapacidadesAdaptadorIA)
  private
    FTextoSincrono: Boolean;
    FFluxoContinuo: Boolean;
    FFerramentas: Boolean;
    FImagemEntrada: Boolean;
    FSaidaEstruturada: Boolean;
  public
    constructor Create(ATextoSincrono, AFluxoContinuo, AFerramentas,
      AImagemEntrada, ASaidaEstruturada: Boolean);
    class function SomenteTextoSincrono: ICapacidadesAdaptadorIA; static;
    function SuportaTextoSincrono: Boolean;
    function SuportaFluxoContinuo: Boolean;
    function SuportaFerramentas: Boolean;
    function SuportaImagemEntrada: Boolean;
    function SuportaSaidaEstruturada: Boolean;
  end;

implementation

constructor TCapacidadesAdaptadorIA.Create(ATextoSincrono, AFluxoContinuo,
  AFerramentas, AImagemEntrada, ASaidaEstruturada: Boolean);
begin
  inherited Create;
  FTextoSincrono := ATextoSincrono;
  FFluxoContinuo := AFluxoContinuo;
  FFerramentas := AFerramentas;
  FImagemEntrada := AImagemEntrada;
  FSaidaEstruturada := ASaidaEstruturada;
end;

class function TCapacidadesAdaptadorIA.SomenteTextoSincrono:
  ICapacidadesAdaptadorIA;
begin
  Result := TCapacidadesAdaptadorIA.Create(True, False, False, False, False);
end;

function TCapacidadesAdaptadorIA.SuportaFerramentas: Boolean;
begin
  Result := FFerramentas;
end;

function TCapacidadesAdaptadorIA.SuportaFluxoContinuo: Boolean;
begin
  Result := FFluxoContinuo;
end;

function TCapacidadesAdaptadorIA.SuportaImagemEntrada: Boolean;
begin
  Result := FImagemEntrada;
end;

function TCapacidadesAdaptadorIA.SuportaSaidaEstruturada: Boolean;
begin
  Result := FSaidaEstruturada;
end;

function TCapacidadesAdaptadorIA.SuportaTextoSincrono: Boolean;
begin
  Result := FTextoSincrono;
end;

end.
