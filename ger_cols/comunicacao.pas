unit comunicacao;

interface
Uses Classes, SysUtils, XML, IdFTP, IdFTPCommon;

Function ComunicaServidor(URL : String; Request : TStringList; MsgAcao: String) : String;
Function FTP_Get(Arq : String; DirDestino : String) : Boolean;
//Function Download(URL : String; DirDestino : String) : Boolean;
implementation

Uses main, Utils, registro, utils_cacic, dialogs;

Function FTP_Get(Arq : String; DirDestino : String) : Boolean;
var v_te_senha_login_serv_updates : string;
    IdFTP1 : TIdFTP;
begin
    v_te_senha_login_serv_updates := utils_cacic.DesCrip(registro.GetValorChaveRegIni('Configs','TE_SENHA_LOGIN_SERV_UPDATES',p_path_cacic_ini));
    v_te_senha_login_serv_updates := StringReplace(v_te_senha_login_serv_updates,'abc%aeiou#+@encryptation','',[rfReplaceAll]);
    v_te_senha_login_serv_updates := StringReplace(v_te_senha_login_serv_updates,'aeiou&abc@v$eryeasyencryptation','',[rfReplaceAll]);
    IdFTP1               := TIdFTP.Create(IdFTP1);
    IdFTP1.Host          := Registro.GetValorChaveRegIni('Configs','TE_SERV_UPDATES', p_path_cacic_ini);
    IdFTP1.Username      := registro.GetValorChaveRegIni('Configs','NM_USUARIO_LOGIN_SERV_UPDATES',p_path_cacic_ini);
    IdFTP1.Password      := v_te_senha_login_serv_updates;
    IdFTP1.Port          := strtoint(registro.GetValorChaveRegIni('Configs','NU_PORTA_SERV_UPDATES',p_path_cacic_ini));
    IdFTP1.TransferType  := ftBinary;

    Try
      if IdFTP1.Connected = true then
        begin
          IdFTP1.Disconnect;
        end;
      IdFTP1.Connect(true);
      IdFTP1.ChangeDir(Registro.GetValorChaveRegIni('Configs','TE_PATH_SERV_UPDATES', p_path_cacic_ini));
      Try
        IdFTP1.Get(Arq, DirDestino + '\' + Arq, True);
        result := true;
      Except
        result := false;
      End;
    Except
        result := false;
    end;
    IdFTP1.Free
end;

Function ComunicaServidor(URL : String; Request : TStringList; MsgAcao: String) : String;
var Response_CS: TStringStream;
var strEndereco : String;
Begin
    strEndereco := 'http://' + registro.GetValorChaveRegIni('Configs','EnderecoServidor',p_path_cacic_ini) + registro.GetValorChaveRegIni('Configs','Endereco_WS',p_path_cacic_ini) + URL;
    if (trim(MsgAcao)='') then Begin MsgAcao := '>> Enviando informações ao servidor e obtendo parâmetros iniciais.'; End;
    if (trim(MsgAcao)<>'.') then main.frmMain.Log_Historico(MsgAcao);
    Response_CS := TStringStream.Create('');
    Try
       main.frmMain.IdHTTP1.Post(strEndereco, Request, Response_CS);
    Except
       main.frmMain.Log_Historico('ERRO: Impossível estabelecer comunicação com o endereço ' + strEndereco + Response_CS.DataString);
       result := '0';
       Exit;
    end;

    if (UpperCase(XML_RetornaValor('Status', Response_CS.DataString)) <> 'OK') Then
      Begin
         main.frmMain.Log_Historico('Houve problemas durante a comunicação. A mensagem retornada pelo sistema foi: ' + Response_CS.DataString);
         result := '0';
      end
    Else
      Begin
         result := Response_CS.DataString;
      end;
    Response_CS.Free;
end;
end.
