unit Daikit.Adaptadores.Gemini.Constantes;

interface

uses
  System.SysUtils;

const
  CEndpointInteracoesGemini =
    'https://generativelanguage.googleapis.com/v1/interactions';
  CModeloGeminiPadrao = 'gemini-3.5-flash';
  CVariavelAmbienteChaveGemini = 'GEMINI_API_KEY';
  CMaximoTokensSaidaPadraoGemini = 1024;
  CCabecalhoChaveGemini = 'x-goog-api-key';
  CCabecalhoIdRequisicaoGemini = 'x-request-id';
  CCabecalhoTipoConteudoGemini = 'Content-Type';
  CCabecalhoAceiteGemini = 'Accept';
  CTipoConteudoJSONGemini = 'application/json';
  CTipoEntradaUsuarioGemini = 'user_input';
  CTipoSaidaModeloGemini = 'model_output';
  CTipoPensamentoGemini = 'thought';
  CTipoTextoGemini = 'text';
  CStatusConcluidoGemini = 'completed';
  CStatusIncompletoGemini = 'incomplete';
  CSeparadorMensagensSistemaGemini = sLineBreak;
  CQuantidadeCabecalhosGemini = 3;
  CIndiceChaveGemini = 0;
  CIndiceTipoConteudoGemini = 1;
  CIndiceAceiteGemini = 2;
  CPrefixoContextoGemini = 'gemini-interaction:';
  CResultadoSucessoCriacaoGUIDGemini = 0;

implementation

end.
