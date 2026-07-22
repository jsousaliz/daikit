unit Daikit.Testes.Fixtures.Anthropic;

interface

const
  CRespostaAnthropicSucesso =
    '{"id":"msg_teste_123","type":"message","role":"assistant",' +
    '"model":"claude-modelo-teste","content":[' +
    '{"type":"text","text":"Ola do Claude"}],' +
    '"stop_reason":"end_turn","stop_sequence":null,' +
    '"usage":{"input_tokens":13,"output_tokens":8}}';

  CRespostaAnthropicMultiplosTextos =
    '{"id":"msg_partes","type":"message","role":"assistant",' +
    '"model":"modelo","content":[' +
    '{"type":"text","text":"primeira "},' +
    '{"type":"text","text":"segunda"}],' +
    '"stop_reason":"end_turn","usage":{"input_tokens":2,"output_tokens":3}}';

  CRespostaAnthropicErro =
    '{"type":"error","error":{' +
    '"type":"invalid_request_error",' +
    '"message":"conteudo-sensivel-anthropic"},' +
    '"request_id":"req_corpo_123"}';

implementation

end.
