unit Daikit.Aplicacao.Interfaces;

interface

{$SCOPEDENUMS ON}

uses
  Daikit.Dominio.Interfaces;

type
  ITokenCancelamentoIA = interface
    ['{05D35226-A278-40E0-A0EF-A8CA2B0C26D3}']
    procedure Cancelar;
    function FoiCancelado: Boolean;
  end;

  ICapacidadesAdaptadorIA = interface
    ['{C9E47E0D-4BBA-4C3A-A02C-A628EAA91FD2}']
    function SuportaTextoSincrono: Boolean;
    function SuportaFluxoContinuo: Boolean;
    function SuportaFerramentas: Boolean;
    function SuportaImagemEntrada: Boolean;
    function SuportaSaidaEstruturada: Boolean;
  end;

  IAdaptadorIA = interface
    ['{D787C067-E0BF-47E7-852F-9FF3343B5CDB}']
    function ObterCapacidades: ICapacidadesAdaptadorIA;
    function Concluir(const ARequisicao: IRequisicaoChatIA;
      const ACancelamento: ITokenCancelamentoIA = nil): IRespostaChatIA;
    function ListarModelos(
      const ACancelamento: ITokenCancelamentoIA = nil): TArray<IModeloIA>;
    property Capacidades: ICapacidadesAdaptadorIA read ObterCapacidades;
  end;

implementation

end.
