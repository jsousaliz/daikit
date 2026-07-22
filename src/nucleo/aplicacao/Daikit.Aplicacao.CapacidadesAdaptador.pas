unit Daikit.Aplicacao.CapacidadesAdaptador;

interface

{$SCOPEDENUMS ON}

uses
  Daikit.Aplicacao.Interfaces;

type
  TCapacidadeAdaptadorIA = (
    TextoSincrono,
    FluxoContinuo,
    Ferramentas,
    ImagemEntrada,
    SaidaEstruturada
  );

  TConjuntoCapacidadesAdaptadorIA = set of TCapacidadeAdaptadorIA;

  TCapacidadesAdaptadorIA = class(TInterfacedObject,
    ICapacidadesAdaptadorIA)
  private
    FCapacidadesAdaptador: TConjuntoCapacidadesAdaptadorIA;
  public
    constructor Create(
      ACapacidadesAdaptador: TConjuntoCapacidadesAdaptadorIA);
    class function SomenteTextoSincrono: ICapacidadesAdaptadorIA; static;
    function SuportaTextoSincrono: Boolean;
    function SuportaFluxoContinuo: Boolean;
    function SuportaFerramentas: Boolean;
    function SuportaImagemEntrada: Boolean;
    function SuportaSaidaEstruturada: Boolean;
  end;

implementation

constructor TCapacidadesAdaptadorIA.Create(
  ACapacidadesAdaptador: TConjuntoCapacidadesAdaptadorIA);
begin
  inherited Create;
  FCapacidadesAdaptador := ACapacidadesAdaptador;
end;

class function TCapacidadesAdaptadorIA.SomenteTextoSincrono:
  ICapacidadesAdaptadorIA;
begin
  Result := TCapacidadesAdaptadorIA.Create([
    TCapacidadeAdaptadorIA.TextoSincrono]);
end;

function TCapacidadesAdaptadorIA.SuportaFerramentas: Boolean;
begin
  Result := TCapacidadeAdaptadorIA.Ferramentas in FCapacidadesAdaptador;
end;

function TCapacidadesAdaptadorIA.SuportaFluxoContinuo: Boolean;
begin
  Result := TCapacidadeAdaptadorIA.FluxoContinuo in FCapacidadesAdaptador;
end;

function TCapacidadesAdaptadorIA.SuportaImagemEntrada: Boolean;
begin
  Result := TCapacidadeAdaptadorIA.ImagemEntrada in FCapacidadesAdaptador;
end;

function TCapacidadesAdaptadorIA.SuportaSaidaEstruturada: Boolean;
begin
  Result := TCapacidadeAdaptadorIA.SaidaEstruturada in FCapacidadesAdaptador;
end;

function TCapacidadesAdaptadorIA.SuportaTextoSincrono: Boolean;
begin
  Result := TCapacidadeAdaptadorIA.TextoSincrono in FCapacidadesAdaptador;
end;

end.
