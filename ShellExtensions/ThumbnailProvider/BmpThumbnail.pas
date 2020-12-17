unit BmpThumbnail;

interface

uses
  ThumbNailProvider,
  Winapi.Windows,
  System.Classes,
  Vcl.Graphics;

const
  // Don't forget to create a new one. Best use Ctrl-G
  CLASS_SVGThumbnail: TGUID = '{F79EEEA9-61A9-4DC2-BF17-C8150D46F9FC}';

type

  TMyDemoThumbnail= class(TCustomStreamThumbnail)
    function GetThumbnailFromStream (Stream : TStream; cx: UINT; out phbmp: HBITMAP; out pdwAlpha: DWORD) : HRESULT;  override;
   end;

implementation

{ TSVGThumbnail }

function TMyDemoThumbnail.GetThumbnailFromStream(Stream: TStream; cx: UINT;
  out phbmp: HBITMAP; out pdwAlpha: DWORD): HRESULT;
var
  B: TBitmap;
begin
  B := TBitmap.Create;
  try
    B.LoadFromStream(Stream);
    Result := B.ReleaseHandle;
  finally
    B.Free;
  end;
  Result := S_OK;
end;

initialization

  TMyDemoThumbnail.Register(
    CLASS_SVGThumbnail,
    'bmp2 files',
    'Some comments .... ',
    '.bmp2');

end.
