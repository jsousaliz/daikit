unit Daikit.Adaptadores.OpenAI.Constantes;

interface

const
  CEndpointRespostasOpenAI = 'https://api.openai.com/v1/responses';
  CModeloOpenAIRecomendado = 'gpt-5.6';
  CVariavelAmbienteChaveOpenAI = 'OPENAI_API_KEY';
  CCabecalhoAutorizacao = 'Authorization';
  CCabecalhoTipoConteudo = 'Content-Type';
  CCabecalhoAceite = 'Accept';
  CCabecalhoIdRequisicaoOpenAI = 'x-request-id';
  CPrefixoBearer = 'Bearer ';
  CTipoConteudoJSON = 'application/json';
  CPapelSistemaOpenAI = 'system';
  CPapelUsuarioOpenAI = 'user';
  CPapelAssistenteOpenAI = 'assistant';
  CTipoMensagemOpenAI = 'message';
  CTipoTextoSaidaOpenAI = 'output_text';
  CStatusConcluidoOpenAI = 'completed';
  CQuantidadeCabecalhosRequisicaoOpenAI = 3;
  CIndiceCabecalhoAutorizacaoOpenAI = 0;
  CIndiceCabecalhoTipoConteudoOpenAI = 1;
  CIndiceCabecalhoAceiteOpenAI = 2;

implementation

end.
