unit utils;

interface

Uses Classes, SysUtils, Windows, TLHELP32, dialogs, main;

Function Explode(Texto, Separador : String) : TStrings;
Function RemoveCaracteresEspeciais(Texto : String) : String;
function ProgramaRodando(NomePrograma: String): Boolean;
function API_GetEnvironmentVariable(EnVar : string) : string;
Function getVersionInfo(Arquivo : String): String;
function LastPos(SubStr, S: string): Integer;
function LetrasDrives : string;


implementation

function LetrasDrives : string;
var i:integer;
strAux : string;
  begin
        frmmain.MSystemInfo.Disk.GetInfo;
        with main.frmMain.MSystemInfo.Disk do
        begin
          for i:=1 to length(AvailableDisks) do
          begin
             Drive := UpperCase(Copy(AvailableDisks,i,1)) + ':';
             if (UpperCase(GetMediaTypeStr(MediaType)) = 'FIXED') then
             Begin
                 strAux := strAux + UpperCase(Copy(Drive,1,1));
             end;
          end;
        end;
        Result := strAux;
  end;


function LastPos(SubStr, S: string): Integer;
var
  Found, Len, Pos: integer;
begin
  Pos := Length(S);
  Len := Length(SubStr);
  Found := 0;
  while (Pos > 0) and (Found = 0) do
  begin
    if Copy(S, Pos, Len) = SubStr then
      Found := Pos;
    Dec(Pos);
  end;
  LastPos := Found;
end;
Function Explode(Texto, Separador : String) : TStrings;
var
    strItem : String;
    ListaAuxUTILS : TStrings;
    NumCaracteres, I : Integer;
Begin
    ListaAuxUTILS := TStringList.Create;
    strItem := '';
    NumCaracteres := Length(Texto);
    For I := 0 To NumCaracteres Do
    If (Texto[I] = Separador) or (I = NumCaracteres) Then
    Begin
       If (I = NumCaracteres) then strItem := strItem + Texto[I];
       ListaAuxUTILS.Add(Trim(strItem));
       strItem := '';
    end
    Else strItem := strItem + Texto[I];
      Explode := ListaAuxUTILS;
//Não estava sendo liberado
//    ListaAuxUTILS.Free;
//Ao ativar esta liberação tomei uma baita surra!!!!  11/05/2004 - 20:30h - Uma noite muito escura!  :)  Anderson Peterle
end;


Function RemoveCaracteresEspeciais(Texto : String) : String;
var I : Integer;
    strAux : String;
Begin
   For I := 0 To Length(Texto) Do
     if ord(Texto[I]) in [32..126] Then
           strAux := strAux + Texto[I]
     else strAux := strAux + ' ';  // Coloca um espaço onde houver caracteres especiais
   Result := strAux;
end;


function ProgramaRodando(NomePrograma: String): Boolean;
var
  IsRunning, ContinueTest: Boolean;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  IsRunning := False;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := Sizeof(FProcessEntry32);
  ContinueTest := Process32First(FSnapshotHandle, FProcessEntry32);
  while ContinueTest do
  begin
    IsRunning :=  UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) = UpperCase(NomePrograma);
    if IsRunning then  ContinueTest := False
    else ContinueTest := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
  Result := IsRunning;
end;

function API_GetEnvironmentVariable(EnVar : string) : string;
//
// Retorna informações sobre uma variável do ambiente
//
var
pEnvStrings : pointer;
begin
pEnvStrings := GetEnvironmentStrings;
SetLength(Result, 256);
SetLength(Result, GetEnvironmentVariable(pchar(EnVar), pchar(Result),256));
FreeEnvironmentStrings(pEnvStrings);
end;

function getVersionInfo(Arquivo : String) : String;
var
   VerInfoSize, VerValueSize, Dummy : DWORD;
   VerInfo : Pointer;
   VerValue : PVSFixedFileInfo;
   V1,       // Major Version
   V2,       // Minor Version
   V3,       // Release
   V4: Word; // Build Number
begin
    Try
       VerInfoSize := GetFileVersionInfoSize(PChar(ParamStr(0)), Dummy);
       GetMem(VerInfo, VerInfoSize);
       GetFileVersionInfo(PChar(Arquivo), 0, VerInfoSize, VerInfo);
       VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize);
       With VerValue^ do
       begin
         V1 := dwFileVersionMS shr 16;
         V2 := dwFileVersionMS and $FFFF;
         V3 := dwFileVersionLS shr 16;
         V4 := dwFileVersionLS and $FFFF;
       end;
       FreeMem(VerInfo, VerInfoSize);
       Result := IntToStr(V1) + '.' + IntToStr(V2) + '.' + IntToStr(V3) + '.' + IntToStr(V4);
    Except
       Result := ''; 
    End;
end;



end.
