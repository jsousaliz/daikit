unit Daikit.Testes.Fixtures.Gemini;

interface

const
  CRespostaGeminiSucesso =
    '{"id":"int_teste_123","model":"gemini-3.5-flash",' +
    '"status":"completed","steps":[{"type":"model_output",' +
    '"content":[{"type":"text","text":"Ola do Gemini"}]}],' +
    '"usage":{"total_input_tokens":12,"total_output_tokens":8,' +
    '"total_tokens":20}}';

  CRespostaGeminiMultiplosTextos =
    '{"id":"int_partes","model":"modelo","status":"completed",' +
    '"steps":[{"type":"model_output","content":[' +
    '{"type":"text","text":"primeira "},' +
    '{"type":"text","text":"segunda"}]}],' +
    '"usage":{"input_tokens":2,"output_tokens":3,"total_tokens":5}}';

  CRespostaGeminiErro =
    '{"error":{"code":400,"message":"conteudo-sensivel-gemini",' +
    '"status":"INVALID_ARGUMENT"}}';
  CRespostaGeminiErroEmLista =
    '[{"error":{"code":400,"message":"conteudo-sensivel-gemini",' +
    '"status":"INVALID_ARGUMENT"}}]';

  CRespostaGeminiComPensamento =
    '{"id":"int_pensamento_123","model":"gemini-3.5-flash",' +
    '"status":"completed","steps":[' +
    '{"type":"thought","signature":"assinatura-opaca-123"},' +
    '{"type":"model_output","content":[' +
    '{"type":"text","text":"Resposta com contexto"}]}],' +
    '"usage":{"total_input_tokens":15,"total_output_tokens":9,' +
    '"total_tokens":24}}';

  CRespostaGeminiStepDesconhecido =
    '{"id":"int_step_123","model":"gemini-3.5-flash",' +
    '"status":"completed","steps":[' +
    '{"type":"recurso_futuro","signature":"valor"},' +
    '{"type":"model_output","content":[' +
    '{"type":"text","text":"Resposta"}]}]}';

  CRespostaGeminiSemId =
    '{"model":"gemini-3.5-flash","status":"completed",' +
    '"steps":[{"type":"thought","signature":"assinatura-sem-id"},' +
    '{"type":"model_output","content":[' +
    '{"type":"text","text":"Resposta sem id remoto"}]}]}';

  CRespostaGeminiPensamentoSemAssinatura =
    '{"id":"int_sem_assinatura","model":"gemini-3.5-flash",' +
    '"status":"completed","steps":[{"type":"thought"},' +
    '{"type":"model_output","content":[' +
    '{"type":"text","text":"Resposta"}]}]}';

implementation

end.
