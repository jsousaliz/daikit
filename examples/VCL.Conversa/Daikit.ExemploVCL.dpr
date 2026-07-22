program DaikitExemploVCL;

uses
  Vcl.Forms,
  Daikit.ExemploVCL.Principal in 'Daikit.ExemploVCL.Principal.pas' {FormPrincipal};

{$R 'Daikit.ExemploVCL.res'}
{$R '..\..\src\design\branding\Daikit.Icone.res'}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormPrincipal, FormPrincipal);
  Application.Run;
end.
