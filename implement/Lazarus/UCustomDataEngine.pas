{
 This is a personal project that I give to community under this licence:

Copyright 2016 Eric Buso (Alias Caine_dvp)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
}
unit UCustomDataEngine;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface
Uses USQLite3;

type TCustomDataEngine = class(TObject)
  public

    type TRows = Array of Array of TVarRec;

    constructor Create(Const DBName:String);
    destructor Destroy;override;

    function Exists(const Value : String; const Table: String; const Column: String ) : Boolean;

  protected
  
    Procedure CopyRows(Var Rows : TRows;Const R : Integer);
    Procedure AssignResult(Var Values : TRows;Const MaxRow : Integer);
    Procedure InsertARow;
    Procedure Select;
    Procedure Fetch (const ColFormat : Array of TVarRec);
    Procedure Update;

  private

    FRowCount ,
    FColCount : Integer;

    FSql      : TSql   ;

    FColFormat: Array of TVarRec; // Format des colonnes de la recherche.

    FColumns  ,
    FTables   ,
    FValues   ,
    FWhere    : String;

    FError    : Integer;

    FRows : TRows ; // Valeurs résultant d'un select.

    function ColCount: Integer;

  Protected
    property Columns : string  read FColumns write FColumns  ;
    property Tables  : string  read FTables  write FTables   ;
    property Values  : string  read FValues  write FValues   ;
    property Where   : string  read FWhere   write FWhere    ;
    property Error   : Integer read FError                   ;
    property RowCount: Integer read FRowCount                ;
    property Rows    : TRows   read FRows                    ;
end;

implementation
Uses Math,SysUtils,Windows;
{ TCustomDataEngine }

procedure TCustomDataEngine.AssignResult(var Values: TRows;
          const MaxRow: Integer);
  Var
    M : Integer;
  begin
    M := Min(MaxRow,FRowCount);
    SetLength(Values,M);
    Dec(M);
    CopyRows(Values,M);
end;

function TCustomDataEngine.ColCount: Integer;
Var I,L:Integer;
begin
Result := 0;
L := Length(FColumns);
If L = 0 Then Exit;
Inc(Result);
I := 1;
Repeat
  If FColumns[I] = ',' Then
    Inc(Result);
  Inc(I);
Until I>=L;
end;

procedure TCustomDataEngine.CopyRows(var Rows: TRows; const R: Integer);
  Var
    I,J: Integer;
  begin
    For I := 0 To R Do Begin

      SetLength(Rows[I],FColCount);
      FSql.Fetch(FColFormat);

      For J:=0 To FColCount-1 Do Begin
      Rows[I][J] := FColFormat[J];
      End;

      // TODO CopyMemory( PVoid(@Rows[I]), PVoid(@FColFormat), Sizeof(FColFormat) );

    End;
    FSql.Fetch(FColFormat);// Appel poubelle, on finalise le statement de FSql.

end;

constructor TCustomDataEngine.Create(Const DBName:String);
var ErrorMSg : String;
begin
  inherited Create;
  FSql := TSql.Create(DBName,FError,ErrorMSg);
  if (FSql = nil) or (FError <>0) then
      Raise Exception.Create('Impossible d''initialiser le SGBD '+DBName+' :' + ErrorMSg);
end;

destructor TCustomDataEngine.Destroy;
begin
  If Assigned(FSql) Then FSql.Destroy;
  If Assigned(FColFormat) Then
    Finalize(FColFormat);
  If Assigned(FRows) Then
    Finalize(FRows);

  inherited;
end;

function TCustomDataEngine.Exists(const Value, Table, Column: String): Boolean;
var Where : String;
begin
Result := False;
Where := Format('%s="%s"' ,[Column,Value]); 
Result := FSql.CountSelect(Table,Where) > 0 ;
end;

procedure TCustomDataEngine.Fetch(const ColFormat : Array of TVarRec);
Var I : Integer;
begin
  FColCount := ColCount;
  If Length(ColFormat) <> FColCount Then
    Raise Exception.Create('Format de recherche incompatible. Le nombre de colonnes diffère.');
  If FRowCOunt <=0 Then Exit;

  SetLength(FColFormat,FColCount);
  For I:= 0 To FColCount-1 Do
      FColFormat[I] := ColFormat[I];

  SetLength(FRows,FRowCount);
  CopyRows(FRows,FRowCount-1);

end;

procedure TCustomDataEngine.InsertARow;
begin
If (FColumns=EmptyStr) or (FTables=EmptyStr) or (FValues=EmptyStr) Then Exit;
FError := FSql.insert(FTables,FColumns,FValues); // Error = 0 si insertion correcte.
end;

procedure TCustomDataEngine.Select;
 
begin
If (FColumns=EmptyStr) or (FTables=EmptyStr) Then Exit;
FError := FSql.Select(FTables,FColumns,FWhere,FRowCount); //Error = 0 si requête Sql correcte.
end;

procedure TCustomDataEngine.Update;
begin

end;

end.
