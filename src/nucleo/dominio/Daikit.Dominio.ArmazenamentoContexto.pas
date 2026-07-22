unit Daikit.Dominio.ArmazenamentoContexto;

interface

uses
  System.Generics.Collections,
  Daikit.Dominio.Interfaces;

type
  TArmazenamentoContextoIA = class(TInterfacedObject,
    IArmazenamentoContextoIA)
  private
    FMensagens: TList<IMensagemIA>;
    function ObterQuantidade: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Adicionar(const AMensagem: IMensagemIA);
    function ObterInstantaneo: TArray<IMensagemIA>;
    procedure Limpar;
  end;

implementation

uses
  Daikit.Dominio.Excecoes;

constructor TArmazenamentoContextoIA.Create;
begin
  inherited Create;
  FMensagens := TList<IMensagemIA>.Create;
end;

destructor TArmazenamentoContextoIA.Destroy;
begin
  FMensagens.Free;
  inherited;
end;

procedure TArmazenamentoContextoIA.Adicionar(
  const AMensagem: IMensagemIA);
begin
  if AMensagem = nil then
    raise EValidacaoDominioIA.Create('A mensagem armazenada nao pode ser nula.');
  TMonitor.Enter(Self);
  try
    FMensagens.Add(AMensagem);
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TArmazenamentoContextoIA.Limpar;
begin
  TMonitor.Enter(Self);
  try
    FMensagens.Clear;
  finally
    TMonitor.Exit(Self);
  end;
end;

function TArmazenamentoContextoIA.ObterInstantaneo: TArray<IMensagemIA>;
begin
  TMonitor.Enter(Self);
  try
    Result := FMensagens.ToArray;
  finally
    TMonitor.Exit(Self);
  end;
end;

function TArmazenamentoContextoIA.ObterQuantidade: Integer;
begin
  TMonitor.Enter(Self);
  try
    Result := FMensagens.Count;
  finally
    TMonitor.Exit(Self);
  end;
end;

end.
