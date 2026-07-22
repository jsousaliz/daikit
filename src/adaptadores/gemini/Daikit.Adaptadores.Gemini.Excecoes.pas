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
    FMensagemAPI: string;
  public
    constructor Create(AStatusHTTP, ACodigoErro: Integer;
      const ATipoErro, AIdRequisicao, AMensagemAPI: string);
    property StatusHTTP: Integer read FStatusHTTP;
    property CodigoErro: Integer read FCodigoErro;
    property TipoErro: string read FTipoErro;
    property IdRequisicao: string read FIdRequisicao;
    property MensagemAPI: string read FMensagemAPI;
  end;

implementation

constructor ERespostaGemini.Create(AStatusHTTP, ACodigoErro: Integer;
  const ATipoErro, AIdRequisicao, AMensagemAPI: string);
begin
  if AMensagemAPI = '' then
    inherited CreateFmt(
      'A API Gemini recusou a requisicao (HTTP %d, codigo %d, tipo "%s", id "%s").',
      [AStatusHTTP, ACodigoErro, ATipoErro, AIdRequisicao])
  else
    inherited CreateFmt(
      'A API Gemini recusou a requisicao (HTTP %d, codigo %d, tipo "%s", id "%s"). Mensagem: %s',
      [AStatusHTTP, ACodigoErro, ATipoErro, AIdRequisicao, AMensagemAPI]);
  FStatusHTTP := AStatusHTTP;
  FCodigoErro := ACodigoErro;
  FTipoErro := ATipoErro;
  FIdRequisicao := AIdRequisicao;
  FMensagemAPI := AMensagemAPI;
end;

end.
