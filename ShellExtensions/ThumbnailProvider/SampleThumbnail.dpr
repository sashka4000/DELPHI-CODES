library SampleThumbnail;

uses
  ComServ,
  Windows,
  ThumbnailProvider in 'ThumbnailProvider.pas',
  BmpThumbnail in 'BmpThumbnail.pas';

exports
  DllGetClassObject,
  DllCanUnloadNow,
  DllRegisterServer,
  DllUnregisterServer,
  DllInstall;

{$R *.RES}


begin
end.
