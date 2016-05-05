{
 This is a personal project that I give to community under this licence:

Copyright 2016 Eric Buso (Alias Caine_dvp)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
}
unit USQLite3;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  windows,SysUtils ;

type

    TSql    = class(Tobject)
    public
      function Update (const tables, sets, where: String;Var Count : Integer): Integer;
      function insert(const tables,columns,values : String ): Integer;
      function LastRowId(const table,where        : String; Var RowId : Integer ): Integer;
      function closeDatabase:integer;
      function CountSelect(const Table,Where: String):integer;
      function CountDistinct(const Table,Columns,Where : String): Integer;
      function Select(const Table,columns,where: String; var Count : Integer):integer;
      procedure Fetch(var Row : Array of TVarRec);

      constructor Create(const Database: String;Var Error : Integer;
                          Var ErrorMsg  : String);
      destructor Destroy;override;

    private
      sqlerror : Integer;
      DB       : Pointer;
      Stmt     : Pointer;
      FErrorMsg : String;

    public
      property ErrorMsg : String Read FErrorMsg;    
    end;

Implementation

const
  DLLSqlite = '.\sqlite3.dll';

  SQLITE_OK = 0; // Successful result
  SQLITE_ERROR = 1; // SQL error or missing database
  SQLITE_INTERNAL = 2; // An internal logic error in SQLite
  SQLITE_PERM = 3; // Access permission denied
  SQLITE_ABORT = 4; // Callback routine requested an abort
  SQLITE_BUSY = 5; // The database file is locked
  SQLITE_LOCKED = 6; // A table in the database is locked
  SQLITE_NOMEM = 7; // A malloc() failed
  SQLITE_READONLY = 8; // Attempt to write a readonly database
  SQLITE_INTERRUPT = 9; // Operation terminated by sqlite3_interrupt()
  SQLITE_IOERR = 10; // Some kind of disk I/O error occurred
  SQLITE_CORRUPT = 11; // The database disk image is malformed
  SQLITE_NOTFOUND = 12; // (Internal Only) Table or record not found
  SQLITE_FULL = 13; // Insertion failed because database is full
  SQLITE_CANTOPEN = 14; // Unable to open the database file
  SQLITE_PROTOCOL = 15; // Database lock protocol error
  SQLITE_EMPTY = 16; // Database is empty
  SQLITE_SCHEMA = 17; // The database schema changed
  SQLITE_TOOBIG = 18; // Too much data for one row of a table
  SQLITE_CONSTRAINT = 19; // Abort due to contraint violation
  SQLITE_MISMATCH = 20; // Data type mismatch
  SQLITE_MISUSE = 21; // Library used incorrectly
  SQLITE_NOLFS = 22; // Uses OS features not supported on host
  SQLITE_AUTH = 23; // Authorization denied
  SQLITE_FORMAT = 24; // Auxiliary database format error
  SQLITE_RANGE = 25; // 2nd parameter to sqlite3_bind out of range
  SQLITE_NOTADB = 26; // File opened that is not a database file
  SQLITE_ROW = 100; // sqlite3_step() has another row ready
  SQLITE_DONE = 101; // sqlite3_step() has finished executing

  SQLITE_INTEGER = 1;
  SQLITE_FLOAT = 2;
  SQLITE_TEXT = 3;
  SQLITE_BLOB = 4;
  SQLITE_NULL = 5;

  SQLITE_OPEN_READONLY  = $00000001;
  SQLITE_OPEN_READWRITE = $00000002;

{
int sqlite3_open_v2(
  const char *filename,   /* Database filename (UTF-8) */
  sqlite3 **ppDb,         /* OUT: SQLite db handle */
  int flags,              /* Flags */
  const char *zVfs        /* Name of VFS module to use */
);
}
  function sqlite3_open_v2(DBName : pchar;Var DB : pointer; Flags : Integer; Vfs : Pointer): integer;  cdecl; external DLLSqlite name 'sqlite3_open_v2';
{
int sqlite3_close(sqlite3 *);
}
 function sqlite3_close(DB : Pointer) : integer; cdecl; external DLLSqlite name 'sqlite3_close';

{int sqlite3_exec(
  sqlite3*,                                  /* An open database */
  const char *sql,                           /* SQL to be evaluated */
  int (*callback)(void*,int,char**,char**),  /* Callback function */
  void *,                                    /* 1st argument to callback */
  char **errmsg                              /* Error msg written here */
);
}
function sqlite3_exec(DB: Pointer; Sql : pchar; Callback : Pointer; FirstParam : Pointer; Var Error : pchar): integer;cdecl;external DLLSqlite name 'sqlite3_exec';

{
int sqlite3_prepare_v2(
  sqlite3 *db,            /* Database handle */
  const char *zSql,       /* SQL statement, UTF-8 encoded */
  int nByte,              /* Maximum length of zSql in bytes. */
  sqlite3_stmt **ppStmt,  /* OUT: Statement handle */
  const char **pzTail     /* OUT: Pointer to unused portion of zSql */
);
}
function sqlite3_prepare_v2 (DB : Pointer; Sql : pchar; Bytes : Integer; Var Statement : Pointer; Var Tail : pchar) : Integer; cdecl; external DLLSqlite name 'sqlite3_prepare_v2';

