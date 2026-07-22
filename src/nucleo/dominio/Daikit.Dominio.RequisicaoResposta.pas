unit Daikit.Dominio.RequisicaoResposta;

interface

uses
  Daikit.Dominio.Interfaces;

type
  TUsoIA = class(TInterfacedObject, IUsoIA)
  private
    FUnidadesEntrada: Int64;
    FUnidadesSaida: Int64;
    function ObterUnidadesEntrada: Int64;
    function ObterUnidadesSaida: Int64;
    function ObterUnidadesTotal: Int64;
  public
    constructor Create(AUnidadesEntrada, AUnidadesSaida: Int64);
  end;

  TRequisicaoChatIA = class(TInterfacedObject, IRequisicaoChatIA)
  private
    FModelo: string;
    FMensagens: TArray<IMensagemIA>;
    function ObterModelo: string;
    function ObterMensagens: TArray<IMensagemIA>;
  public
    constructor Create(const AModelo: string;
      const AMensagens: TArray<IMensagemIA>);
  end;

  TRespostaChatIA = class(TInterfacedObject, IRespostaChatIA)
  private
    FId: string;
    FMensagem: IMensagemIA;
    FUso: IUsoIA;
    function ObterId: string;
    function ObterMensagem: IMensagemIA;
    function ObterUso: IUsoIA;
  public
    constructor Create(const AId: string; const AMensagem: IMensagemIA;
      const AUso: IUsoIA = nil);
  end;

implementation

uses
  Daikit.Dominio.Constantes,
  Daikit.Dominio.Excecoes;

{ TUsoIA }

constructor TUsoIA.Create(AUnidadesEntrada, AUnidadesSaida: Int64);
begin
  inherited Create;
  if AUnidadesEntrada < CQuantidadeMinimaUnidadesIA then
    raise EValidacaoDominioIA.Create('As unidades de entrada nao podem ser negativas.');
  if AUnidadesSaida < CQuantidadeMinimaUnidadesIA then
    raise EValidacaoDominioIA.Create('As unidades de saida nao podem ser negativas.');
  FUnidadesEntrada := AUnidadesEntrada;
  FUnidadesSaida := AUnidadesSaida;
end;

function TUsoIA.ObterUnidadesEntrada: Int64;
begin
  Result := FUnidadesEntrada;
end;

function TUsoIA.ObterUnidadesSaida: Int64;
begin
  Result := FUnidadesSaida;
end;

function TUsoIA.ObterUnidadesTotal: Int64;
begin
  Result := FUnidadesEntrada + FUnidadesSaida;
end;

{ TRequisicaoChatIA }

constructor TRequisicaoChatIA.Create(const AModelo: string;
  const AMensagens: TArray<IMensagemIA>);
var
  I: Integer;
begin
  inherited Create;
  if Length(AMensagens) < CQuantidadeMinimaMensagensRequisicao then
    raise EValidacaoDominioIA.Create('A requisicao deve possuir ao menos uma mensagem.');

  SetLength(FMensagens, Length(AMensagens));
  for I := Low(AMensagens) to High(AMensagens) do
  begin
    if AMensagens[I] = nil then
      raise EValidacaoDominioIA.CreateFmt(
        'A mensagem no indice %d da requisicao nao foi informada.', [I]);
    FMensagens[I] := AMensagens[I];
  end;
  FModelo := AModelo;
end;

function TRequisicaoChatIA.ObterMensagens: TArray<IMensagemIA>;
begin
  Result := Copy(FMensagens);
end;

function TRequisicaoChatIA.ObterModelo: string;
begin
  Result := FModelo;
end;

{ TRespostaChatIA }

constructor TRespostaChatIA.Create(const AId: string;
  const AMensagem: IMensagemIA; const AUso: IUsoIA);
begin
  inherited Create;
  if AMensagem = nil then
    raise EValidacaoDominioIA.Create('A mensagem da resposta deve ser informada.');
  FId := AId;
  FMensagem := AMensagem;
  FUso := AUso;
end;

function TRespostaChatIA.ObterId: string;
begin
  Result := FId;
end;

function TRespostaChatIA.ObterMensagem: IMensagemIA;
begin
  Result := FMensagem;
end;

function TRespostaChatIA.ObterUso: IUsoIA;
begin
  Result := FUso;
end;

end.
