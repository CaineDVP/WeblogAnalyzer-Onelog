{
 This is a personal project that I give to community under this licence:

Copyright 2016 Eric Buso (Alias Caine_dvp)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
}
unit UCommons;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

Uses SysUtils, Variants, Classes,StrUtils;

type
    TLogsInfo = record
      IpAddress ,
      Domain    ,
      DateTime  ,
      FileRequest:String;
      FileSize  ,
      Code      : Integer;
      
      case IsBot: boolean of
          True  : (BotName : String[255]);
          False : (Referrer: String[255];
                   Country : String[15];
                   Browser : String[15];
                   OS      : String[15];
                   UserAgentInfos:String[255];
                  );
    end;

    { TLogParser }

    { TLogStats }

    TLogStats = Class(Tobject)
       private
           FUniqueIP: array[1..10000] of string;
           FLastIP : integer;
       public
           function UniqueIPCounter(const LogsInfo: TLogsInfo) : integer;
    end;

    TLogParser = class(Tobject)
      private
          FLogsInfo : TLogsInfo;
          FSplitted ,
          FRobotsIp,FUserAgentSplit  : TStringList;
          function GetIsBot: Boolean;
          function TrimFileRequest (const Request : String) : String;
          function TrimBotName(const UserAgentInfos : String):String;
          Procedure TrimUserAgentInfos(const UserAgentInfos : String);
          Procedure TrimCountry(Const CountryInfos : String);
          Procedure Clear;
      public
          constructor Create;
          destructor  Destroy; override;
          property IsBot : Boolean Read GetIsBot;
          property LogInfos : TLogsInfo Read FLogsInfo;
           
          function ParseLine (const Line : String): Boolean;
          function SqlTimeStamp(const TimeStamp : String) : String;
    end;

implementation
Uses Math;

{ TLogStats }

