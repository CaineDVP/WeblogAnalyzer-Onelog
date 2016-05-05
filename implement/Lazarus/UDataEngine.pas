{
 This is a personal project that I give to community under this licence:

Copyright 2016 Eric Buso (Alias Caine_dvp)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
}
{%BuildWorkingDir D:\Dev_Projects\WebLogAnalyser\tests\Release tests\Lazarus}
{%RunWorkingDir D:\Dev_Projects\WebLogAnalyser\tests\Release tests\Lazarus}
unit UDataEngine;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface
Uses UCustomDataEngine,UCommons;

type

  { TGeolocData }

  TGeolocData = class(TCustomDataEngine)
  Public
    constructor Create(Const DBName:String);
    function GetCountryName(Const IPAddress:String):String;
    function IsTheLastIPAddress(IPAddress:String):Boolean;

  Private
    FLastIPChecked : String;

    const
    //Alias des tables Geoloc
    BlockIPV4 ='GeoLite_block_IPv4';
    CountryLocation= 'GeoLite_Country_Location' ;

    //Alias des noms de la table GeoLite_block_IPv4
    IP1 ='IP1';
    IP2 ='IP2';
    IP3 ='IP3';
    IP4 ='IP4';
    CIDR='CIDR';
    Geoname='geoname_id';
    regCountryGeoname='registered_country_geoname_id';
    repCountryGeoname='represented_country_geoname_id';
    IsAnonymousProxy='is_anonymous_proxy';
    IsSatelliteProvider='is_satellite_provider';

    //Alias des noms de la table GeoLite_Country_Location:
    GeonameID='geoname_id';
    LocaleCode='locale_code';
    ContientCode='continent_code';
    ContinentName='continent_name';
    CountryIsoCode='country_iso_code';
    CountryName='country_name';
  end;

  TDataEngine = class(TCustomDataEngine)
  Public

    constructor Create(Const DBName:String);

    procedure InsertDomain( const Infos : TLogsInfo; var Error: integer);
    procedure InsertHuman ( const Infos : TLogsInfo; var Error: integer);
    procedure InsertRobot ( const Infos : TLogsInfo; var Error: integer);
  Private
    Const
      // Alias des noms de tables de la Bdd.
      Domain     = 'SiteDomains'    ;
      Human      = 'Human_traffic'  ;
      Robots     = 'Robots_traffic' ;
      AgentInfos = 'UserAgentInfos' ;
      RobotsInfos= 'Robot_infos'    ;

      //Alias des noms de colonnes de la Bdd.
      // Table 'Domain'
      DomainKey  = 'DN_Key'     ;
      DomainName = 'DomainName' ;

      // Table 'Human'
      IPKey      ='IP_Key'     ;
      IPAddress  ='IP_Address' ;
        //DomainName foreign key (DN_KEY).
      Referrer   = 'Referrer'     ;
      DateTime   = 'VisitDatetime';
      TimeZone   = 'TimeZone'     ;
      FileR      = 'FileRequest'  ;
      FileS      = 'FileSize'     ;
      Protocol   = 'Protocol'     ;
      Code       = 'Code'         ;
      // 'UserAgentInfos'
      Country    = 'Country' ;
      Browser    = 'Browser' ;
      OS         = 'OS'      ;

      // Table 'Robots', cette table reprend la majorité des champs de la table 'human'
      BotName    = 'BotName';

      function ForeignKey(const Table : string ; const Column : string;const ForeignColumn: String; const ForeignFormat: TVarRec;Var ForeignValue: TVarRec ) : String;
  end;

implementation
Uses SysUtils,StrUtils,Windows;

{ TGeolocData }

constructor TGeolocData.Create(const DBName: String);
begin
  inherited Create(DBName);
end;


function TGeolocData.IsTheLastIPAddress(IPAddress: String): Boolean;
begin
    Result := (AnsiCompareText(FLastIPChecked,IPAddress)=0);
end;

function TGeolocData.GetCountryName(const IPAddress: String): String;
Var Cols: Array of TVarRec;
    CIDRMasks: Array[1..4] of Integer;
    SearchStr:String;
    //IPS sera accéder par reste de la division par 8. Donc commence à zéro.
    IPS: Array[1..4] of String;
    GeoNameSearch :String;
    calc,p,ICIDR,Mask,len,llen,I:Integer;

