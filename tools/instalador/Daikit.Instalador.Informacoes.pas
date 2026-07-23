unit Daikit.Instalador.Informacoes;

interface

const
  URL_REPOSITORIO_DAIKIT = 'https://github.com/jsousaliz/daikit';

function ObterVersaoInstalador: string;

implementation

uses
  System.SysUtils,
  Winapi.Windows;

function ObterVersaoInstalador: string;
var
  LTamanhoInformacoes: DWORD;
  LIdentificador: DWORD;
  LInformacoes: TBytes;
  LInformacoesVersao: PVSFixedFileInfo;
  LTamanhoVersao: UINT;
begin
  Result := '0.0.0';
  LTamanhoInformacoes := GetFileVersionInfoSize(PChar(ParamStr(0)),
    LIdentificador);
  if LTamanhoInformacoes = 0 then
    Exit;

  SetLength(LInformacoes, LTamanhoInformacoes);
  if not GetFileVersionInfo(PChar(ParamStr(0)), 0, LTamanhoInformacoes,
    LInformacoes) then
    Exit;

  if not VerQueryValue(LInformacoes, '\', Pointer(LInformacoesVersao),
    LTamanhoVersao) then
    Exit;

  Result := Format('%d.%d.%d', [
    HiWord(LInformacoesVersao.dwFileVersionMS),
    LoWord(LInformacoesVersao.dwFileVersionMS),
    HiWord(LInformacoesVersao.dwFileVersionLS)
  ]);
end;

end.
