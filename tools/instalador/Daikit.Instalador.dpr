program DaikitInstalador;

uses
  Vcl.Forms,
  Daikit.Instalador.Principal in 'Daikit.Instalador.Principal.pas' {FormInstalador},
  Daikit.Instalador.Servico in 'Daikit.Instalador.Servico.pas';

{$R 'Daikit.Instalador.Payload.res'}
{$R '..\..\src\design\branding\Daikit.Icone.res'}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Instalador Daikit';
  Application.CreateForm(TFormInstalador, FormInstalador);
  Application.Run;
end.
