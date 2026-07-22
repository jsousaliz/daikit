unit Daikit.Infraestrutura.HTTP.FluxoLimitado;

interface

uses
  System.Classes;

type
  TFluxoRespostaLimitado = class(TMemoryStream)
  private
    FLimiteBytes: Int64;
    procedure VerificarLimite(ACount: NativeInt);
  public
    constructor Create(ALimiteBytes: Int64);
{$IF Sizeof(LongInt) <> Sizeof(NativeInt)}
    function Write(const Buffer; Count: Longint): Longint; override;
{$ENDIF}
    function Write(const Buffer; Count: TNativeCount): TNativeCount; override;
  end;

implementation

uses
  Daikit.Infraestrutura.HTTP.Excecoes;

constructor TFluxoRespostaLimitado.Create(ALimiteBytes: Int64);
begin
  inherited Create;
  if ALimiteBytes <= 0 then
    raise EValidacaoHTTP.Create('O limite do fluxo deve ser maior que zero.');
  FLimiteBytes := ALimiteBytes;
end;

procedure TFluxoRespostaLimitado.VerificarLimite(ACount: NativeInt);
begin
  if (ACount > 0) and (Position + ACount > FLimiteBytes) then
    raise ELimiteRespostaHTTP.Create('A resposta HTTP excedeu o limite permitido.');
end;

{$IF Sizeof(LongInt) <> Sizeof(NativeInt)}
function TFluxoRespostaLimitado.Write(const Buffer;
  Count: Longint): Longint;
begin
  VerificarLimite(Count);
  Result := inherited Write(Buffer, Count);
end;
{$ENDIF}

function TFluxoRespostaLimitado.Write(const Buffer;
  Count: TNativeCount): TNativeCount;
begin
  VerificarLimite(Count);
  Result := inherited Write(Buffer, Count);
end;

end.
