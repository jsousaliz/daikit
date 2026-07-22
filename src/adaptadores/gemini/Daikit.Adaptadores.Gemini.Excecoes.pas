unit Daikit.Adaptadores.Gemini.Excecoes;

interface

uses
  System.SysUtils;

type
  EGemini = class(Exception);
  EConfiguracaoGemini = class(EGemini);
  EContratoGemini = class(EGemini);

  ERespostaGemini = class(EGemini)
  private
    FStatusHTTP: Integer;
    FCodigoErro: Integer;
    FTipoErro: string;
    FIdRequisicao: string;
  public
    constructor Create(AStatusHTTP, ACodigoErro: Integer;
      const ATipoErro, AIdRequisicao: string);
    property StatusHTTP: Integer read FStatusHTTP;
    property CodigoErro: Integer read FCodigoErro;
    property TipoErro: string read FTipoErro;
    property IdRequisicao: string read FIdRequisicao;
  end;

implementation

constructor ERespostaGemini.Create(AStatusHTTP, ACodigoErro: Integer;
  const ATipoErro, AIdRequisicao: string);
begin
  inherited CreateFmt(
    'A API Gemini recusou a requisicao (HTTP %d, codigo %d, tipo "%s", id "%s").',
    [AStatusHTTP, ACodigoErro, ATipoErro, AIdRequisicao]);
  FStatusHTTP := AStatusHTTP;
  FCodigoErro := ACodigoErro;
  FTipoErro := ATipoErro;
  FIdRequisicao := AIdRequisicao;
end;

end.
