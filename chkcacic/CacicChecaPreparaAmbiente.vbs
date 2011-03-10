'==========================================================================================================================================================
' Código VBScript para Checagem e Preparação do Ambiente Computacional Baseado no Sistema Operacional MS-Windows para Instalação do Sistema
' CACIC - Configurador Automático e Coletor de Informações Computacionais
'
' NOME: CacicChecaPreparaAmbiente.vbs
'
' AUTOR: Anderson Peterle - anderson.peterle@previdencia.gov.br
' DATA : 21/09/2009 01:36AM
'
' OBJETIVOS: 
' 1) Verificar a existência do programa executável referente ao processo Mantenedor de Integridade do Sistema CACIC nas estações de trabalho com MS-Windows
' 2) Caso o objetivo 1 seja positivo, exclusão de todos os arquivos e chaves de execução automática (Registry) referentes às versões antigas do CACIC
'
' EXECUÇÃO: cscript CacicChecaPreparaAmbiente.vbs <PastaCheckCacic> //B
'==========================================================================================================================================================

' Crio o objeto para os trabalhos com arquivos e diretórios
Set fileSys  = CreateObject("Scripting.FileSystemObject")

' Verifico a existência do executável do Serviço para Manutenção de Integridade do Agente Principal
' Caso não exista o executável do serviço, entendo que a estação contém alguma versão antiga do CACIC
If not fileSys.FileExists(fileSys.GetSpecialFolder(0) & "\cacicsvc.exe") Then
	' Crio um objeto para acesso ao Registry
	Set WSHShell = CreateObject("WScript.Shell")

	' Exclusão da chave para execução automática do Agente Principal (cacic2.exe)	
	If RegExist("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\cacic2") Then 
		WSHShell.RegDelete( "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\cacic2" )
	End If

	' Exclusão da chave para execução automática do Agente Verificador de Integridade (chksis.exe)	
	If RegExist("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\CheckSystemRoutine") Then 	
		WSHShell.RegDelete( "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\CheckSystemRoutine" )
	End If
		
	' Exclusão dos arquivos que compõem o Verificador de Integridade do Sistema (ChkSis)
	' O "TRUE" é para confirmar a exclusão de arquivos ReadOnly
	If fileSys.FileExists(fileSys.GetSpecialFolder(0) & "\chksis.exe") Then fileSys.DeleteFile(fileSys.GetSpecialFolder(0) & "\chksis.exe"),TRUE	
	If fileSys.FileExists(fileSys.GetSpecialFolder(0) & "\chksis.ini") Then fileSys.DeleteFile(fileSys.GetSpecialFolder(0) & "\chksis.ini"),TRUE	
	If fileSys.FileExists(fileSys.GetSpecialFolder(0) & "\chksis.dat") Then fileSys.DeleteFile(fileSys.GetSpecialFolder(0) & "\chksis.dat"),TRUE	
	If fileSys.FileExists(fileSys.GetSpecialFolder(0) & "\chksis.log") Then fileSys.DeleteFile(fileSys.GetSpecialFolder(0) & "\chksis.log"),TRUE				

    
	' Exclusão da pasta de instalação do CACIC
	Set objArgs = WScript.Arguments
	if objArgs.Count > 0 Then 
		strCacicFolder = GetINIString("Cacic2", "cacic_dir", "Cacic", objArgs(0))	
		if fileSys.FolderExists(Left(fileSys.GetSpecialFolder(0), 3) & strCacicFolder) Then
			fileSys.DeleteFolder(Left(fileSys.GetSpecialFolder(0), 3) & strCacicFolder)		
		End If
	End If
End If

' Função para verificação de existência de chave do Registry
Function RegExist(Key)
	On Error Resume Next
	Set WshShellChecaReg=Wscript.CreateObject("Wscript.Shell")
	Kexist=WshShellChecaReg.RegRead(Key)
	If Err.number=0 then
		RegExist=True
	Else
		RegExist=False
	End If
End Function

' Função para leitura de chave em arquivo INI
Function GetINIString(Section, KeyName, Default, FileName)
  Dim INIContents, PosSection, PosEndSection, sContents, Value, Found
  
  ' Carrega o conteúdo do arquivo INI em uma string
  INIContents = GetFile(FileName)

  ' Procura pela seção
  PosSection = InStr(1, INIContents, "[" & Section & "]", vbTextCompare)
  If PosSection>0 Then
    ' Caso a seção exista, encontra o seu fim
    PosEndSection = InStr(PosSection, INIContents, vbCrLf & "[")
    ' Se for a última seção...
    If PosEndSection = 0 Then PosEndSection = Len(INIContents)+1
    
    ' Separa os conteúdos da seção
    sContents = Mid(INIContents, PosSection, PosEndSection - PosSection)

    If InStr(1, sContents, vbCrLf & KeyName & "=", vbTextCompare)>0 Then
      Found = True
      ' Separa valor de chave
      Value = SeparateField(sContents, vbCrLf & KeyName & "=", vbCrLf)
    End If
  End If
  If isempty(Found) Then Value = Default
  GetINIString = Value
End Function

' Separa um campo entre Inicio e Fim
Function SeparateField(ByVal sFrom, ByVal sStart, ByVal sEnd)
  Dim PosB: PosB = InStr(1, sFrom, sStart, 1)
  If PosB > 0 Then
    PosB = PosB + Len(sStart)
    Dim PosE: PosE = InStr(PosB, sFrom, sEnd, 1)
    If PosE = 0 Then PosE = InStr(PosB, sFrom, vbCrLf, 1)
    If PosE = 0 Then PosE = Len(sFrom) + 1
    SeparateField = Mid(sFrom, PosB, PosE - PosB)
  End If
End Function


' Função para leitura de um arquivo
Function GetFile(ByVal FileName)
  Dim FS: Set FS = CreateObject("Scripting.FileSystemObject")
  ' Caso não seja informada a pasta, usa a do MS-Windows
  If InStr(FileName, ":\") = 0 And Left (FileName,2)<>"\\" Then 
    FileName = FS.GetSpecialFolder(0) & "\" & FileName
  End If
  On Error Resume Next

  GetFile = FS.OpenTextFile(FileName).ReadAll
End Function