const Masks: Array[0..7] of integer = (255,128,192,224,240,248,252,254);
begin
//Extraire les 4 parties de l'adresse IP
  FLastIPChecked := IPAddress;
  len := Length(IPAddress);
  p    := Pos('.',IPAddress);
  llen := p;
  IPS[1]  := Copy( IPAddress,0,p-1);
  p    := PosEx('.',IPAddress,p+1);
  IPS[2] := Copy( IPAddress,llen+1,p-llen-1);
  llen:=p;
  p   := PosEx('.',IPAddress,p+1);
  IPS[3] := Copy( IPAddress,llen+1,p-llen-1);
  IPS[4] := Copy( IPAddress,p+1,len-p);

  For ICIDR := 8 to 32 Do
  Begin
    //Remise à zéro des chaînes de recherches.
    FillMemory(PVOID(@CIDRMasks),4*sizeof(String),0);

    //Convertir la partie IP en entier puis appliquer le masque.
    p := ICIDR Div 8;
    llen := ICIDR mod 8;
    I := 0;

    //Construire la table des masque de CIDR.
    For I :=1 To P Do
    Begin
      Mask := StrToInt(IPS[I]);
      Mask := Mask And Masks[0];
      //Construire la chaine de recherche Sql à partir des masques.
      CIDRMasks[I] := Mask;
    end;

    If (llen > 0)  Then //Erreur ici: 2*2*8 pour CIDR 17!
      Begin
       Inc(I);
       Mask := StrToInt(IPS[I]);
       Mask := Mask And Masks[llen];
       //Construire la chaine de recherche Sql à partir des masques.
       CIDRMasks[I] := Mask;
      End;

 Columns := Geoname;
  Tables  := BlockIPV4;
  Where   := IP1+'='+IntToStr(CIDRMasks[1])+' and '+IP2+'='+IntToStr(CIDRMasks[2])+' and '+IP3+'='+IntToStr(CIDRMasks[3])+' and '+IP4+'='+IntToStr(CIDRMasks[4])+' and '+CIDR+'='+IntToStr(ICIDR);
  Select;

  If RowCount =1 then
  Begin
    SetLength(Cols,1);

    Cols[0].vType := vtPChar;
    Fetch(Cols);

   GeoNameSearch := String(Rows[0][0].VPChar);
   Columns := CountryName;
   Tables  := CountryLocation;
   Where   := GeonameID +'='+GeoNameSearch;
   Select;

   If RowCount = 1 then
   Begin
   SetLength(Cols,1);
   Cols[0].vType := vtPchar;
   Fetch(Cols);
      Result := String(Rows[0][0].VPChar);
      End;

   exit;
  End;
end;

end;

{ TDataEngine }

//function TDataEngine.ForeignKey(const Value: TVarRec; const Table,
constructor TDataEngine.Create(const DBName: String);
begin
inherited Create(DBName);
end;

function TDataEngine.ForeignKey(const Table,
                    Column: string;const ForeignColumn: String; const ForeignFormat: TVarRec;Var ForeignValue: TVarRec): String;

  Var StrValue : String;
      Value: string;
      Cols : Array[0..0] of TVarRec;

begin
  Result  := EmptyStr;

  Case ForeignFormat.VType of
      vtInteger:
          Value := IntToStr(ForeignFormat.VInteger);
      vtChar:
            Value :=  ForeignFormat.VChar;
      vtString:
          Value := (ForeignFormat.VString)^ ;
      vtPChar:
            Value := String(ForeignFormat.VPChar)  ;
  End;

  Columns := ForeignColumn;
  Tables  := Table;
  Where   := ' ' + Column + '="'+Value+'"';
  Select;
  Cols[0] := ForeignValue;
  Fetch(Cols);

  Case ForeignValue.VType Of
      vtInteger: Begin
          ForeignValue.VInteger := Rows[0][0].VInteger;
          Result := IntToStr(ForeignValue.VInteger);
      End;
      vtChar: Begin
          ForeignValue.VChar := Rows[0][0].VChar;
          Result :=  ForeignValue.VChar;
      End;
      vtPChar: Begin
          ForeignValue.VPChar := Rows[0][0].VPChar;
          Result := String(ForeignValue.VPChar)  ;
      End;

  End;
end;

procedure TDataEngine.InsertDomain(const Infos: TLogsInfo; var Error: integer);
begin
  If Exists(Infos.Domain,Domain,DomainName) Then Exit;
  Tables  := Domain;
  Columns := DomainKey+','+DomainName;
  Values  := 'NULL,"' + Infos.Domain +'"' ;
  InsertARow;
  Error := Self.Error;
end;

procedure TDataEngine.InsertHuman(const Infos: TLogsInfo; var Error: integer);
var  VRec: TVarRec;
     ADomainKey : String;
     ColFormat,ResFormat : TVarRec;
begin
  ColFormat.vType := vtPChar;
  ColFormat.VPChar := PChar(Infos.Domain);
  // Les clés étrangères doivent toutes être transformées avant toute autre opération.
  // Transformer le nom de domain en clé étrangère.
  ResFormat.VType := vtInteger;
  ADomainKey := ForeignKey(Domain,DomainName,Self.DomainKey,ColFormat,ResFormat);

  Tables  := Human ;
  Columns := IPAddress + ',' + DomainName +','+DateTime+','{+TimeZone + ','} + FileR +','+Referrer +','+ Country + ','+ Browser + ',' + OS;
  Values  := '"' +Infos.IpAddress +'",'+ ADomainKey+',"'+Infos.DateTime+'","'+Infos.FileRequest +'","'+ Infos.Referrer+ '","'+Infos.Country+'","'+Infos.Browser+'","'+Infos.OS+'"';
  //Insertion infos d'une visite.
  InsertARow;
  Error := Self.Error;
end;

procedure TDataEngine.InsertRobot(const Infos: TLogsInfo; var Error: integer);
begin

  InsertARow;
  Error := Self.Error;
end;

end.
