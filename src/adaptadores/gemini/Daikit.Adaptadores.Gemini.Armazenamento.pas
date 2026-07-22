unit Daikit.Adaptadores.Gemini.Armazenamento;

interface

uses
  System.Generics.Collections,
  Daikit.Adaptadores.Gemini.Interfaces;

type
  TArmazenamentoContextoGemini = class(TInterfacedObject,
    IArmazenamentoContextoGemini)
  private
    FContextos: TDictionary<string, string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Guardar(const AIdCorrelacao, AContextoJSON: string);
    function TentarObter(const AIdCorrelacao: string;
      out AContextoJSON: string): Boolean;
    procedure Remover(const AIdCorrelacao: string);
    procedure Limpar;
    function ObterQuantidade: Integer;
  end;

implementation

uses
  System.SysUtils,
  Daikit.Adaptadores.Gemini.Excecoes;

constructor TArmazenamentoContextoGemini.Create;
begin
  inherited Create;
  FContextos := TDictionary<string, string>.Create;
end;

destructor TArmazenamentoContextoGemini.Destroy;
begin
  FContextos.Free;
  inherited;
end;

procedure TArmazenamentoContextoGemini.Guardar(const AIdCorrelacao,
  AContextoJSON: string);
begin
  if Trim(AIdCorrelacao) = '' then
    raise EContratoGemini.Create(
      'O identificador do contexto Gemini deve ser informado.');
  if Trim(AContextoJSON) = '' then
    raise EContratoGemini.Create('O contexto Gemini deve ser informado.');
  TMonitor.Enter(Self);
  try
    FContextos.AddOrSetValue(AIdCorrelacao, AContextoJSON);
  finally
    TMonitor.Exit(Self);
  end;
end;

function TArmazenamentoContextoGemini.TentarObter(
  const AIdCorrelacao: string; out AContextoJSON: string): Boolean;
begin
  TMonitor.Enter(Self);
  try
    Result := FContextos.TryGetValue(AIdCorrelacao, AContextoJSON);
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TArmazenamentoContextoGemini.Remover(
  const AIdCorrelacao: string);
begin
  TMonitor.Enter(Self);
  try
    FContextos.Remove(AIdCorrelacao);
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TArmazenamentoContextoGemini.Limpar;
begin
  TMonitor.Enter(Self);
  try
    FContextos.Clear;
  finally
    TMonitor.Exit(Self);
  end;
end;

function TArmazenamentoContextoGemini.ObterQuantidade: Integer;
begin
  TMonitor.Enter(Self);
  try
    Result := FContextos.Count;
  finally
    TMonitor.Exit(Self);
  end;
end;

end.
