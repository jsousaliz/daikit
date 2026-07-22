unit Daikit.Adaptadores.Interfaces;

interface

type
  IFonteChaveAPI = interface
    ['{B6C09FBC-3818-441D-8BBF-326BE227D066}']
    function ObterChaveAPI: string;
  end;

  IConfiguracaoAdaptadorIA = interface
    ['{DA038848-36EB-4B9B-B5EF-2C4EA186ABDC}']
    function ObterEndpoint: string;
    function ObterEndpointModelos: string;
    function ObterModeloPadrao: string;
    function ObterTimeoutConexaoMS: Integer;
    function ObterTimeoutRespostaMS: Integer;
    function ObterLimiteRespostaBytes: Int64;
    property Endpoint: string read ObterEndpoint;
    property EndpointModelos: string read ObterEndpointModelos;
    property ModeloPadrao: string read ObterModeloPadrao;
    property TimeoutConexaoMS: Integer read ObterTimeoutConexaoMS;
    property TimeoutRespostaMS: Integer read ObterTimeoutRespostaMS;
    property LimiteRespostaBytes: Int64 read ObterLimiteRespostaBytes;
  end;

implementation

end.
