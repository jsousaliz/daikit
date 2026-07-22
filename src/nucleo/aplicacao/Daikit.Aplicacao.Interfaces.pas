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
    ['{06578615-863D-4222-84D1-5EDD82763E77}']
    function ObterCapacidades: ICapacidadesAdaptadorIA;
    function Concluir(const ARequisicao: IRequisicaoChatIA;
      const ACancelamento: ITokenCancelamentoIA = nil): IRespostaChatIA;
    property Capacidades: ICapacidadesAdaptadorIA read ObterCapacidades;
  end;

implementation

end.
