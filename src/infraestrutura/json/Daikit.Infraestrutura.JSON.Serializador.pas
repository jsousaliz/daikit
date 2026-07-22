unit Daikit.Infraestrutura.JSON.Serializador;

interface

uses
  REST.Json,
  Daikit.Infraestrutura.JSON.Constantes;

type
  TSerializadorJSON = class sealed
  public
    class function Serializar(AObjeto: TObject): string; overload; static;
    class function Serializar(AObjeto: TObject;
      AOpcoes: TJsonOptions): string; overload; static;
    class function Desserializar<T: class, constructor>(
      const AJSON: string): T; overload; static;
    class function Desserializar<T: class, constructor>(const AJSON: string;
      AOpcoes: TJsonOptions): T; overload; static;
  end;

implementation

uses
  System.SysUtils,
  Daikit.Infraestrutura.JSON.Excecoes;

class function TSerializadorJSON.Desserializar<T>(const AJSON: string;
  AOpcoes: TJsonOptions): T;
begin
  if Trim(AJSON) = '' then
    raise ESerializacaoJSON.Create('O JSON para desserializacao deve ser informado.');
  try
    Result := TJson.JsonToObject<T>(AJSON, AOpcoes);
    if Result = nil then
      raise ESerializacaoJSON.Create('O JSON nao produziu um objeto.');
  except
    on E: ESerializacaoJSON do
      raise;
    on E: Exception do
    begin
      raise ESerializacaoJSON.CreateFmt(
        'Falha ao desserializar JSON (%s).', [E.ClassName]);
    end;
  end;
end;

class function TSerializadorJSON.Desserializar<T>(const AJSON: string): T;
begin
  Result := Desserializar<T>(AJSON, COpcoesJSONPadrao);
end;

class function TSerializadorJSON.Serializar(AObjeto: TObject): string;
begin
  Result := Serializar(AObjeto, COpcoesJSONPadrao);
end;

class function TSerializadorJSON.Serializar(AObjeto: TObject;
  AOpcoes: TJsonOptions): string;
begin
  if AObjeto = nil then
    raise ESerializacaoJSON.Create('O objeto para serializacao deve ser informado.');
  try
    Result := TJson.ObjectToJsonString(AObjeto, AOpcoes);
  except
    on E: Exception do
      raise ESerializacaoJSON.CreateFmt(
        'Falha ao serializar objeto (%s).', [E.ClassName]);
  end;
end;

end.
