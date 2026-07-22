unit Daikit.Adaptadores.Anthropic.Excecoes;

interface

uses
  System.SysUtils;

type
  EAnthropic = class(Exception);
  EConfiguracaoAnthropic = class(EAnthropic);
  EContratoAnthropic = class(EAnthropic);

  ERespostaAnthropic = class(EAnthropic)
  private
    FStatusHTTP: Integer;
    FTipoErro: string;
    FIdRequisicao: string;
    FMensagemAPI: string;
  public
    constructor Create(AStatusHTTP: Integer; const ATipoErro,
      AIdRequisicao, AMensagemAPI: string);
    property StatusHTTP: Integer read FStatusHTTP;
    property TipoErro: string read FTipoErro;
    property IdRequisicao: string read FIdRequisicao;
    property MensagemAPI: string read FMensagemAPI;
  end;

implementation

constructor ERespostaAnthropic.Create(AStatusHTTP: Integer;
  const ATipoErro, AIdRequisicao, AMensagemAPI: string);
begin
  if AMensagemAPI = '' then
    inherited CreateFmt(
      'A API Anthropic recusou a requisicao (HTTP %d, tipo "%s", id "%s").',
      [AStatusHTTP, ATipoErro, AIdRequisicao])
  else
    inherited CreateFmt(
      'A API Anthropic recusou a requisicao (HTTP %d, tipo "%s", id "%s"). Mensagem: %s',
      [AStatusHTTP, ATipoErro, AIdRequisicao, AMensagemAPI]);
  FStatusHTTP := AStatusHTTP;
  FTipoErro := ATipoErro;
  FIdRequisicao := AIdRequisicao;
  FMensagemAPI := AMensagemAPI;
end;

end.
