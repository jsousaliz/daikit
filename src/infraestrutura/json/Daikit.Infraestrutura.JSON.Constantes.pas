unit Daikit.Infraestrutura.JSON.Constantes;

interface

uses
  REST.Json;

const
  COpcoesJSONPadrao: TJsonOptions = [joDateIsUTC, joDateFormatISO8601,
    joBytesFormatArray, joIndentCaseCamel, joSerialFields];
  COpcoesJSONSemVazios: TJsonOptions = [joDateIsUTC, joDateFormatISO8601,
    joBytesFormatArray, joIndentCaseCamel, joSerialFields,
    joIgnoreEmptyStrings, joIgnoreEmptyArrays];
  CLimiteJSONLogPadraoBytes = 64 * 1024;
  CLimiteJSONLogMinimoBytes = 128;
  CLimiteEntradaJSONLogBytes = 16 * 1024 * 1024;
  CLimiteProfundidadeJSONLog = 64;
  CPrimeiroCodigoSurrogateAlto = $D800;
  CUltimoCodigoSurrogateAlto = $DBFF;
  CValorJSONSensivelRemovido = '[REMOVIDO]';
  CValorJSONConteudoOculto = '[CONTEUDO_OCULTO]';
  CValorJSONProfundidadeRemovida = '[PROFUNDIDADE_REMOVIDA]';
  CJSONInvalidoRemovido = '[JSON_INVALIDO_REMOVIDO]';
  CJSONExcessivoRemovido = '[JSON_EXCESSIVO_REMOVIDO]';
  CChaveEnvelopeJSONTruncado = 'daikit_truncado';
  CChaveEnvelopeJSONPrevia = 'daikit_previa';
  CChaveEnvelopeJSONRemovido = 'daikit_removido';
  CMensagemLimiteJSONLogInvalido =
    'O limite do JSON de log deve ser no minimo %d bytes.';

  CChaveJSONAutorizacao = 'authorization';
  CChaveJSONAutorizacaoProxy = 'proxy_authorization';
  CChaveJSONChaveAPI = 'api_key';
  CChaveJSONChaveAPISemSeparador = 'apikey';
  CChaveJSONChaveAPIGoogle = 'x_goog_api_key';
  CChaveJSONChaveAPIComPrefixoX = 'x_api_key';
  CChaveJSONTokenAcesso = 'access_token';
  CChaveJSONTokenAtualizacao = 'refresh_token';
  CChaveJSONToken = 'token';
  CChaveJSONSenha = 'password';
  CChaveJSONSenhaPortugues = 'senha';
  CChaveJSONSegredo = 'secret';
  CChaveJSONSegredoCliente = 'client_secret';
  CChaveJSONCookie = 'cookie';
  CChaveJSONCookieResposta = 'set_cookie';
  CChaveJSONChave = 'key';
  CChaveJSONChavePortugues = 'chave';
  CChaveJSONChaveAPIPortugues = 'chave_api';
  CChaveJSONCredencial = 'credential';

  CChaveJSONTexto = 'text';
  CChaveJSONConteudo = 'content';
  CChaveJSONEntrada = 'input';
  CChaveJSONSaida = 'output';
  CChaveJSONSistema = 'system';
  CChaveJSONInstrucaoSistema = 'system_instruction';
  CChaveJSONPrompt = 'prompt';
  CChaveJSONMensagem = 'message';
  CChaveJSONMensagens = 'messages';
  CChaveJSONResposta = 'response';
  CChaveJSONConclusao = 'completion';

  CChaveJSONAssinatura = 'signature';
  CChaveJSONAssinaturaPensamento = 'thought_signature';
  CChaveJSONConteudoCriptografado = 'encrypted_content';
  CChaveJSONRaciocinio = 'reasoning';
  CChaveJSONConteudoRaciocinio = 'reasoning_content';
  CChaveJSONPensamento = 'thought';
  CChaveJSONPensando = 'thinking';
  CChaveJSONResumo = 'summary';

implementation

end.
