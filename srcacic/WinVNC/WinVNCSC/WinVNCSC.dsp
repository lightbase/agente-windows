# Microsoft Developer Studio Project File - Name="winvncsc" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Application" 0x0101

CFG=winvncsc - Win32 Release
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "winvnc2.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "winvnc2.mak" CFG="winvncsc - Win32 Release"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "winvncsc - Win32 Release" (based on "Win32 (x86) Application")
!MESSAGE "winvncsc - Win32 Debug" (based on "Win32 (x86) Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=xicl6.exe
MTL=midl.exe
RSC=rc.exe

!IF  "$(CFG)" == "winvncsc - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /MT /W3 /GX /Zi /O2 /I "..\omnithread" /I ".." /I "..\.." /D "NDEBUG" /D "__x86__" /D "__WIN32__" /D "WIN32" /D "_WINDOWS" /D "_MBCS" /D _WIN32_WINNT=0x501 /D "XMD_H" /D "_WINSTATIC" /D _WIN32_IE=0x0500 /D "SINGLECLICKULTRA" /YX /FD /O3 /QaxWK /c
# SUBTRACT CPP /Fr
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x809 /d "NDEBUG"
# ADD RSC /l 0x809 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=xilink6.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /machine:I386
# ADD LINK32 ws2_32.lib  winmm.lib kernel32.lib user32.lib gdi32.lib shell32.lib advapi32.lib ole32.lib version.lib comctl32.lib /nologo /subsystem:windows /machine:I386
# SUBTRACT LINK32 /pdb:none /nodefaultlib
# Begin Special Build Tool
SOURCE="$(InputPath)"
PreLink_Cmds=cl /nologo /MT /Fo..\Release\ /Fd..\Release\ /c buildtime.cpp
# End Special Build Tool

!ELSEIF  "$(CFG)" == "winvncsc - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /YX /FD /GZ /c
# ADD CPP /nologo /MTd /W3 /Gm /GX /ZI /Od /I "..\omnithread" /I ".." /I "..\.." /D "_DEBUG" /D "__x86__" /D "__WIN32__" /D "WIN32" /D "_WINDOWS" /D "_MBCS" /D _WIN32_WINNT=0x501 /D "XMD_H" /D "_WINSTATIC" /D _WIN32_IE=0x0500 /D "SINGLECLICKULTRA" /Fr /YX /FD /GZ /c
# ADD BASE MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x809 /d "_DEBUG"
# ADD RSC /l 0x809 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=xilink6.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /debug /machine:I386 /pdbtype:sept
# ADD LINK32 ws2_32.lib winmm.lib kernel32.lib user32.lib gdi32.lib shell32.lib advapi32.lib ole32.lib version.lib  comctl32.lib /nologo /subsystem:windows /debug /machine:I386
# SUBTRACT LINK32 /profile
# Begin Special Build Tool
SOURCE="$(InputPath)"
PreLink_Cmds=cl /nologo /MTd /Fo..\Debug\ /Fd..\Debug\ /c buildtime.cpp
# End Special Build Tool

!ENDIF 

# Begin Target

# Name "winvncsc - Win32 Release"
# Name "winvncsc - Win32 Debug"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=.\black_layered.cpp
# End Source File
# Begin Source File

SOURCE=.\buildtime.cpp
# End Source File
# Begin Source File

SOURCE=..\..\DSMPlugin\DSMPlugin.cpp
# End Source File
# Begin Source File

SOURCE=.\HideDesktop.cpp
# End Source File
# Begin Source File

SOURCE=..\..\lzo\minilzo.c
# End Source File
# Begin Source File

SOURCE=.\rfbRegion.cpp
# PROP Exclude_From_Build 1
# End Source File
# Begin Source File

SOURCE=.\rfbRegion_X11.cxx
# End Source File
# Begin Source File

SOURCE=.\rfbUpdateTracker.cpp
# End Source File
# Begin Source File

SOURCE=.\stdhdrs.cpp
# End Source File
# Begin Source File

SOURCE=.\tableinitcmtemplate.cpp
# PROP Exclude_From_Build 1
# End Source File
# Begin Source File

SOURCE=.\tableinittctemplate.cpp
# PROP Exclude_From_Build 1
# End Source File
# Begin Source File

SOURCE=.\tabletranstemplate.cpp
# PROP Exclude_From_Build 1
# End Source File
# Begin Source File

SOURCE=.\TextChat.cpp
# End Source File
# Begin Source File

SOURCE=.\translate.cpp
# End Source File
# Begin Source File

SOURCE=.\videodriver.cpp
# End Source File
# Begin Source File

SOURCE=.\videodrivercheck.cpp
# End Source File
# Begin Source File

SOURCE=.\vncabout.cpp
# End Source File
# Begin Source File

SOURCE=.\vncbuffer.cpp
# End Source File
# Begin Source File

SOURCE=.\vncclient.cpp
# End Source File
# Begin Source File

SOURCE=.\vncdesktop.cpp
# End Source File
# Begin Source File

SOURCE=.\vncDesktopSW.cpp
# End Source File
# Begin Source File

SOURCE=.\vncdesktopthread.cpp
# End Source File
# Begin Source File

SOURCE=.\vncencodehext.cpp
# End Source File
# Begin Source File

SOURCE=.\vncencoder.cpp
# End Source File
# Begin Source File

SOURCE=.\vncencoderCursor.cpp
# End Source File
# Begin Source File

SOURCE=.\vncEncodeTight.cpp
# End Source File
# Begin Source File

SOURCE=.\vncencodezrle.cpp
# End Source File
# Begin Source File

SOURCE=.\vncinsthandler.cpp
# End Source File
# Begin Source File

SOURCE=.\vnckeymap.cpp
# End Source File
# Begin Source File

SOURCE=.\vnclog.cpp
# End Source File
# Begin Source File

SOURCE=.\vncmenu.cpp
# End Source File
# Begin Source File

SOURCE=.\vncMultiMonitor.cpp
# End Source File
# Begin Source File

SOURCE=.\vncOSVersion.cpp
# End Source File
# Begin Source File

SOURCE=.\vncproperties.cpp
# End Source File
# Begin Source File

SOURCE=.\vncpropertiesPoll.cpp
# End Source File
# Begin Source File

SOURCE=.\vncserver.cpp
# End Source File
# Begin Source File

SOURCE=.\vncservice.cpp
# End Source File
# Begin Source File

SOURCE=.\vncsockconnect.cpp
# End Source File
# Begin Source File

SOURCE=.\vsocket.cpp
# End Source File
# Begin Source File

SOURCE=.\winvncsc.cpp
# End Source File
# Begin Source File

SOURCE=.\winvncsc.rc
# End Source File
# Begin Source File

SOURCE=..\..\ZipUnZip32\ZipUnzip32.cpp
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# Begin Source File

SOURCE=.\d3des.h
# End Source File
# Begin Source File

SOURCE=..\..\DSMPlugin\DSMPlugin.h
# End Source File
# Begin Source File

SOURCE=.\keysymdef.h
# End Source File
# Begin Source File

SOURCE=.\MultiMon.h
# End Source File
# Begin Source File

SOURCE=.\resource.h
# End Source File
# Begin Source File

SOURCE=.\rfb.h
# End Source File
# Begin Source File

SOURCE=.\rfbMisc.h
# End Source File
# Begin Source File

SOURCE=.\rfbRect.h
# End Source File
# Begin Source File

SOURCE=.\rfbRegion.h
# End Source File
# Begin Source File

SOURCE=.\rfbRegion_win32.h
# End Source File
# Begin Source File

SOURCE=.\rfbRegion_X11.h
# End Source File
# Begin Source File

SOURCE=.\rfbUpdateTracker.h
# End Source File
# Begin Source File

SOURCE=.\stdhdrs.h
# End Source File
# Begin Source File

SOURCE=.\TextChat.h
# End Source File
# Begin Source File

SOURCE=.\translate.h
# End Source File
# Begin Source File

SOURCE=.\videodriver.h
# End Source File
# Begin Source File

SOURCE=.\vnc.hh
# End Source File
# Begin Source File

SOURCE=.\vncabout.h
# End Source File
# Begin Source File

SOURCE=.\vncacceptdialog.h
# End Source File
# Begin Source File

SOURCE=.\vncauth.h
# End Source File
# Begin Source File

SOURCE=.\vncbuffer.h
# End Source File
# Begin Source File

SOURCE=.\vncclient.h
# End Source File
# Begin Source File

SOURCE=.\vncconndialog.h
# End Source File
# Begin Source File

SOURCE=.\vnccorbaconnect.h
# End Source File
# Begin Source File

SOURCE=.\vncdesktop.h
# End Source File
# Begin Source File

SOURCE=.\vncdesktopthread.h
# End Source File
# Begin Source File

SOURCE=.\vncencodecorre.h
# End Source File
# Begin Source File

SOURCE=.\vncencodehext.h
# End Source File
# Begin Source File

SOURCE=.\vncencodemgr.h
# End Source File
# Begin Source File

SOURCE=.\vncencoder.h
# End Source File
# Begin Source File

SOURCE=.\vncencoderre.h
# End Source File
# Begin Source File

SOURCE=.\vncEncodeTight.h
# End Source File
# Begin Source File

SOURCE=.\vncEncodeUltra.h
# End Source File
# Begin Source File

SOURCE=.\vncEncodeZlib.h
# End Source File
# Begin Source File

SOURCE=.\vncEncodeZlibHex.h
# End Source File
# Begin Source File

SOURCE=.\vncencodezrle.h
# End Source File
# Begin Source File

SOURCE=.\vnchttpconnect.h
# End Source File
# Begin Source File

SOURCE=.\vncinsthandler.h
# End Source File
# Begin Source File

SOURCE=.\vnckeymap.h
# End Source File
# Begin Source File

SOURCE=.\vncListDlg.h
# End Source File
# Begin Source File

SOURCE=.\vnclog.h
# End Source File
# Begin Source File

SOURCE=.\vncmenu.h
# End Source File
# Begin Source File

SOURCE=.\vncpasswd.h
# End Source File
# Begin Source File

SOURCE=.\vncproperties.h
# End Source File
# Begin Source File

SOURCE=.\vncpropertiesPoll.h
# End Source File
# Begin Source File

SOURCE=.\vncpropPath.h
# End Source File
# Begin Source File

SOURCE=.\vncserver.h
# End Source File
# Begin Source File

SOURCE=.\vncservice.h
# End Source File
# Begin Source File

SOURCE=.\vncsetauth.h
# End Source File
# Begin Source File

SOURCE=.\vncsockconnect.h
# End Source File
# Begin Source File

SOURCE=.\vnctimedmsgbox.h
# End Source File
# Begin Source File

SOURCE=.\vsocket.h
# End Source File
# Begin Source File

SOURCE=.\vtypes.h
# End Source File
# Begin Source File

SOURCE=.\winvncsc.h
# End Source File
# Begin Source File

SOURCE=..\..\ZipUnZip32\ZipUnZip32.h
# End Source File
# End Group
# Begin Group "Resource Files"

# PROP Default_Filter "ico;cur;bmp;dlg;rc2;rct;bin;rgs;gif;jpg;jpeg;jpe"
# Begin Source File

SOURCE=.\res\background.bmp
# End Source File
# Begin Source File

SOURCE=.\res\background2.bmp
# End Source File
# Begin Source File

SOURCE=.\res\clipboardframe.class
# End Source File
# Begin Source File

SOURCE=.\res\descipher.class
# End Source File
# Begin Source File

SOURCE=.\HideDesktop.h
# End Source File
# Begin Source File

SOURCE=.\res\ico00001.ico
# End Source File
# Begin Source File

SOURCE=.\res\icon1.ico
# End Source File
# Begin Source File

SOURCE=.\res\icon2.ico
# End Source File
# Begin Source File

SOURCE=.\res\optionsframe.class
# End Source File
# Begin Source File

SOURCE=.\res\rfbproto.class
# End Source File
# Begin Source File

SOURCE=.\res\vdacc.bmp
# End Source File
# Begin Source File

SOURCE=".\res\vnc-1.bmp"
# End Source File
# Begin Source File

SOURCE=".\res\vnc-1.ico"
# End Source File
# Begin Source File

SOURCE=.\res\vnc.bmp
# End Source File
# Begin Source File

SOURCE=.\vnc.bmp
# End Source File
# Begin Source File

SOURCE=.\res\vnc64.BMP
# End Source File
# Begin Source File

SOURCE=.\res\vnccanvas.class
# End Source File
# Begin Source File

SOURCE=.\res\vncviewer.class
# End Source File
# Begin Source File

SOURCE=.\res\vncviewer.jar
# End Source File
# Begin Source File

SOURCE=.\res\winvncsc.ico
# End Source File
# Begin Source File

SOURCE=.\res\world3a.ico
# End Source File
# Begin Source File

SOURCE=".\res\ww-grn-sq2.ico"
# End Source File
# End Group
# Begin Source File

SOURCE=.\res\AuthPanel.class
# End Source File
# Begin Source File

SOURCE=..\..\BUILDING.txt
# End Source File
# Begin Source File

SOURCE=..\building.txt
# End Source File
# Begin Source File

SOURCE=.\res\ButtonPanel.class
# End Source File
# Begin Source File

SOURCE=.\res\FTPFrame.class
# End Source File
# Begin Source File

SOURCE=..\history.txt
# End Source File
# Begin Source File

SOURCE=..\..\LICENCE.txt
# End Source File
# Begin Source File

SOURCE=..\README_BINARY.txt
# End Source File
# Begin Source File

SOURCE=.\res\RecordingFrame.class
# End Source File
# Begin Source File

SOURCE=.\res\SessionRecorder.class
# End Source File
# End Target
# End Project
