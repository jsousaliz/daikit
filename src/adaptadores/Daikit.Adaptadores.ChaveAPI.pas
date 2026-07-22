unit Daikit.Adaptadores.ChaveAPI;

interface

uses
  Daikit.Adaptadores.Interfaces;

type
  TFonteChaveAPIMemoria = class(TInterfacedObject, IFonteChaveAPI)
  private
    FChaveAPI: string;
  public
    constructor Create(const AChaveAPI: string);
    function ObterChaveAPI: string;
  end;

  TFonteChaveAPIAmbiente = class(TInterfacedObject, IFonteChaveAPI)
  private
    FNomeVariavel: string;
  public
    constructor Create(const ANomeVariavel: string);
    function ObterChaveAPI: string;
  end;

implementation

uses
  System.SysUtils;

constructor TFonteChaveAPIMemoria.Create(const AChaveAPI: string);
begin
  inherited Create;
  FChaveAPI := AChaveAPI;
end;

function TFonteChaveAPIMemoria.ObterChaveAPI: string;
begin
  Result := FChaveAPI;
end;

constructor TFonteChaveAPIAmbiente.Create(const ANomeVariavel: string);
begin
  inherited Create;
  if Trim(ANomeVariavel) = '' then
    raise EArgumentException.Create(
      'O nome da variavel de ambiente da chave da API deve ser informado.');
  FNomeVariavel := ANomeVariavel;
end;

function TFonteChaveAPIAmbiente.ObterChaveAPI: string;
begin
  Result := GetEnvironmentVariable(FNomeVariavel);
end;

end.