{
int sqlite3_step(sqlite3_stmt*);
}

function sqlite3_step(Statement: Pointer) : Integer;cdecl; external DLLSQLite name 'sqlite3_step';

{
int sqlite3_column_count(sqlite3_stmt *pStmt);
}
function sqlite3_column_count(Statement : Pointer) : Integer;cdecl;external DLLSQLite name 'sqlite3_column_count';

{
int sqlite3_column_int(sqlite3_stmt*, int iCol);
}

function sqlite3_column_int(Statement : Pointer; iCol: Integer):Integer;cdecl;external DLLSQLite name 'sqlite3_column_int';

{
int sqlite3_column_bytes(sqlite3_stmt*, int iCol);
}

function sqlite3_column_bytes(Statement : Pointer; iCol: Integer): Integer;cdecl;external DLLSQLite name 'sqlite3_column_bytes';

{
const unsigned char *sqlite3_column_text(sqlite3_stmt*, int iCol);
}

function sqlite3_column_text(Statement : Pointer; iCol: Integer): pchar;cdecl;external DLLSQLite name 'sqlite3_column_text';

{const char *sqlite3_errmsg(sqlite3*);}

 function sqlite3_errmsg(DB : Pointer):pchar;cdecl;external DLLSQLite name 'sqlite3_errmsg';

{
int sqlite3_column_type(sqlite3_stmt*, int iCol);
}

{
int sqlite3_finalize(sqlite3_stmt *pStmt);
}
function sqlite3_finalize(Statement : Pointer) : Integer;cdecl;external DLLSQLite name 'sqlite3_finalize';

{
void sqlite3_free(void*);
}

procedure sqlite3_free(SLObject : Pointer);cdecl;external DLLSQLite name 'sqlite3_free'; 

{ TSql }

function TSql.closeDatabase: integer;
begin
	if Assigned(DB) then Begin
		sqlerror := sqlite3_close(DB);
		DB := nil;
	End;
	Result := sqlerror;
end;

function TSql.CountDistinct(const Table, Columns, Where: String): Integer;
const Sql = ' select count(*) from (select %s from %s %s);';
Var  tail : pchar;
     Select : String;
begin
  Result := -1;
  If Where = EmptyStr Then
    Select := Format(Sql,[Columns,Table,Where])
  Else
    Select := Format(Sql,[Columns,Table,Format('where %s',[Where])]);

	sqlerror := sqlite3_prepare_v2(DB,pchar(Select),-1,Stmt,tail);
	if (sqlerror = SQLITE_OK) Then Begin
		sqlerror := sqlite3_step(Stmt);
		if (sqlerror = SQLITE_ROW) Then Begin
			Result := sqlite3_column_int(Stmt,0);
      sqlerror := sqlite3_step(Stmt);
    End;
	End;
	if (sqlerror = SQLITE_DONE) Then Begin
	  sqlite3_finalize(Stmt);
    Stmt := nil;
    sqlerror := SQLITE_OK;
  End;

end;

function TSql.CountSelect(const Table,Where: String): integer;
const Sql = 'select count(*) from %s %s;';
Var  tail : pchar;
     Select : String;
begin
  Result := -1;
  If Where = EmptyStr Then
    Select := Format(Sql,[Table,Where])
  Else
    Select := Format(Sql,[Table,Format('where %s',[Where])]);

	sqlerror := sqlite3_prepare_v2(DB,pchar(Select),-1,Stmt,tail);
	if (sqlerror = SQLITE_OK) Then Begin
		sqlerror := sqlite3_step(Stmt);
		if (sqlerror = SQLITE_ROW) Then Begin
			Result := sqlite3_column_int(Stmt,0);
      sqlerror := sqlite3_step(Stmt);
    End;
	End;
	if (sqlerror = SQLITE_DONE) Then Begin
	  sqlite3_finalize(Stmt);
    Stmt := nil;
    sqlerror := SQLITE_OK;
  End;
end;

constructor TSql.Create(const Database: String;Var Error : Integer;
    Var ErrorMsg  : String);
begin
  DB := Nil;
	sqlerror := sqlite3_open_v2(pchar(Database),&DB,SQLITE_OPEN_READWRITE,nil);
  Error := sqlerror;  
	if (sqlerror <> SQLITE_OK) Then Begin
		ErrorMsg := sqlite3_errmsg(DB);
		sqlite3_close(DB);
// le pointeur assigné par la Dll Sqlite ne peut être libéré que par ses soins.
// Sa valeur n'a plus de sens après le CLose. Mise à Nil préventive.
		DB := nil;
	End
end;

destructor TSql.Destroy;
begin
	if (Stmt <> nil ) Then
	  sqlite3_finalize(Stmt);  

  closeDatabase;
end;

