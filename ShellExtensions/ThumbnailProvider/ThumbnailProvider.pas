unit ThumbnailProvider;

// Copyright (c) 2020 Ivanov Alexander


{$WARN SYMBOL_PLATFORM OFF}
{$DEFINE NO_USE_CODESITE}



interface
uses  Windows, System.Classes;


type

  TCustomStreamThumbnail = class abstract
  public
    class procedure Register(const AClassID: TGUID; const AName, ADescription, AFileExtension: string);
    function GetThumbnailFromStream(Stream: TStream; cx: UINT; out phbmp: HBITMAP; out pdwAlpha: DWORD): HRESULT; virtual; abstract;
  end;

implementation

uses
{$IFDEF USE_CODESITE}
  CodeSiteLogging,
{$ENDIF}
  System.Win.ComObj, WinApi.ActiveX, System.Win.ComServ, WinApi.PropSys,
  System.SysUtils, Vcl.AxCtrls;

const
  SID_ThumbnailProvider = '{E357FCCD-A995-4576-B01F-234630154E96}';

type

  IThumbnailProvider = interface(IUnknown)
    [SID_ThumbnailProvider]
    function GetThumbnail(cx: UINT; out phbmp: HBITMAP; out pdwAlpha: DWORD): HResult; stdcall;
  end;

  TCustomStreamThumbnailClass = class of TCustomStreamThumbnail;

  TComThumbnailProvider = class(TComObject, IThumbnailProvider, IInitializeWithStream)
  strict private
    function IThumbnailProvider.GetThumbnail = IThumbnailProvider_GetThumbnail;
    function IInitializeWithStream.Initialize = IInitializeWithStream_Initialize;
    function IInitializeWithStream_Initialize(const pstream: IStream; grfMode: Cardinal): HRESULT; stdcall;
    function IThumbnailProvider_GetThumbnail(cx: UINT; out phbmp: HBITMAP; out pdwAlpha: DWORD): HResult; stdcall;
  private
    FStreamThumbnail: TCustomStreamThumbnail;
    FStreamThumbnailClass: TCustomStreamThumbnailClass;
    FIStream: IStream;
    FMode: Cardinal;
  public
    procedure Initialize; override;
    destructor Destroy; override;
    property StreamThumbnailClass: TCustomStreamThumbnailClass read FStreamThumbnailClass write FStreamThumbnailClass;
  end;


  TComThumbnailProviderFactory = class(TComObjectFactory)
  private
    FFileExtension: string;
    FCustomStreamThumbnailClass: TCustomStreamThumbnailClass;
  protected
    property FileExtension: string read FFileExtension;
  public
    constructor Create(ACustomStreamThumbnailClass: TCustomStreamThumbnailClass; const AClassID: TGUID; const AName, ADescription, AFileExtension: string);
    function CreateComObject(const Controller: IUnknown): TComObject; override;
    procedure UpdateRegistry(Register: Boolean); override;
  end;

constructor TComThumbnailProviderFactory.Create(ACustomStreamThumbnailClass: TCustomStreamThumbnailClass; const AClassID: TGUID; const AName, ADescription, AFileExtension: string);
begin
  inherited Create(System.Win.ComServ.ComServer, TComThumbnailProvider , AClassID, AName, ADescription, ciMultiInstance, tmApartment);
  FFileExtension := AFileExtension;
  FCustomStreamThumbnailClass := ACustomStreamThumbnailClass;
end;

function TComThumbnailProviderFactory.CreateComObject(const Controller: IUnknown): TComObject;
begin
 {$IFDEF USE_CODESITE}
  CodeSite.Send('TComThumbnailProviderFactory.CreateComObject');
 {$ENDIF}
  result := inherited CreateComObject(Controller);
  TComThumbnailProvider(result).FStreamThumbnailClass := FCustomStreamThumbnailClass;
end;

procedure TComThumbnailProviderFactory.UpdateRegistry(Register: Boolean);
var
  sClassID, ProgID,  RegPrefix: string;
  RootKey: HKEY;
begin
  if Instancing = ciInternal then
    Exit;

  ComServer.GetRegRootAndPrefix(RootKey, RegPrefix);

  sClassID := GUIDToString(ClassID);
  ProgID := GetProgID;

  if Register then
  begin
    inherited;
    if ProgID <> '' then
    begin
        CreateRegKey(RegPrefix + FileExtension + '\shellex\' + SID_ThumbnailProvider, '', sClassID, RootKey);
    end;
  end
  else
  begin
    if ProgID <> '' then
    begin
        DeleteRegKey(RegPrefix + FileExtension + '\shellex\' + SID_ThumbnailProvider, RootKey);
        DeleteRegKey(RegPrefix + FileExtension + '\shellex', RootKey);
    end;
    inherited;
  end;
end;

destructor TComThumbnailProvider.Destroy;
begin
 {$IFDEF USE_CODESITE}
  CodeSite.Send('TComThumbnailProvider.Destroy');
 {$ENDIF}
  FStreamThumbnail.Free;
  inherited Destroy;
end;

function TComThumbnailProvider.IInitializeWithStream_Initialize(
  const pstream: IStream; grfMode: Cardinal): HRESULT;
begin
 {$IFDEF USE_CODESITE}
 CodeSite.Send('IInitializeWithStream_Initialize  %x', [Integer(@FIStream)]);
 {$ENDIF}
 FIStream := pstream;
 FMode := grfMode;
 result := S_OK;
end;

procedure TComThumbnailProvider.Initialize;
begin
  inherited;
 {$IFDEF USE_CODESITE}
  CodeSite.Send('TComThumbnailProvider.Initialize');
 {$ENDIF}
end;

function TComThumbnailProvider.IThumbnailProvider_GetThumbnail(cx: UINT; out phbmp: HBITMAP; out pdwAlpha: DWORD): HResult;
var
  S: TStream;
begin
  try
    {$IFDEF USE_CODESITE}
    CodeSite.Send('GetThumbnail cx = %u',[cx]);
    {$ENDIF}
    S := TOleStream.Create(FIStream);
    S.Position := 0;
    try
     if FStreamThumbnail = nil then
       FStreamThumbnail := FStreamThumbnailClass.Create;
     Result := FStreamThumbnail.GetThumbnailFromStream(S, cx, phbmp, pdwAlpha);
    finally
     S.Free;
     FIStream := nil;
    end;
  except
    on E: Exception do
    begin
    {$IFDEF USE_CODESITE}
      CodeSite.SendException(E);
    {$ENDIF}
    end;
  end;
  result := S_OK;
end;

{ TCustomStreamThumbnail }

class procedure TCustomStreamThumbnail.Register(const AClassID: TGUID;
  const AName, ADescription, AFileExtension: string);
begin
  TComThumbnailProviderFactory.Create(Self, AClassID, AName, ADescription, AFileExtension);
end;

initialization

{$IFDEF USE_CODESITE}
  CodeSiteManager.ConnectUsingTcp;
{$ENDIF}

end.

