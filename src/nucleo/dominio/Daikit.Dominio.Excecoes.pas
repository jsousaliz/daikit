unit Daikit.Dominio.Excecoes;

interface

uses
  System.SysUtils;

type
  EValidacaoDominioIA = class(EArgumentException);
  EOperacaoCanceladaIA = class(EAbort);

implementation

end.
