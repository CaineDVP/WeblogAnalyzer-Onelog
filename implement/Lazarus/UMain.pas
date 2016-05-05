{
 This is a personal project that I give to community under this licence:

Copyright 2016 Eric Buso (Alias Caine_dvp)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
}
unit UMain;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Grids,Shellapi,
  UFiles, ComCtrls, ExtCtrls,UCommons,UDataEngine;

type

  { TfmMain }

  TfmMain = class(TForm)
    btOpen: TButton;
    edPathFile: TEdit;
    mmLogInfos: TMemo;
    odgFile: TOpenDialog;
    PageControl1: TPageControl;
    pnLogHistory: TPanel;
    pnTrafficTable: TPanel;
    stgDatas: TStringGrid;
    stgRobots: TStringGrid;
    tbsSaw: TTabSheet;
    tsbRobots: TTabSheet;
    procedure FormCreate(Sender: TObject);
    procedure edPathFileChange(Sender: TObject);
    procedure btOpenClick(Sender: TObject);
    procedure BtUnzipClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Déclarations privées }
    FLogParser : TLogParser;
    FExePath : String;
  public
    { Déclarations publiques }
  end;

var
  fmMain: TfmMain;

implementation

{$R *.dfm}
Uses FileUtil;

Function ExtractToken(Const S : String;Const Separator: String;Var Token : String) : string;
Var
   P : Integer;
Begin
     P := Pos(Separator,S);
     Result := Copy(S,P+1,Length(S)-1);
     Token := Copy(S,0,P-1);
End;

Procedure ReplaceToken(Var S : String;Const Separator,Token: String);
Var
   p : Integer;
   Temp,Current: String;
Begin
     P := 0;
     Current := S;
     Temp := '';
     Repeat
        P    := Pos(Separator,Current);
        If P <> 0 Then
            Begin
            Temp := Copy(Current,1,P-1);
            Temp := Temp + Token;
            Current := Copy(Current,P+Length(Separator),Length(Current));
            End;
     Until P = 0;
     If Temp <> '' Then
         S := Temp + Current;
End;


procedure TfmMain.btOpenClick(Sender: TObject);

var Reader : TTextFiles;
    I,Row1,Col1,Row2,Col2 : Integer;
    Cnt,Col : ^Integer;
    Error,Tokens  : String;
    Line,Tail   : String;
    IpAddress,Date: String;
    CurrentGrid : TStringGrid;
    B : Boolean;
    Path : String;
    GeolocData: TGeolocData;
    GeoCountry :String;

begin

  Row1 := stgDatas.FixedRows;
  Col1 := stgDatas.FixedCols;

  Row2 := stgRobots.FixedRows;
  Col2 := stgRobots.FixedCols;

  CurrentGrid := nil;

  If odgFile.Execute Then
     edPathFile.Text := OdgFile.FileName
  Else Exit;

  Reader := TTextFiles.Create(OdgFile.FileName,False,Error);
  CurrentGrid := stgDatas;

    //Creation de la base Geoloc
  try
  GeolocData := nil;

    Path := FExepath ;
    If Not Assigned(GeolocData) Then
       GeolocData:= TGeolocData.Create(Path + '\GeoLite2.db');
    If Not Assigned(GeolocData) Then
        Raise Exception.Create('Impossible d''initialiser GeolocData');
  finally
  end;


  Try
  Repeat

    Reader.ReadLine(Line,Error);
    B := FLogParser.ParseLine(Line);

    If Not B Then Continue;

    If FlogParser.IsBot Then Begin
      CurrentGrid :=  stgRobots;
      Cnt := @Row1;
      Col := @Col1;
    End
    Else
    Begin
      CurrentGrid := stgDatas;
      Cnt := @Row2;
      Col := @Col2;
    End;

    With FlogParser.LogInfos Do
    Begin
      {Pour le trafic humain uniquement, si le code diffère de 404}
      If ( Not IsBot ) And (Code <> 404) Then
      Begin
      {Chercher la géolocalisation de l'adresse IP}
      Try
       If (GeolocData.IsTheLastIPAddress(IPAddress)=False) Then Begin
        //If (CurrentGrid.Cols[Col^].IndexOf(IPAddress)=-1) Then Begin
        //mmLogInfos.Append(IPAddress);
        GeoCountry := GeolocData.GetCountryName(IPAddress);
      end;
      finally
      If GeoCountry <> EmptyStr Then
          Begin
          //mmLogInfos.Append(GeoCountry);
          If (CurrentGrid.RowCount > Cnt^) Then CurrentGrid.Cells[Col^,Cnt^]   := GeoCountry;
          end;
      GeoCountry := EmptyStr;
      end;
      End;
      {Remplir la grille avec les information extraitent de la ligne}
      If (CurrentGrid.RowCount > Cnt^) Then Begin
      CurrentGrid.Cells[Col^+1 ,Cnt^]   := IPAddress;
      CurrentGrid.Cells[Col^+2 ,Cnt^] := Domain;
      CurrentGrid.Cells[Col^+3 ,Cnt^] := DateTime;
      CurrentGrid.Cells[Col^+4 ,Cnt^] := FileRequest;
      CurrentGrid.Cells[Col^+5 ,Cnt^] := IntToStr(FileSize);
      CurrentGrid.Cells[Col^+6 ,Cnt^] := IntToStr(Code);
      If Isbot Then
        Currentgrid.Cells[Col^+7 ,Cnt^] := BotName
      Else
        Currentgrid.Cells[Col^+7 ,Cnt^] := Referrer;
{      Currentgrid.Cells[Col^+8 ,Cnt^] := Country;
      Currentgrid.Cells[Col^+9 ,Cnt^] := Browser;
      Currentgrid.Cells[Col^+10 ,Cnt^] := Os;
}
      Currentgrid.Cells[Col^+8 ,Cnt^] := UserAgentInfos;
      end;
    End;
    Inc(Cnt^,1);


  Until Reader.IsEOF;
Finally
  FreeAndNil(GeolocData);
End;

end;

procedure TfmMain.BtUnzipClick(Sender: TObject);
Var FromFiles,ToFolder : String;
begin
ToFolder  := ' "C:\temp\Moved\"';
FromFiles := '/C move "' +edPathFile.Text + '\*.gz"' + ToFolder;

If FromFiles <> EmptyStr Then
  ShellExecute(0,'open','cmd',PChar(FromFiles), PChar(edPathFile.Text) ,SW_SHOW)
Else Exit;

FromFiles := '/K ' + '.\gzip.exe -ad '+ ToFolder+'\*.gz';

If (FromFiles <> EmptyStr) and (ToFolder <> EmptyStr) Then
  ShellExecute(0,'open','cmd',PChar(FromFiles), PChar(ToFolder) ,SW_SHOW)

end;

procedure TfmMain.edPathFileChange(Sender: TObject);
begin
odgFile.InitialDir := edPathFile.Text;
end;

procedure TfmMain.FormCreate(Sender: TObject);
begin
//edPathFile.text := 'C:\Documents and Settings\caine\Mes documents\VosLogiciels.com\Logs OVH';
edPathFile.text := 'C:\temp\Logs OVH';
odgFile.InitialDir := edPathFile.Text;
FLogParser := TLogParser.Create;
//Stoquer le chemin vers l'executable.
FExepath := ProgramDirectory;
stgDatas.RowCount := 10000;
end;

procedure TfmMain.FormDestroy(Sender: TObject);
begin
FreeAndNil(FLogParser);

end;


end.
