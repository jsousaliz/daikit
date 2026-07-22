unit Daikit.Adaptadores.Interfaces;

interface

type
  IFonteChaveAPI = interface
    ['{B6C09FBC-3818-441D-8BBF-326BE227D066}']
    function ObterChaveAPI: string;
  end;

  IConfiguracaoAdaptadorIA = interface
    ['{B72E987E-D626-4777-A3A0-D73DE3B15E68}']
    function ObterEndpoint: string;
    function ObterModeloPadrao: string;
    function ObterTimeoutConexaoMS: Integer;
    function ObterTimeoutRespostaMS: Integer;
    function ObterLimiteRespostaBytes: Int64;
    property Endpoint: string read ObterEndpoint;
    property ModeloPadrao: string read ObterModeloPadrao;
    property TimeoutConexaoMS: Integer read ObterTimeoutConexaoMS;
    property TimeoutRespostaMS: Integer read ObterTimeoutRespostaMS;
    property LimiteRespostaBytes: Int64 read ObterLimiteRespostaBytes;
  end;

implementation

end.
