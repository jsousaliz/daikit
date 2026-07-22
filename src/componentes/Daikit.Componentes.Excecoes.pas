unit Daikit.Componentes.Excecoes;

interface

uses
  System.SysUtils;

type
  EComponenteIA = class(Exception);
  EConfiguracaoComponenteIA = class(EComponenteIA);
  EEstadoComponenteIA = class(EComponenteIA);

implementation

end.