procedure TSql.Fetch(var Row: array of TVarRec);
Var
  C,I,Sz : Integer;
  Text : pchar;
begin
if Stmt = nil then exit;
C := sqlite3_column_count(Stmt);
If Length(Row) < C Then
  Exit;


For I := 0 To C-1 Do
  case Row[I].VType of
    VtInteger:
       Row[I].VInteger := sqlite3_column_int(Stmt,I);
    vtPChar:
    Begin
       Text := sqlite3_column_text(Stmt,I);
       Sz := sqlite3_column_bytes(Stmt,I);
       Row[I].vPChar := StrNew(Text);
    End;
{    VtInt64 :
       Row[I].VInt64 :=
}  end;
  //Préparer la row suivante ou finaliser si aucune row.
	sqlerror := sqlite3_step(Stmt);

	if (sqlerror = SQLITE_DONE) Then Begin
	  sqlite3_finalize(Stmt);
    Stmt := nil;
    sqlerror := SQLITE_OK;
  End;

end;

function TSql.insert(const tables, columns, values: String): Integer;
  Const InsertStmt = 'insert into "%s" (%s) values (%s);';
Var
  Insert : String;
  Error  : pchar;
begin
  Result := sqlerror;
  if (sqlerror <> SQLITE_OK) Then Exit;

  Insert := Format(InsertStmt,[tables,columns,values] );
  sqlerror := sqlite3_exec(DB,pchar(Insert),nil,nil,Error);
  If sqlerror <> SQLITE_OK Then
    FErrorMsg := sqlite3_errmsg(DB);
  Result := sqlerror;

  sqlite3_free(Error);

end;

function TSql.LastRowId(const table, Where: String;Var RowId : Integer): Integer;
Const RowIDStmt  = 'select into "%s" where %s;';

Var   Request : String;
      Error  : pchar;
begin
  Result := sqlerror;
  if (sqlerror <> SQLITE_OK) Then Exit;

  Request  := Format(RowIDStmt,[table,Where] );
  sqlerror := sqlite3_exec(DB,pchar(Request),nil,nil,Error);
  Result   := sqlerror;
  sqlite3_free(Error);

  if (sqlerror = SQLITE_ROW) Then Begin
    RowId := sqlite3_column_int(Stmt,0);
    sqlerror := sqlite3_step(Stmt);
    Result := sqlerror;
  End;

end;

function TSql.Select(const Table, columns, where: String; var Count : Integer): integer;

  Const SelectStmt = 'select %s from %s %s;';
  var
    Select : String;
    Tail   : pchar;
    I: Integer;
begin
  Count := -1;
  //Une requête en cours
  Result := SQLITE_BUSY;
  if (Stmt <> nil) Then Exit;

  //Une erreur précédente.
  Result := sqlerror;
  if (sqlerror <> SQLITE_OK) Then Exit;

  If Pos('distinct',columns) > 0 Then
  Count  :=	CountDistinct(Table,columns,where)
  Else
  Count  :=	CountSelect(table,where);

  Result := SQLITE_OK;
  if count <= 0 then exit;

  If Where = EmptyStr Then
    Select := Format(SelectStmt,[columns,Table,Where])
  Else
    Select := Format(SelectStmt,[columns,Table,Format('where %s',[Where])]);

	sqlerror := sqlite3_prepare_v2(DB,pchar(Select),-1,Stmt,tail);
	if (sqlerror = SQLITE_OK) Then Begin
		sqlerror := sqlite3_step(Stmt);
    case sqlerror of
      SQLITE_ROW: Begin
      Result := SQLITE_OK;
      End;

      SQLITE_DONE: Begin
      Count := 0;
      Result := SQLITE_OK;
      End;
    end;
	End;

  if Result <> SQLITE_OK then
    result := -sqlerror;
end;

function TSql.Update(const tables, sets, where: String;Var Count : Integer): Integer;
const UPdateStmt = 'update %s set %s where %s';
Var
  Select : String;
  tail   : pchar;
begin
//
  Count := -1;
  //Une requête en cours
  Result := SQLITE_BUSY;
  if (Stmt <> nil) Then Exit;

  //Une erreur précédente.
  Result := sqlerror;
  if (sqlerror <> SQLITE_OK) Then Exit;

  Count  :=	CountSelect(tables,where);

  Result := -1;
  if count <= 0 then exit;

  Select :=  Format(UPdateStmt,[tables,sets,where]);

	sqlerror := sqlite3_prepare_v2(DB,pchar(Select),-1,Stmt,tail);
	if (sqlerror = SQLITE_OK) Then Begin
		sqlerror := sqlite3_step(Stmt);
    case sqlerror of
      SQLITE_ROW: Begin
      Result := SQLITE_OK;
      End;

      SQLITE_DONE: Begin
      Count := 0;
      sqlite3_finalize(Stmt);
      Stmt := nil;
      sqlerror := SQLITE_OK;
      Result := SQLITE_OK;
      End;
    end;
	End;

  if Result <> SQLITE_OK then
    result := -sqlerror;

end;

End.