function TLogStats.UniqueIPCounter(const LogsInfo: TLogsInfo): integer;
begin
  {Accumuler le nombre d'adresses IP uniques}
  //if Self.FUniqueIP[FLastIP]
end;

{ TLogParser }

procedure TLogParser.Clear;
begin
With Self.FLogsInfo Do Begin
      IpAddress := EmptyStr;
      Domain    := EmptyStr;
      DateTime  := EmptyStr;
      FileRequest := EmptyStr;
      FileSize  :=0;
      Code      :=0;

      BotName := EmptyStr;
      Referrer:= EmptyStr;
      Country := EmptyStr;
      Browser := EmptyStr;
      OS      := EmptyStr;
End;

end;

constructor TLogParser.Create;
begin
  inherited;
  FSplitted := TStringlist.Create;
  FRobotsIP := TStringlist.Create;
  FUserAgentSplit := TStringlist.Create;
end;

destructor TLogParser.Destroy;
begin
  FreeAndNil(FSplitted);
  FreeAndNil(FRobotsIP);
  FreeAndNil(FUserAgentSplit);
  inherited;
end;

function TLogParser.GetIsBot: Boolean;
begin
  result := FLogsInfo.IsBot;
end;

function TLogParser.ParseLine(const Line: String): Boolean;
Var IsABot : Boolean;
    Str : String;
begin
    Result := False;
    IsABot := False;
    FSplitted.Clear ;
    FSplitted.Delimiter := ' ';
    FSplitted.DelimitedText := Line;

    // Seules les informations sur les fichiers html ou robots.txt nous intéressent.
    // Note : lorsque le fichier demandé est '/', il correspond à index.html
    // Les fichier images, CSS, javascipt, etc ne sont pas parser.
   If (Pos('.html',FSplitted[5]) >0) or (Pos('.txt',FSplitted[5])>0) or (Pos(' / ',FSplitted[5])>0)Then
//DROP    If (Pos('?',FSplitted[5])=0) or (Pos('.css',FSplitted[5])=0) or (Pos('.jpg',FSplitted[5])=0) or (Pos('.js',FSplitted[5]) =0) or (Pos('.gif',FSplitted[5]) =0) Then
    Begin
      //Reset des anciennes informations.
      Self.Clear;
      //Indiquer à l'appelant que le fichier est parsé.
      Result:=True;
      With Self.FLogsInfo Do Begin

      //Addresse IP
      IpAddress  := Trim(FSplitted[0]);
      //Nom de domaine recherché
      Domain     := Trim(FSplitted[1]);
      //Extraire la date et l'heure
      Str := Trim(FSplitted[3]);
      Str :=  Copy(Str,2,Length(Str)-1);//Sauter le '[' résiduel.
      //TODO SqlTimeStamp renvoit 03 pour May!!!
      DateTime   := SqlTimeStamp(Str);
      //Page demandée par le navigateur
      FileRequest:= TrimFileRequest(FSplitted[5]);
      //Code envoyé par le serveur Appache -200=OK, 404= non trouvée, 503=En maitenance, 301=Redirection
      Code       := StrToInt(Trim(FSplitted[6]));
      //Extraction et convertion de la taille en octet de la page.
      FileSize := -1;
      try
        If (Code = 200) Then FileSize   := StrToInt(Trim(FSplitted[7]));
      Except
        FileSize := -1;
      end;
      //L'adresse IP est déjà connu comme robot pour ce log.
      IsABot     := FRobotsIp.IndexOf(IpAddress) >= 0;
      // Rechercher si le fichier robot.txt a été demandé pour cette adresse IP
        If (Pos('/robots.txt',FSplitted[5]) >0) or (IsABot) Then
        Begin
          IsBot := True;
          //Stoquer l'adresse IP correspondant au robot.
          If FRobotsIp.IndexOf(IpAddress) =-1 Then
              FRobotsIp.Add(IpAddress);
          //Extraire le nom du robot
          //OLD BotName := TrimBotName(FSplitted[9]);
          BotName := FSplitted[9];
        End
        Else Begin
          // Attention, cas d'un robot qui ne demande pas 'robots.txt';
          // Dans ce use case, il est certain que l'IP n'est pas celle d'un robot.
          // 2ème cas du test : Match robot sur User agent info vide (égal à "-").
          if (Pos('Bot',FSplitted[9])>0) or (Pos('crawl',FSplitted[9])>0) or (Pos('Bot',FSplitted[9])>0) or
               (Pos('bot',FSplitted[9])>0) or (Pos('spider',FSplitted[9])>0) or ( CompareStr('-',FSplitted[9]) = 0) then Begin
            IsBot := True;
            FRobotsIp.Add(IpAddress);
            //OLD BotName := TrimBotName(FSplitted[9]);
            BotName := FSplitted[9];
            Exit;
          End;
          IsBot   := False;
          Referrer := Trim(FSplitted[8]);
          Str := Referrer;
          //OLD TrimUserAgentInfos(FSplitted[9]);
          UserAgentInfos := FSplitted[9];
          Str := UserAgentInfos;
        End;
      End;
    End;
end;

//Transformer une date DD/MMM/YYYY:HH:MM:SS (format windows,
//                                         MMM est une string (DEC par exemple))
// en format Sql Timestamp : YYYY-MM-DD HH:MM:SS
function TLogParser.SqlTimeStamp(const TimeStamp: String): String;
  var Day,Month,Year : String;
begin
  Result := EmptyStr;
  SetLength(Result,20);

  Day   := Copy(TimeStamp,1,2);
  Month := Copy(TimeStamp,4,3);
  // Transformer Month en chiffres.
  //'Jan'->1,'Feb'->2,'Mar'->3,'Apr'->4,'May'->5,'Jun'->6,'Jul'->7,'Aug'->8
  //'Sep'->9,'Oct'->10,'Nov'->11,'Dec'->12
  Case Month[1] of
    'J':
       If Month[2]='a' then Month := '01'
       Else if Month[3]='n' then Month := '06'
       Else Month := '07';
    'F': Month := '02';
    'M': If Month[3]='y' then Month := '05'
         Else
            Month := '03';
    'A': If Month[2]='p' Then Month := '04'
         Else Month := '08';
    'S': Month := '09';
    'O': Month := '10';
    'N': Month := '11';
    'D': Month := '12';
  End;

  Year  := Copy(TimeStamp,8,4);

  Result := Year+'-'+Month+'-'+Day+' ' + Copy(TimeStamp,13,9);
end;

procedure TLogParser.TrimCountry(const CountryInfos: String);
  Var I,L:Integer;
      CountryInfosTrim:String;
begin
  L:=Length(CountryInfos);
  // Cas où le pay est remplacé par une chaîne d'info, souvent avec au moins un chiffre.
  For I:= 1 To L Do
       If CountryInfos[I] in ['0'..'9'] Then Begin
         Self.FLogsInfo.Country := '-';
         Exit;
       End;
  //Unification des chaînes de pays.
  CountryInfosTrim := Trim(LowerCase(CountryInfos));
  If CompareStr(CountryInfosTrim,'fr-fr')=0 then Begin Self.FLogsInfo.Country := 'fr'; Exit; End;
  If CompareStr(CountryInfosTrim,'eng-us')=0 then Begin Self.FLogsInfo.Country := 'usa'; Exit;End;
  Self.FLogsInfo.Country := CountryInfosTrim;
end;

function TLogParser.TrimFileRequest(const Request: String): String;
var start,L,P : Integer; 
begin
If Pos(' / ',request) > 0 Then Begin result := 'index.html'; Exit;End;
start := Pos(' /',request);
L :=  Length(request);
P := start+2;
Repeat
  If Request[P] = ' ' Then
    Break;
  Inc(P);
Until P = L;

Result := Copy(request,start+2,p-start-2);

end;

function TLogParser.TrimBotName(const UserAgentInfos: String):String;
var start,Cnt,Ex : Integer;

begin
{
start := Pos('Bot', UserAgentInfos );
If start = 0 Then Begin
start := Pos('bot', UserAgentInfos );
End;
If start >0 Then Begin
   Ex := PosEx(' ',UserAgentInfos,start);
   Cnt:=start;
Repeat
   Dec(Cnt);
until (UserAgentInfos[Cnt] =' ') Or (Cnt >0);
End  ;
If (Ex = 0) And (Cnt = 0) Then Begin
   Result:= UserAgentInfos;
   Exit;
End;

end;
}
FUserAgentSplit.Clear;
FUserAgentSplit.Delimiter := ';';
FUserAgentSplit.DelimitedText := UserAgentInfos;
//Result := Copy(  UserAgentInfos,Cnt,Ex);
Result := FUserAgentSplit[2];
end;

//Mozilla/[version] ([system and browser information]) [platform] ([platform details]) [extensions]
procedure TLogParser.TrimUserAgentInfos(const UserAgentInfos: String);
var start,Cnt{,L},Ex : Integer;
begin
  start := Pos('(compatible; ', UserAgentInfos );
//  L := Length( UserAgentInfos );
  If start > 0 Then Begin
    //Rechercher le navigateur
    Cnt := Length('(compatible; ');
    Inc(start,Cnt);
    Ex := PosEx('; ',UserAgentInfos,start);
    If Ex = -1 Then Exit;
    Self.FLogsInfo.Browser := Copy(UserAgentInfos, start, Ex-Start);
    //Rechercher l'OS
    start := Ex+1;
    Ex := PosEx('; ',UserAgentInfos,start);
    Self.FLogsInfo.Os := Copy(UserAgentInfos, start, Ex-Start+1);
    //Rechercher le pays
    start := PosEx('; ',UserAgentInfos,Ex+1)+2;
    Ex := PosEx('; ',UserAgentInfos,start);
    TrimCountry(Trim(Copy(UserAgentInfos, start, Ex-Start)));
  End
  Else Begin
    //Rechercher l'OS
    start := Pos(' (', UserAgentInfos);
    Inc(start,Length(' ('));
    Ex := PosEx('; ',UserAgentInfos,start);
    start := Ex+1;
    Ex := PosEx('; ',UserAgentInfos,start);
    start := Ex+1;
    Ex := PosEx('; ',UserAgentInfos,start);
    Self.FLogsInfo.Os := Copy(UserAgentInfos, start, Ex-Start+1);
    //Rechercher le pays
    start := Ex+1;
    // Cas '( ; ;Pays; )'
    Ex := PosEx(';',UserAgentInfos,start);
    // Cas '( ; ;Pays )'
    If Ex = 0 Then
      Ex := PosEx(')',UserAgentInfos,start);

    TrimCountry(Trim(Copy(UserAgentInfos, start, Ex-Start)));
  End;
end;

end.
