program Daikit.Demo;

uses
  Vcl.Forms,
  Daikit.Demo.Principal in 'Daikit.Demo.Principal.pas' {FormPrincipal};

{$R 'Daikit.Demo.res'}
{$R '..\..\src\design\branding\Daikit.Icone.res'}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormPrincipal, FormPrincipal);
  Application.Run;
end.
