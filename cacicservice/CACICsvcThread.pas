(*
  A Windows NT Service Thread
  ===========================

  Author          Kim Sandell
                  Email: kim.sandell@nsftele.com
*)
unit CACICsvcThread;

interface

uses
  Windows, Messages, SysUtils, Classes;


type
  TNTServiceThread = Class(TThread)
  private
    { Private declarations }
  Public
    { Public declarations }
    Interval              : Integer;

    Procedure Execute; Override;
  Published
    { Published declarations }
  End;

implementation

{ TNTServiceThread }

procedure TNTServiceThread.Execute;
var TimeOut : integer;
begin
     // Do NOT free on termination - The Serivce frees the Thread
     FreeOnTerminate := False;

     // Set Interval
     TimeOut := Interval * 4;

     // Main Loop
     Try
        While Not Terminated do
        Begin
             // Decrement timeout
             Dec( TimeOut );

             If (TimeOut=0) then
             Begin
                  // Reset timer
                  TimeOut := Interval * 4;

             End;
             // Wait 1/4th of a second
             Sleep(250);
        End;
     Except
        On E:Exception do ; // TODO: Exception logging...
     End;
     // Terminate the Thread - This signals Terminated=True
     Terminate;

end;

end.
