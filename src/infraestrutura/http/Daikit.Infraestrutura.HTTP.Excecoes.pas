unit Daikit.Infraestrutura.HTTP.Excecoes;

interface

uses
  System.SysUtils;

type
  EValidacaoHTTP = class(EArgumentException);
  ELimiteRespostaHTTP = class(Exception);
  ETransporteHTTP = class(Exception);
  ETimeoutHTTP = class(ETransporteHTTP);

implementation

end.
