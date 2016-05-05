{
 This is a personal project that I give to community under this licence:

Copyright 2016 Eric Buso (Alias Caine_dvp)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
}
program UWebLogAnalyser_OneLog;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{%ToDo 'UWebLogAnalyser.todo'}

uses
  Forms, Interfaces,
  UMain in 'UMain.pas' {fmMain},
  UFiles in 'UFiles.pas',
  UCommons in 'UCommons.pas', UDataEngine;

{$R *.res}

begin
  Application.Title:='WebLogAnalyzer - OneLog';
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
