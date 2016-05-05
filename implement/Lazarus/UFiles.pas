{
 This is a personal project that I give to community under this licence:

Copyright 2016 Eric Buso (Alias Caine_dvp)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
}
unit UFiles;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface
Uses Classes,SysUtils;
Const
  InternalError   = 'Erreur interne.';
  AssignFileError = 'Erreur à l''assignation (%d) du fichier %s';
  CreateFileError = 'Erreur à la création (%d) du nouveau fichier %s';
  CreateOverrideError = 'Erreur (%d) fichier %s existant';
  ReadFileError   = 'Erreur de lecture (%d) du fichier %s';
  WriteFileError  = 'Erreur d''écriture (%d) du fichier %s';
  ResetFileError  = 'Erreur ouverture en lecture seule (%d) du fichier %s';
  AppendFileError = 'Erreur ouverture en écriture seule (%d) du fichier %s';
  NotFoundFileError   = 'Erreur (%d) fichier %s attendue mais inexistant';
  CloseFileError  = '';

type
    TTextFiles = Class (TObject)
    private
      FFileName : String;
      FFile     : TextFile;
      FError    : Integer;
      FErrorStr : String;
      FAssigned : Boolean;
      FUnread   : Boolean;
      FEOF      : Boolean;
      function SetError(Const AFormatedError : String;Var ErrorStr : String): Boolean;
    function ReadEOF: Boolean;
    
    public
      constructor Create ( Const AFileName: String;Const NewFile: Boolean;Var ErrorStr : String);
      destructor  Destroy;override;
      function ReadLine  ( Var ALine : String; Var ErrorStr : String)  : Boolean;
      function WriteLine ( Const ALine : String;Var ErrorStr : String) : Boolean;

      property IsEOF : Boolean read ReadEOF default False;
    End;


implementation

{ TTextFiles }

constructor TTextFiles.Create(const AFileName: String;Const NewFile: Boolean; var ErrorStr: String);
begin
  FAssigned := False;
  FFileName := EmptyStr;
  FUnread   := True;

  If Not NewFile Then Begin
    If Not FileExists(AFileName) { *Converted from FileExists*  } Then Begin
       ErrorStr := Format(NotFoundFileError,[0,AFileName]);
       Exit;
    End;

  AssignFile(FFile,AFileName);
  If Not SetError(AssignFileError,ErrorStr) Then Begin
      FFileName := AFileName;
      FAssigned := True;
  End;
    Exit;
  End;

  If FileExists(AFileName) { *Converted from FileExists*  } Then Begin
  FError := 0;
  ErrorStr := Format(CreateOverrideError,[-1,AFileName] );
  Exit;
  End;

  AssignFile(FFile,AFileName);
  If Not SetError(AssignFileError,ErrorStr) Then Begin
      FFileName := AFileName;
      FAssigned := True;
  End;


  // NewFile est vrai, le fichier n'existe pas.
  ReWrite(FFile);
  SetError(CreateFileError,ErrorStr);

  CloseFile(FFile); // Supprimer l'écriture seule du Rewrite.
  FAssigned := False;

  FError := IOResult;
  If FError <> 0 Then
    Raise Exception.CreateFmt('Erreur de fichier inattendue (%d) sur (%s)',[FError,FFileName]);
end;

destructor TTextFiles.Destroy;
begin
  If FAssigned Then
    CloseFile(FFile);
  inherited;
end;

function TTextFiles.ReadEOF: Boolean;
Var
  mode : Integer;
begin
 If Not FASSigned Then
    Raise Exception.Create(InternalError + ' lecture EOF avec un fichier non assigné');

 Mode := TTextRec(FFile).Mode;
 If mode = 1 Then
    Raise Exception.Create(InternalError + ' lecture EOF sur un fichier en écriture');

 Result := EOF(FFile) or FEOF;
end;

function TTextFiles.ReadLine(var ALine, ErrorStr: String): Boolean;
begin
  Try
    Result := False;
    If Not FAssigned Then Begin
      //Raise Exception.Create(InternalError);
      AssignFile(FFile,FFileName);
      If Not SetError(AssignFileError,ErrorStr) Then Begin
          FAssigned := True;
      End;
    End;

    FileMode := 0; // Lecture seule.
    If FUnread Then
      Reset(FFile);

    If SetError(ResetFileError,ErrorStr) Then Begin
        ErrorStr := FErrorStr;
        Exit
    End;

    ReadLn(FFile,ALine);

    If Not SetError(ReadFileError,ErrorStr) Then Begin
      FUnread := False;
      Result := True;
    End;

  Finally

  End;

end;

function TTextFiles.SetError(Const AFormatedError: String;Var ErrorStr : String) : Boolean;
begin
  Result := FError <> 0;
  If Result Then Exit; // Une erreur est déjà en cours.
  FError := IOresult;
  If FError <> 0 Then Begin
     FErrorStr := Format(AFormatedError,[FError,FFileName]);
     ErrorStr := FErrorStr;
     Result := True;
     FEOF   := True;     
  End
end;

function TTextFiles.WriteLine(const ALine: String;
  var ErrorStr: String): Boolean;
begin
  Try
    Result := False;
    If Not FAssigned Then Begin
      //Raise Exception.Create(InternalError);
      AssignFile(FFile,FFileName);
      If Not SetError(AssignFileError,ErrorStr) Then Begin
          FAssigned := True;
      End;

    End;

    Append(FFile);

    SetError(AppendFileError,ErrorStr);

    WriteLn(FFile,ALine);
    Result := Not SetError(WriteFileError,ErrorStr);
  Finally
    //Sleep(5);
    //CloseFile(FFile);
  End;
end;

end.
