unit Daikit.Testes.ProvedorFalso;

interface

uses
  System.Classes,
  Daikit.Aplicacao.Interfaces,
  Daikit.Componentes.Provedor,
  Daikit.Infraestrutura.HTTP.Interfaces;

type
  TProvedorIAFalso = class(TProvedorIA)
  private
    FAdaptador: IAdaptadorIA;
  protected
    function ObterEndpointPadrao: string; override;
    function ObterModeloPadraoDoAdaptador: string; override;
    function ObterVariavelAmbienteChaveAPIPadrao: string; override;
    function ObterNomeProvedorLog: string; override;
    function CriarAdaptadorComTransporte(
      const ATransporte: ITransporteHTTP): IAdaptadorIA; override;
  public
    constructor Create(AOwner: TComponent;
      const AAdaptador: IAdaptadorIA); reintroduce;
  end;

implementation

uses
  Daikit.Componentes.Excecoes;

constructor TProvedorIAFalso.Create(AOwner: TComponent;
  const AAdaptador: IAdaptadorIA);
begin
  inherited Create(AOwner);
  if AAdaptador = nil then
    raise EConfiguracaoComponenteIA.Create(
      'O adaptador do provedor falso deve ser informado.');
  FAdaptador := AAdaptador;
end;

function TProvedorIAFalso.CriarAdaptadorComTransporte(
  const ATransporte: ITransporteHTTP): IAdaptadorIA;
begin
  Result := FAdaptador;
end;

function TProvedorIAFalso.ObterEndpointPadrao: string;
begin
  Result := 'https://api.falsa.test/v1';
end;

function TProvedorIAFalso.ObterModeloPadraoDoAdaptador: string;
begin
  Result := 'modelo-falso';
end;

function TProvedorIAFalso.ObterNomeProvedorLog: string;
begin
  Result := 'Falso';
end;

function TProvedorIAFalso.ObterVariavelAmbienteChaveAPIPadrao: string;
begin
  Result := 'DAIKIT_API_KEY_FALSA';
end;

end.
