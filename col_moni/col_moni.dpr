(**
---------------------------------------------------------------------------------------------------------------------------------------------------------------
Copyright 2000, 2001, 2002, 2003, 2004, 2005 Dataprev - Empresa de Tecnologia e Informações da Previdência Social, Brasil

Este arquivo é parte do programa CACIC - Configurador Automático e Coletor de Informações Computacionais

O CACIC é um software livre; você pode redistribui-lo e/ou modifica-lo dentro dos termos da Licença Pública Geral GNU como
publicada pela Fundação do Software Livre (FSF); na versão 2 da Licença, ou (na sua opinião) qualquer versão.

Este programa é distribuido na esperança que possa ser  util, mas SEM NENHUMA GARANTIA; sem uma garantia implicita de ADEQUAÇÂO a qualquer
MERCADO ou APLICAÇÃO EM PARTICULAR. Veja a Licença Pública Geral GNU para maiores detalhes.

Você deve ter recebido uma cópia da Licença Pública Geral GNU, sob o título "LICENCA.txt", junto com este programa, se não, escreva para a Fundação do Software
Livre(FSF) Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
---------------------------------------------------------------------------------------------------------------------------------------------------------------
*)

program col_moni;
{$R *.res}

uses
  Windows,
  sysutils,
  Classes,
  CACIC_Library in '..\CACIC_Library.pas';

var
  v_Res_Search,
  v_Drive,
  v_File                : String;

var
  g_oCacic              : TCACIC;

const
  CACIC_APP_NAME        = 'col_moni';

procedure GetSubDirs(Folder:string; sList:TStringList);
 var
  sr:TSearchRec;
begin
  if FindFirst(Folder+'*.*',faDirectory,sr)=0 then
   try
    repeat
      if(sr.Attr and faDirectory)=faDirectory then
       sList.Add(sr.Name);
    until FindNext(sr)<>0;
   finally
    FindClose(sr);
   end;
end;

// Baixada de http://www.infoeng.hpg.ig.com.br/borland_delphi_dicas_2.htm
function LetrasDrives: string;
var
Drives: DWord;
I, Tipo: byte;
v_Unidade : string;
begin
Result := '';
Drives := GetLogicalDrives;
if Drives <> 0 then
for I := 65 to 90 do
  if ((Drives shl (31 - (I - 65))) shr 31) = 1 then
    Begin
      v_Unidade := Char(I) + ':\';
      Tipo := GetDriveType(PChar(v_Unidade));
      case Tipo of
        DRIVE_FIXED: Result := Result + Char(I);
      end;
    End;
end;

// By Muad Dib 2003
// at http://www.planet-source-code.com.
// Excelente!!!
function SearchFile(p_Drive,p_File:string) : boolean;
var sr:TSearchRec;
    sDirList:TStringList;
    i:integer;
begin
   Result := false;
   v_Res_Search := '';
   if FindFirst(p_Drive+p_File,faAnyFile,sr) = 0 then
    Begin
      v_Res_Search := p_Drive+p_File;
      Result := true;
    End
   else
    Begin
     repeat
     until FindNext(sr)<>0;
        FindClose(sr);
        sDirList:= TStringList.Create;
        try
         GetSubDirs(p_Drive,sDirList);
         for i:=0 to sDirList.Count-1 do
            if (sDirList[i]<>'.') and (sDirList[i]<>'..') then
             begin
              //Application.ProcessMessages;
              if (SearchFile(IncludeTrailingPathDelimiter(p_Drive+sDirList[i]),p_File)) then
                Begin
                  Result := true;
                  Break;
                End;
             end;
         finally
         sDirList.Free;
    End;
   end;
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


procedure Executa_Col_moni;
var tstrTripa2, tstrTripa3, v_array1, v_array2, v_array3, v_array4 : TStrings;
    strAux, strAux1, strAux3, strAux4, strTripa, ValorChavePerfis, UVC, v_LetrasDrives, v_Data : String;
    intAux4, v1, v3, v_achei : Integer;

