unit Daikit.Aplicacao.ServicoModelos;

interface

uses
  Daikit.Dominio.Interfaces,
  Daikit.Aplicacao.Interfaces;

type
  TServicoModelosIA = class
  public
    class function Listar(const AAdaptador: IAdaptadorIA;
      const ACancelamento: ITokenCancelamentoIA): TArray<IModeloIA>; static;
  end;

implementation

uses
  Daikit.Dominio.Excecoes;

class function TServicoModelosIA.Listar(const AAdaptador: IAdaptadorIA;
  const ACancelamento: ITokenCancelamentoIA): TArray<IModeloIA>;
begin
  if AAdaptador = nil then
    raise EValidacaoDominioIA.Create(
      'O adaptador deve ser informado para listar os modelos.');
  if (ACancelamento <> nil) and ACancelamento.FoiCancelado then
    raise EOperacaoCanceladaIA.Create(
      'A listagem de modelos foi cancelada.');
  Result := AAdaptador.ListarModelos(ACancelamento);
end;

end.
