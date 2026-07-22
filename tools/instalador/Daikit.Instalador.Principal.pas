unit Daikit.Instalador.Principal;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Daikit.Instalador.Servico;

type
  TFormInstalador = class(TForm)
    ButtonInstalar: TButton;
    ButtonDesinstalar: TButton;
    LabelDestino: TLabel;
    LabelEstado: TLabel;
    LabelIntroducao: TLabel;
    LabelPlataformas: TLabel;
    LabelTitulo: TLabel;
    MemoLog: TMemo;
    PanelCabecalho: TPanel;
    procedure ButtonDesinstalarClick(Sender: TObject);
    procedure ButtonInstalarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  strict private
    FServicoInstalacaoDaikit: TServicoInstalacaoDaikit;
    procedure AtualizarTela;
    procedure RegistrarLog(const ATexto: string);
  end;

var
  FormInstalador: TFormInstalador;

implementation

uses
  System.SysUtils,
  System.UITypes,
  Vcl.Dialogs;

{$R *.dfm}

procedure TFormInstalador.AtualizarTela;
var
  LEstado: TEstadoInstalacaoDaikit;
begin
  LEstado := FServicoInstalacaoDaikit.ObterEstado;
  LabelDestino.Caption := 'Destino das BPLs: ' + LEstado.DiretorioBPL;
  LabelEstado.Caption := LEstado.Descricao;
  ButtonInstalar.Enabled := LEstado.DelphiInstalado and
    LEstado.ArtefatosDisponiveis and not LEstado.IDEEmExecucao;
  ButtonDesinstalar.Enabled := LEstado.PacoteRegistrado and
    not LEstado.IDEEmExecucao;
end;

procedure TFormInstalador.ButtonDesinstalarClick(Sender: TObject);
begin
  if MessageDlg('Deseja remover os componentes Daikit do Delphi 12?',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;
  try
    FServicoInstalacaoDaikit.Desinstalar;
    RegistrarLog('Desinstalacao concluida.');
    MessageDlg('Daikit removido. Abra novamente o Delphi.', mtInformation,
      [mbOK], 0);
  except
    on E: Exception do
    begin
      RegistrarLog('ERRO: ' + E.Message);
      MessageDlg(E.Message, mtError, [mbOK], 0);
    end;
  end;
  AtualizarTela;
end;

procedure TFormInstalador.ButtonInstalarClick(Sender: TObject);
begin
  try
    FServicoInstalacaoDaikit.Instalar;
    RegistrarLog('Instalacao Win32 e Win64 concluida.');
    MessageDlg('Daikit instalado. Abra o Delphi e procure a pagina Daikit.',
      mtInformation, [mbOK], 0);
  except
    on E: Exception do
    begin
      RegistrarLog('ERRO: ' + E.Message);
      MessageDlg(E.Message, mtError, [mbOK], 0);
    end;
  end;
  AtualizarTela;
end;

procedure TFormInstalador.FormCreate(Sender: TObject);
begin
  FServicoInstalacaoDaikit := TServicoInstalacaoDaikit.Create;
  RegistrarLog('Instalador autocontido iniciado.');
  AtualizarTela;
end;

procedure TFormInstalador.FormDestroy(Sender: TObject);
begin
  FServicoInstalacaoDaikit.Free;
end;

procedure TFormInstalador.RegistrarLog(const ATexto: string);
begin
  MemoLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + ATexto);
end;

end.
