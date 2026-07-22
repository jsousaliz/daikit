unit Daikit.Testes.Fixtures.OpenAI;

interface

const
  CRespostaOpenAISucesso =
    '{' +
    '"id":"resp_teste_123",' +
    '"object":"response",' +
    '"status":"completed",' +
    '"model":"gpt-modelo-teste",' +
    '"output":[' +
      '{"type":"message","role":"assistant","status":"completed",' +
      '"content":[' +
        '{"type":"output_text","text":"Ola do OpenAI","annotations":[]}' +
      ']}' +
    '],' +
    '"usage":{"input_tokens":11,"output_tokens":7,"total_tokens":18}' +
    '}';

  CRespostaOpenAIMultiplosTextos =
    '{' +
    '"id":"resp_partes","status":"completed","model":"modelo",' +
    '"output":[{"type":"message","role":"assistant","status":"completed",' +
    '"content":[' +
      '{"type":"output_text","text":"primeira ","annotations":[]},' +
      '{"type":"output_text","text":"segunda","annotations":[]}' +
    ']}],' +
    '"usage":{"input_tokens":2,"output_tokens":3,"total_tokens":5}' +
    '}';

  CRespostaOpenAIErro =
    '{"error":{' +
      '"message":"Modelo invalido. Chave: sk-chave-falsa-de-teste.\r\nRevise o identificador.",' +
      '"type":"invalid_request_error",' +
      '"param":"model",' +
      '"code":"model_not_found"' +
    '}}';

implementation

end.
