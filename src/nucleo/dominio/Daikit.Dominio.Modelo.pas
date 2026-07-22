unit Daikit.Dominio.Modelo;

interface

uses
  Daikit.Dominio.Interfaces;

type
  TModeloIA = class(TInterfacedObject, IModeloIA)
  private
    FId: string;
    FNome: string;
    function ObterId: string;
    function ObterNome: string;
  public
    constructor Create(const AId, ANome: string);
  end;

implementation

uses
  System.SysUtils,
  Daikit.Dominio.Excecoes;

constructor TModeloIA.Create(const AId, ANome: string);
begin
  inherited Create;
  if Trim(AId) = '' then
    raise EValidacaoDominioIA.Create(
      'O identificador do modelo deve ser informado.');
  FId := AId;
  FNome := ANome;
  if Trim(FNome) = '' then
    FNome := FId;
end;

function TModeloIA.ObterId: string;
begin
  Result := FId;
end;

function TModeloIA.ObterNome: string;
begin
  Result := FNome;
end;

end.
