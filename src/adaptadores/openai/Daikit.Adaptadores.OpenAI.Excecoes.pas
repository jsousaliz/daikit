unit Daikit.Adaptadores.OpenAI.Excecoes;

interface

uses
  System.SysUtils;

type
  EOpenAI = class(Exception);
  EConfiguracaoOpenAI = class(EOpenAI);
  EContratoOpenAI = class(EOpenAI);

  ERespostaOpenAI = class(EOpenAI)
  private
    FStatusHTTP: Integer;
    FTipoErro: string;
    FCodigoErro: string;
    FIdRequisicao: string;
  public
    constructor Create(AStatusHTTP: Integer; const ATipoErro, ACodigoErro,
      AIdRequisicao: string);
    property StatusHTTP: Integer read FStatusHTTP;
    property TipoErro: string read FTipoErro;
    property CodigoErro: string read FCodigoErro;
    property IdRequisicao: string read FIdRequisicao;
  end;

implementation

constructor ERespostaOpenAI.Create(AStatusHTTP: Integer; const ATipoErro,
  ACodigoErro, AIdRequisicao: string);
begin
  inherited CreateFmt(
    'A API OpenAI recusou a requisicao (HTTP %d, tipo "%s", codigo "%s", id "%s").',
    [AStatusHTTP, ATipoErro, ACodigoErro, AIdRequisicao]);
  FStatusHTTP := AStatusHTTP;
  FTipoErro := ATipoErro;
  FCodigoErro := ACodigoErro;
  FIdRequisicao := AIdRequisicao;
end;

end.
