unit Daikit.Dominio.Mensagem;

interface

uses
  Daikit.Dominio.Interfaces;

type
  TParteConteudoTextoIA = class(TInterfacedObject, IParteConteudoIA)
  private
    FTexto: string;
    function ObterTipo: TTipoParteConteudoIA;
    function ObterTexto: string;
  public
    constructor Create(const ATexto: string);
  end;

  TMensagemIA = class(TInterfacedObject, IMensagemIA)
  private
    FPapelMensagem: TPapelMensagemIA;
    FPartesConteudo: TArray<IParteConteudoIA>;
    FNome: string;
    FIdCorrelacao: string;
    function ObterPapel: TPapelMensagemIA;
    function ObterPartes: TArray<IParteConteudoIA>;
    function ObterTexto: string;
    function ObterNome: string;
    function ObterIdCorrelacao: string;
  public
    constructor Create(APapel: TPapelMensagemIA;
      const APartes: TArray<IParteConteudoIA>; const ANome: string = '';
      const AIdCorrelacao: string = '');
    class function CriarTexto(APapel: TPapelMensagemIA;
      const ATexto: string; const ANome: string = '';
      const AIdCorrelacao: string = ''): IMensagemIA; static;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  Daikit.Dominio.Constantes,
  Daikit.Dominio.Excecoes;

{ TParteConteudoTextoIA }

constructor TParteConteudoTextoIA.Create(const ATexto: string);
begin
  inherited Create;
  if Trim(ATexto) = '' then
    raise EValidacaoDominioIA.Create('O texto da parte de conteudo nao pode ser vazio.');
  FTexto := ATexto;
end;

function TParteConteudoTextoIA.ObterTexto: string;
begin
  Result := FTexto;
end;

function TParteConteudoTextoIA.ObterTipo: TTipoParteConteudoIA;
begin
  Result := TTipoParteConteudoIA.Texto;
end;

{ TMensagemIA }

constructor TMensagemIA.Create(APapel: TPapelMensagemIA;
  const APartes: TArray<IParteConteudoIA>; const ANome,
  AIdCorrelacao: string);
var
  I: Integer;
begin
  inherited Create;
  if Length(APartes) < CQuantidadeMinimaPartesMensagem then
    raise EValidacaoDominioIA.Create('A mensagem deve possuir ao menos uma parte de conteudo.');

  SetLength(FPartesConteudo, Length(APartes));
  for I := Low(APartes) to High(APartes) do
  begin
    if APartes[I] = nil then
      raise EValidacaoDominioIA.CreateFmt(
        'A parte de conteudo no indice %d nao foi informada.', [I]);
    FPartesConteudo[I] := APartes[I];
  end;

  FPapelMensagem := APapel;
  FNome := ANome;
  FIdCorrelacao := AIdCorrelacao;
end;

class function TMensagemIA.CriarTexto(APapel: TPapelMensagemIA;
  const ATexto, ANome, AIdCorrelacao: string): IMensagemIA;
var
  LPartesConteudo: TArray<IParteConteudoIA>;
begin
  SetLength(LPartesConteudo, CQuantidadePartesMensagemTexto);
  LPartesConteudo[Low(LPartesConteudo)] := TParteConteudoTextoIA.Create(ATexto);
  Result := TMensagemIA.Create(APapel, LPartesConteudo, ANome, AIdCorrelacao);
end;

function TMensagemIA.ObterIdCorrelacao: string;
begin
  Result := FIdCorrelacao;
end;

function TMensagemIA.ObterNome: string;
begin
  Result := FNome;
end;

function TMensagemIA.ObterPapel: TPapelMensagemIA;
begin
  Result := FPapelMensagem;
end;

function TMensagemIA.ObterPartes: TArray<IParteConteudoIA>;
begin
  Result := Copy(FPartesConteudo);
end;

function TMensagemIA.ObterTexto: string;
var
  LParteConteudo: IParteConteudoIA;
  LConstrutorTexto: TStringBuilder;
begin
  LConstrutorTexto := TStringBuilder.Create;
  try
    for LParteConteudo in FPartesConteudo do
      if LParteConteudo.Tipo = TTipoParteConteudoIA.Texto then
        LConstrutorTexto.Append(LParteConteudo.Texto);
    Result := LConstrutorTexto.ToString;
  finally
    LConstrutorTexto.Free;
  end;
end;

end.
