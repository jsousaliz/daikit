unit Daikit.Adaptadores.Anthropic.Constantes;

interface

uses
  System.SysUtils;

const
  CEndpointMensagensAnthropic = 'https://api.anthropic.com/v1/messages';
  CModeloAnthropicPadrao = 'claude-sonnet-4-6';
  CVersaoAPIAnthropic = '2023-06-01';
  CVariavelAmbienteChaveAnthropic = 'ANTHROPIC_API_KEY';
  CMaximoTokensSaidaPadraoAnthropic = 1024;
  CCabecalhoChaveAnthropic = 'x-api-key';
  CCabecalhoVersaoAnthropic = 'anthropic-version';
  CCabecalhoIdRequisicaoAnthropic = 'request-id';
  CCabecalhoTipoConteudoAnthropic = 'Content-Type';
  CCabecalhoAceiteAnthropic = 'Accept';
  CTipoConteudoJSONAnthropic = 'application/json';
  CPapelUsuarioAnthropic = 'user';
  CPapelAssistenteAnthropic = 'assistant';
  CTipoMensagemAnthropic = 'message';
  CTipoTextoAnthropic = 'text';
  CSeparadorMensagensSistemaAnthropic = sLineBreak;
  CQuantidadeCabecalhosAnthropic = 4;
  CIndiceChaveAnthropic = 0;
  CIndiceVersaoAnthropic = 1;
  CIndiceTipoConteudoAnthropic = 2;
  CIndiceAceiteAnthropic = 3;

implementation

end.