begin
  Try
   g_oCacic.setValueToFile('Col_Moni','Inicio', g_oCacic.enCrypt( FormatDateTime('hh:nn:ss', Now)), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
   // Verifica se deverá ser realizada a coleta de informações de sistemas monitorados neste
   // computador, perguntando ao Gerente de Coletas.
   g_oCacic.writeDailyLog('Coletando informações de Sistemas Monitorados.');
   ShortDateFormat := 'dd/mm/yyyy';
   intAux4          := 1;
   strAux3          := '';
   ValorChavePerfis := '*';
   v_LetrasDrives   := LetrasDrives;

   while ValorChavePerfis <> '' do
      begin
         strAux3 := 'SIS' + trim(inttostr(intAux4));
         strTripa := ''; // Conterá as informações a serem enviadas ao Gerente.
         // Obtenho do registro o valor que foi previamente armazenado
         ValorChavePerfis := Trim(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Coletas',strAux3,g_oCacic.getLocalFolder + 'GER_COLS.inf')));

         if (ValorChavePerfis <> '') then
           Begin
               //Atenção, OS ELEMENTOS DEVEM ESTAR DE ACORDO COM A ORDEM QUE SÃO TRATADOS NO MÓDULO GERENTE.
               tstrTripa2  := g_oCacic.explode(ValorChavePerfis,',');
               if (strAux <> '') then strAux := strAux + '#';
               strAux := strAux + trim(tstrTripa2[0]) + ',';


               ///////////////////////////////////////////
               ///// Coleta de Informação de Licença /////
               ///////////////////////////////////////////

               //Vazio
               if (trim(tstrTripa2[2])='0') then
                 Begin
                    strAux := strAux + ',';
                 End;

               //Caminho\Chave\Valor em Registry
               if (trim(tstrTripa2[2])='1') then
                 Begin
                    strAux4 := '';
                    g_oCacic.writeDebugLog('Buscando informação de LICENÇA em '+tstrTripa2[3]);
                    Try
                      strAux4 := Trim(g_oCacic.getValueRegistryKey(trim(tstrTripa2[3])));
                    Except
                    End;
                    if (strAux4 = '') then strAux4 := '?';
                    strAux  := strAux + strAux4 + ',';
                 End;

               //Nome/Seção/Chave de Arquivo INI
               if (trim(tstrTripa2[2])='2') then
                 Begin
                    g_oCacic.writeDebugLog('Buscando informação de LICENÇA em '+tstrTripa2[3]);
                    Try
                      if (LastPos('/',trim(tstrTripa2[3]))>0) then
                        Begin
                          tstrTripa3  := g_oCacic.explode(trim(tstrTripa2[3]),'/');
                          //
                          for v1:=1 to length(v_LetrasDrives) do
                            Begin
                              v_File := trim(tstrTripa3[0]);
                              if (LastPos(':\',v_File)>0) then
                                Begin
                                  v_Drive := Copy(v_File,1,3);
                                  v_File  := Copy(v_File,4,Length(v_File));
                                End
                              else
                                Begin
                                  v_Drive := v_LetrasDrives[v1] + ':';
                                  if (Copy(v_File,1,1)<>'\') then v_Drive := v_Drive + '\';
                                  v_File  := Copy(v_File,1,Length(v_File));
                                End;

                              strAux1 := ExtractShortPathName(v_Drive + v_File);
                              if (strAux1 = '') then
                                begin
                                  if (SearchFile(v_Drive,v_File)) then
                                    Begin
                                      strAux1 := v_Res_Search;
                                      break;
                                    End;
                                end
                              else break;
                            End;

                          strAux4 := Trim(g_oCacic.GetValueFromFile(tstrTripa3[1],tstrTripa3[2],strAux1));
                          if (strAux4 = '') then strAux4 := '?';
                          strAux := strAux + strAux4 + ',';
                        End;

                      if (LastPos('/',trim(tstrTripa2[3]))=0) then
                        Begin
                          strAux := strAux + 'Parâm.Lic.Incorreto,';
                        End
                    Except
                        strAux := strAux + 'Parâm.Lic.Incorreto,';
                    End;
                 End;



               //////////////////////////////////////////////
               ///// Coleta de Informação de Instalação /////
               //////////////////////////////////////////////

               //Vazio
               if (trim(tstrTripa2[5])='0') then
                 Begin
                    strAux := strAux + ',';
                 End;

               //Nome de Executável OU Nome de Arquivo de Configuração (CADPF!!!)
               if (trim(tstrTripa2[5])='1') or (trim(tstrTripa2[5]) = '2') then
                 Begin
                  strAux1 := '';
                  for v1:=1 to length(v_LetrasDrives) do
                    Begin
                    v_File := trim(tstrTripa2[6]);
                    g_oCacic.writeDebugLog('Buscando informação de INSTALAÇÃO em '+tstrTripa2[6]);
                    if (LastPos(':\',v_File)>0) then
                      Begin
                        v_Drive := Copy(v_File,1,3);
                        v_File  := Copy(v_File,4,Length(v_File));
                      End
                    else
                      Begin
                        v_Drive := v_LetrasDrives[v1] + ':';
                        if (Copy(v_File,1,1)<>'\') then v_Drive := v_Drive + '\';
                        v_File  := Copy(v_File,1,Length(v_File));
                      End;

                      strAux1 := ExtractShortPathName(v_Drive + v_File);
                      if (strAux1 = '') then
                        begin
                          if (SearchFile(v_Drive,v_File)) then
                            Begin
                              strAux1 := v_Res_Search;
                              break;
                            End;
                        end
                      else break;

                    End;

                  if (strAux1 <> '') then strAux := strAux + 'S,';
                  if (strAux1 = '')  then strAux := strAux + 'N,';
                  strAux1 := '';
                 End;

               //Caminho\Chave\Valor em Registry
               if (trim(tstrTripa2[5])='3') then
                 Begin
                  strAux1 := '';
                  Try
                    g_oCacic.writeDebugLog('Buscando informação de INSTALAÇÃO em '+tstrTripa2[6]);
                    strAux1 := Trim(g_oCacic.getValueRegistryKey(trim(tstrTripa2[6])));
                  Except
                  End;
                  if (strAux1 <> '') then strAux  := strAux + 'S,';
                  if (strAux1 = '') then strAux := strAux + 'N,';
                  strAux1 := '';
                 End;



               //////////////////////////////////////////
               ///// Coleta de Informação de Versão /////
               //////////////////////////////////////////

               //Vazio
               if (trim(tstrTripa2[7])='0') then
                 Begin
                    strAux := strAux + ',';
                 End;

               //Data de Arquivo
               if (trim(tstrTripa2[7])='1') then
                 Begin
                  strAux1 := '';
                  g_oCacic.writeDebugLog('Buscando informação de VERSÃO em '+tstrTripa2[8]);
                  for v1:=1 to length(v_LetrasDrives) do
                    Begin
                    v_File := trim(tstrTripa2[8]);
                    if (LastPos(':\',v_File)>0) then
                      Begin
                        v_Drive := Copy(v_File,1,3);
                        v_File  := Copy(v_File,4,Length(v_File));
                      End
                    else
                      Begin
                        v_Drive := v_LetrasDrives[v1] + ':';
                        if (Copy(v_File,1,1)<>'\') then v_Drive := v_Drive + '\';
                        v_File  := Copy(v_File,1,Length(v_File));
                      End;

                      strAux1 := ExtractShortPathName(v_Drive + v_File);
                      if (strAux1 = '') then
                        begin
                          if (SearchFile(v_Drive,v_File)) then
                            Begin
                              strAux1 := v_Res_Search;
                              break;
                            End;
                        end
                      else break;
                    End;

                  if (strAux1 <> '') then
                    Begin
                      v_Data := StringReplace(DateToStr(FileDateToDateTime(FileAge(strAux1))),'.','/',[rfReplaceAll]);
                      v_Data := StringReplace(v_Data,'-','/',[rfReplaceAll]);
                      strAux := strAux + v_Data + ',';
                      v_Data := '';
                    End;

                  if (strAux1 = '') then strAux := strAux + '?,';
                  strAux1 := '';
                 End;

               //Caminho\Chave\Valor em Registry
               if (trim(tstrTripa2[7])='2') then
                 Begin
                  strAux1 := '';
                  g_oCacic.writeDebugLog('Buscando informação de VERSÃO em '+tstrTripa2[8]);
                  Try
                    strAux1 := Trim(g_oCacic.getValueRegistryKey(trim(tstrTripa2[8])));
                  Except
                  End;
                  if (strAux1 <> '') then strAux := strAux + strAux1 + ',';
                  if (strAux1 = '') then strAux := strAux + '?,';
                  strAux1 := '';
                 End;


               //Nome/Seção/Chave de Arquivo INI
               if (trim(tstrTripa2[7])='3') then
                 Begin
                    Try
                      g_oCacic.writeDebugLog('Buscando informação de VERSÃO em '+tstrTripa2[8]);
                      if (LastPos('/',trim(tstrTripa2[8]))>0) then
                        Begin
                          tstrTripa3  := g_oCacic.explode(trim(tstrTripa2[8]),'/');
                          //
                          for v1:=1 to length(v_LetrasDrives) do
                            Begin
                              v_File := trim(tstrTripa3[0]);
                              if (LastPos(':\',v_File)>0) then
                                Begin
                                  v_Drive := Copy(v_File,1,3);
                                  v_File  := Copy(v_File,4,Length(v_File));
                                End
                              else
                                Begin
                                  v_Drive := v_LetrasDrives[v1] + ':';
                                  if (Copy(v_File,1,1)<>'\') then v_Drive := v_Drive + '\';
                                  v_File  := Copy(v_File,1,Length(v_File));
                                End;

                              strAux1 := ExtractShortPathName(v_Drive + v_File);
                              if (strAux1 = '') then
                                begin
                                  if (SearchFile(v_Drive,v_File)) then
                                    Begin
                                      strAux1 := v_Res_Search;
                                      break;
                                    End;
                                end
                              else break;
                            End;

                          //
                          strAux4 := Trim(g_oCacic.GetValueFromFile(tstrTripa3[1],tstrTripa3[2],strAux1));
                          if (strAux4 = '') then strAux4 := '?';
                          strAux := strAux + strAux4 + ',';
                        End
                      else
                        Begin
                          strAux := strAux + 'Parâm.Versao Incorreto,';
                        End;
                    Except
                    End;
                 End;


             //Versão de Executável
             if (trim(tstrTripa2[7])='4') then
               Begin
                 g_oCacic.writeDebugLog('Buscando informação de VERSÃO em '+tstrTripa2[8]);
                 Try
                  v_achei := 0;
                  for v1:=1 to length(v_LetrasDrives) do
                    Begin
                      if v_achei = 0 then
                        Begin
                          v_File := trim(tstrTripa2[8]);
                          if (LastPos(':\',v_File)>0) then
                            Begin
                              v_Drive := Copy(v_File,1,3);
                              v_File  := Copy(v_File,4,Length(v_File));
                            End
                          else
                            Begin
                              v_Drive := v_LetrasDrives[v1] + ':';
                              if (Copy(v_File,1,1)<>'\') then v_Drive := v_Drive + '\';
                              v_File  := Copy(v_File,1,Length(v_File));
                            End;

                          strAux1 := ExtractShortPathName(v_Drive + v_File);
                          if (strAux1 = '') then
                            begin
                            if (SearchFile(v_Drive,v_File)) then
                              Begin
                                strAux1 := v_Res_Search;
                                v_achei := 1;
                              End;
                            end
                          else v_achei := 1;
                        End;
                    End;
                 Except
                 End;

                 if (strAux1 <> '') then
                    Begin
                      strAux := strAux + g_oCacic.GetVersionInfo(strAux1);
                    End
                else strAux := strAux + '?';

                strAux := strAux + ',';

               End;


               //////////////////////////////////////////
               ///// Coleta de Informação de Engine /////
               //////////////////////////////////////////

               //Vazio
               if (trim(tstrTripa2[9])='.') then
                 Begin
                    strAux := strAux + ',';
                 End;

               //Arquivo para Versão de Engine
               //O ponto é proposital para quando o último parâmetro vem vazio do Gerente!!!  :)
               if (trim(tstrTripa2[9])<>'.') then
                 Begin
                  g_oCacic.writeDebugLog('Buscando informação de ENGINE em '+tstrTripa2[9]);
                  for v1:=1 to length(v_LetrasDrives) do
                    Begin
                      v_File := trim(tstrTripa2[9]);
                      if (LastPos(':\',v_File)>0) then
                        Begin
                          v_Drive := Copy(v_File,1,3);
                          v_File  := Copy(v_File,4,Length(v_File));
                        End
                      else
                        Begin
                          v_Drive := v_LetrasDrives[v1] + ':';
                          if (Copy(v_File,1,1)<>'\') then v_Drive := v_Drive + '\';
                          v_File  := Copy(v_File,1,Length(v_File));
                        End;

                      strAux1 := ExtractShortPathName(v_Drive + v_File);
                      if (strAux1 = '') then
                        begin
                          if (SearchFile(v_Drive,v_File)) then
                            Begin
                              strAux1 := v_Res_Search;
                              break;
                            End;
                        end
                      else break;
                    End;
                  if (strAux1 <> '') then
                    Begin
                      tstrTripa3 := g_oCacic.explode(g_oCacic.GetVersionInfo(strAux1), '.'); // Pego só os dois primeiros dígitos. Por exemplo: 6.640.0.1001  vira  6.640.
                      strAux := strAux + tstrTripa3[0] + '.' + tstrTripa3[1];
                    End;
                 End;


               ///////////////////////////////////////////
               ///// Coleta de Informação de Pattern /////
               ///////////////////////////////////////////

               //Arquivo para Versão de Pattern
               //O ponto é proposital para quando o último parâmetro vem vazio do Gerente!!!  :)
               strAux1 := '';
               if (trim(tstrTripa2[10])<>'.') then
                 Begin
                  g_oCacic.writeDebugLog('Buscando informação de PATTERN em '+tstrTripa2[9]);
                    for v1:=1 to length(v_LetrasDrives) do
                      Begin
                      v_File := trim(tstrTripa2[10]);
                      if (LastPos(':\',v_File)>0) then
                        Begin
                          v_Drive := Copy(v_File,1,3);
                          v_File  := Copy(v_File,4,Length(v_File));
                        End
                      else
                        Begin
                          v_Drive := v_LetrasDrives[v1] + ':';
                          if (Copy(v_File,1,1)<>'\') then v_Drive := v_Drive + '\';
                          v_File  := Copy(v_File,1,Length(v_File));
                        End;

                        strAux1 := ExtractShortPathName(v_Drive + v_File);
                        if (strAux1 = '') then
                          begin
                          if (SearchFile(v_Drive, v_File)) then
                            Begin
                              strAux1 := v_Res_Search;
                              break;
                            End;
                        end
                      else break;

                      End;
                 End;
                 if (strAux1 <> '') then
                    Begin
                      tstrTripa3 := g_oCacic.explode(g_oCacic.GetVersionInfo(strAux1), '.'); // Pego só os dois primeiros dígitos. Por exemplo: 6.640.0.1001  vira  6.640.
                      strAux := strAux + tstrTripa3[0] + '.' + tstrTripa3[1];
                    End;
                 if (strAux1 = '') then strAux := strAux + ',';
                 strAux1 := '';
           End;
           intAux4 := intAux4 + 1;
      End;

      UVC := Trim(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Coletas','Sistemas_Monitorados',g_oCacic.getLocalFolder + 'GER_COLS.inf')));

      g_oCacic.setValueToFile('Col_Moni','Fim', g_oCacic.enCrypt( FormatDateTime('hh:nn:ss', Now)), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);

      If (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Configs','IN_COLETA_FORCADA_MONI',g_oCacic.getLocalFolder + 'GER_COLS.inf'))='S') or (trim(strAux) <> trim(UVC)) Then
        Begin
          if (trim(UVC) <> '') then
            begin
              v_array1  :=  g_oCacic.explode(strAux, '#');
              strAux    :=  '';
              v_array3  :=  g_oCacic.explode(UVC, '#');
              for v1 := 0 to (v_array1.count)-1 do
                Begin
                  v_array2  :=  g_oCacic.explode(v_array1[v1], ',');
                  v_achei   :=  0;
                  for v3 := 0 to (v_array3.count)-1 do
                    Begin
                      v_array4  :=  g_oCacic.explode(v_array3[v3], ',');
                      if (v_array4=v_array2) then v_achei := 1;
                    End;
                  if (v_achei = 0) then
                    Begin
                      if (strAUX <> '') then strAUX :=  strAUX + '#';
                      strAUX  :=  strAUX + v_array1[v1];
                    End;
                End;
              end;
          g_oCacic.writeDebugLog('Coleta anterior: '+UVC);
          g_oCacic.writeDebugLog('Coleta atual...: '+strAux);
          g_oCacic.setValueToFile('Col_Moni','UVC', g_oCacic.enCrypt( strAux), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        end
      else
        Begin
          g_oCacic.writeDebugLog('Nenhuma Coleta Efetuada');
          g_oCacic.setValueToFile('Col_Moni','nada',g_oCacic.enCrypt( 'nada'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
        End;

  Except
    Begin
      g_oCacic.setValueToFile('Col_Moni','nada',g_oCacic.enCrypt( 'nada'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
      g_oCacic.setValueToFile('Col_Moni','Fim',g_oCacic.enCrypt( '99999999'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
    End;
  End;
END;

begin
   g_oCacic := TCACIC.Create();

   g_oCacic.setBoolCipher(true);

   if( not g_oCacic.isAppRunning( CACIC_APP_NAME ) ) then
    if (ParamCount>0) then
        Begin
          g_oCacic.setLocalFolder( g_oCacic.GetParam('LocalFolder') );

          if (g_oCacic.getLocalFolder <> '') then
            Begin
               g_oCacic.checkDebugMode;

               Try
                 Executa_Col_moni;
               Except
                 g_oCacic.setValueToFile('Col_Moni','nada',g_oCacic.enCrypt( 'nada'), g_oCacic.getLocalFolder + 'Temp\' + g_oCacic.getInfFileName);
               End;
            End;
        End;

    g_oCacic.Free();

end.
