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
  FMensagens.Add(AMensagem);
end;

procedure TArmazenamentoContextoIA.Limpar;
begin
  FMensagens.Clear;
end;

function TArmazenamentoContextoIA.ObterInstantaneo: TArray<IMensagemIA>;
begin
  Result := FMensagens.ToArray;
end;

function TArmazenamentoContextoIA.ObterQuantidade: Integer;
begin
  Result := FMensagens.Count;
end;

end.
