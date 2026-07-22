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
  public
    constructor Create(AStatusHTTP: Integer; const ATipoErro,
      AIdRequisicao: string);
    property StatusHTTP: Integer read FStatusHTTP;
    property TipoErro: string read FTipoErro;
    property IdRequisicao: string read FIdRequisicao;
  end;

implementation

constructor ERespostaAnthropic.Create(AStatusHTTP: Integer;
  const ATipoErro, AIdRequisicao: string);
begin
  inherited CreateFmt(
    'A API Anthropic recusou a requisicao (HTTP %d, tipo "%s", id "%s").',
    [AStatusHTTP, ATipoErro, AIdRequisicao]);
  FStatusHTTP := AStatusHTTP;
  FTipoErro := ATipoErro;
  FIdRequisicao := AIdRequisicao;
end;

end.
