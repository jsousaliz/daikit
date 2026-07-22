unit Daikit.Design.Registro;

interface

procedure Register;

implementation

{$R 'Daikit.Design.Registro.dcr'}

uses
  System.Classes,
  DesignIntf,
  Daikit.Componentes.Constantes,
  Daikit.Componentes.Chat,
  Daikit.Componentes.Conversa,
  Daikit.Componentes.Provedores;

procedure Register;
begin
  RegisterComponents(CNomePaletaDaikit,
    [TChatIA, TConversaIA, TProvedorOpenAI, TProvedorAnthropic,
     TProvedorGemini]);
end;

end.
