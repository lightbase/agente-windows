unit CACIC_USB;
// Código Original obtido em http://www.delphi3000.com/articles/article_4841.asp?SK=
interface
uses Windows, Messages, SysUtils, Classes;

type
  { Event Types }
  TOnUsbChangeEvent = procedure(AObject : TObject;
                                const ADevType,AVendorID,
                                      AProductID : string) of object;

  { USB Class }
  TUsbClass = class(TObject)
  private
    FHandle : HWND;
    FOnUsbRemoval,
    FOnUsbInsertion : TOnUsbChangeEvent;
    procedure GetUsbInfo(const ADeviceString : string;
                         out ADevType,AVendorID,
                            AProductID : string);
    procedure WinMethod(var AMessage : TMessage);
    procedure RegisterUsbHandler;
    procedure WMDeviceChange(var AMessage : TMessage);
    procedure Split(const Delimiter: Char;Input: string;const Strings: TStrings);
  public
    constructor Create;
    destructor Destroy; override;
    property OnUsbInsertion : TOnUsbChangeEvent read FOnUsbInsertion
                                           write FOnUsbInsertion;
    property OnUsbRemoval : TOnUsbChangeEvent read FOnUsbRemoval
                                           write FOnUsbRemoval;
  end;



// -----------------------------------------------------------------------------
implementation

type
  // Win API Definitions
  PDevBroadcastDeviceInterface  = ^DEV_BROADCAST_DEVICEINTERFACE;
  DEV_BROADCAST_DEVICEINTERFACE = record
    dbcc_size : DWORD;
    dbcc_devicetype : DWORD;
    dbcc_reserved : DWORD;
    dbcc_classguid : TGUID;
    dbcc_name : char;
  end;

const
  // Miscellaneous
  GUID_DEVINTF_USB_DEVICE : TGUID = '{A5DCBF10-6530-11D2-901F-00C04FB951ED}';
  USB_INTERFACE                = $00000005; // Device interface class
  USB_INSERTION                = $8000;     // System detected a new device
  USB_REMOVAL                  = $8004;     // Device is gone

constructor TUsbClass.Create;
begin
  inherited Create;
  FHandle := AllocateHWnd(WinMethod);
  RegisterUsbHandler;
end;

destructor TUsbClass.Destroy;
begin
  DeallocateHWnd(FHandle);
  inherited Destroy;
end;

procedure TUsbClass.GetUsbInfo(const ADeviceString : string;
                               out ADevType,AVendorID,
                                   AProductID : string);
var sWork,sKey1 : string;
    tstrAUX1,tstrAUX2 : TStringList;
begin
  ADevType := '';
  AVendorID := '';
  AProductID := '';

  if ADeviceString <> '' then
    Begin
      sWork := copy(ADeviceString,pos('#',ADeviceString) + 1,1026);
      sKey1 := copy(sWork,1,pos('#',sWork) - 1);

      tstrAUX1 := TStringList.Create;
      tstrAUX2 := TStringList.Create;

      Split('&',sKey1,tstrAUX1);

      Split('_',tstrAUX1[0],tstrAUX2);
      AVendorID := tstrAUX2[1];

      Split('_',tstrAUX1[1],tstrAUX2);
      AProductID := tstrAUX2[1];

      tstrAUX1.Free;
      tstrAUX2.Free;
    End;
end;

procedure TUsbClass.Split(const Delimiter: Char;
    Input: string;
    const Strings: TStrings) ;
begin
   Assert(Assigned(Strings)) ;
   Strings.Clear;
   Strings.Delimiter := Delimiter;
   Strings.DelimitedText := Input;
end;

procedure TUsbClass.WMDeviceChange(var AMessage : TMessage);
var iDevType : integer;
    sDevString,sDevType,
    sVendorID,sProductID : string;
    pData : PDevBroadcastDeviceInterface;
begin
  if (AMessage.wParam = USB_INSERTION) or
     (AMessage.wParam = USB_REMOVAL) then
    Begin
      pData := PDevBroadcastDeviceInterface(AMessage.LParam);
      iDevType := pData^.dbcc_devicetype;

      // Se for um dispositivo USB...
      if iDevType = USB_INTERFACE then
        Begin
          sDevString := PChar(@pData^.dbcc_name);

          GetUsbInfo(sDevString,sDevType,sVendorID,sProductID);

          // O evento é disparado conforme a mensagem
          if (AMessage.wParam = USB_INSERTION) and Assigned(FOnUsbInsertion) then
              FOnUsbInsertion(self,sDevType,sVendorID,sProductID);
          if (AMessage.wParam = USB_REMOVAL) and Assigned(FOnUsbRemoval) then
              FOnUsbRemoval(self,sDevType,sVendorID,sProductID);
        End;
    End;
end;

procedure TUsbClass.WinMethod(var AMessage : TMessage);
begin
  if (AMessage.Msg = WM_DEVICECHANGE) then
    WMDeviceChange(AMessage)
  else
    AMessage.Result := DefWindowProc(FHandle,AMessage.Msg,
                                     AMessage.wParam,AMessage.lParam);
end;


procedure TUsbClass.RegisterUsbHandler;
var rDbi : DEV_BROADCAST_DEVICEINTERFACE;
    iSize : integer;
begin
  iSize := SizeOf(DEV_BROADCAST_DEVICEINTERFACE);
  ZeroMemory(@rDbi,iSize);
  rDbi.dbcc_size       := iSize;
  rDbi.dbcc_devicetype := USB_INTERFACE;
  rDbi.dbcc_reserved   := 0;
  rDbi.dbcc_classguid  := GUID_DEVINTF_USB_DEVICE;
  rDbi.dbcc_name       := #0;
  RegisterDeviceNotification(FHandle,@rDbi,DEVICE_NOTIFY_WINDOW_HANDLE);
end;


end.
