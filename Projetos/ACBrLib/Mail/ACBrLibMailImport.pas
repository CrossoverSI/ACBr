﻿{******************************************************************************}
{ Projeto: Componentes ACBr                                                    }
{  Biblioteca multiplataforma de componentes Delphi para interação com equipa- }
{ mentos de Automação Comercial utilizados no Brasil                           }

{ Direitos Autorais Reservados (c) 2018 Daniel Simoes de Almeida               }

{ Colaboradores nesse arquivo: Rafael Teno Dias                                }

{  Você pode obter a última versão desse arquivo na pagina do  Projeto ACBr    }
{ Componentes localizado em      http://www.sourceforge.net/projects/acbr      }

{  Esta biblioteca é software livre; você pode redistribuí-la e/ou modificá-la }
{ sob os termos da Licença Pública Geral Menor do GNU conforme publicada pela  }
{ Free Software Foundation; tanto a versão 2.1 da Licença, ou (a seu critério) }
{ qualquer versão posterior.                                                   }

{  Esta biblioteca é distribuída na expectativa de que seja útil, porém, SEM   }
{ NENHUMA GARANTIA; nem mesmo a garantia implícita de COMERCIABILIDADE OU      }
{ ADEQUAÇÃO A UMA FINALIDADE ESPECÍFICA. Consulte a Licença Pública Geral Menor}
{ do GNU para mais detalhes. (Arquivo LICENÇA.TXT ou LICENSE.TXT)              }

{  Você deve ter recebido uma cópia da Licença Pública Geral Menor do GNU junto}
{ com esta biblioteca; se não, escreva para a Free Software Foundation, Inc.,  }
{ no endereço 59 Temple Street, Suite 330, Boston, MA 02111-1307 USA.          }
{ Você também pode obter uma copia da licença em:                              }
{ http://www.opensource.org/licenses/gpl-license.php                           }

{ Daniel Simões de Almeida  -  daniel@djsystem.com.br  -  www.djsystem.com.br  }
{        Rua Cel.Aureliano de Camargo, 973 - Tatuí - SP - 18270-170            }

{******************************************************************************}

{$I ACBr.inc}

unit ACBrLibMailImport;

interface

uses
  Classes, SysUtils, DynLibs,
  ACBrMail;

const
 {$IfDef MSWINDOWS}
  {$IfDef CPU64}
  CACBrMailLIBName = 'ACBrMail64.dll';
  {$Else}
  CACBrMailLIBName = 'ACBrMail32.dll';
  {$EndIf}
 {$Else}
  {$IfDef CPU64}
  CACBrMailLIBName = 'ACBrMail64.so';
  {$Else}
  CACBrMailLIBName = 'ACBrMail32.so';
  {$EndIf}
 {$EndIf}

type
  PACBrMail = ^TACBrMail;

  TMailInicializar = function(const eArqConfig, eChaveCrypt: PChar): longint;
    {$IfDef STDCALL} stdcall{$Else} cdecl{$EndIf};
  TMailFinalizar = function: longint;
    {$IfDef STDCALL} stdcall{$Else} cdecl{$EndIf};
  TMailUltimoRetorno = function(const sMensagem: PChar; var esTamanho: longint): longint;
    {$IfDef STDCALL} stdcall{$Else} cdecl{$EndIf};
  TMailGetMail = function(var handle: PACBrMail): longint;
    {$IfDef STDCALL} stdcall{$Else} cdecl{$EndIf};

  TACBrLibMail = class
  private
    FHandle: TLibHandle;
    FMailInicializar: TMailInicializar;
    FMailFinalizar: TMailFinalizar;
    FMailUltimoRetorno: TMailUltimoRetorno;
    FMailGetMail: TMailGetMail;

    procedure LoadLib;
    procedure UnLoadLib;
    procedure CheckResut(const resultado: longint);

  public
    constructor Create(ArqConfig: string = ''; ChaveCrypt: ansistring = '');
    destructor Destroy; override;

    function GetMail: TACBrMail;
  end;

implementation

constructor TACBrLibMail.Create(ArqConfig: string; ChaveCrypt: ansistring);
Var
  ret: longint;
begin
  inherited Create();
  LoadLib;

  ret := FMailInicializar(PChar(ArqConfig), PChar(ChaveCrypt));
  CheckResut(ret);
end;

destructor TACBrLibMail.Destroy;
Var
  ret: longint;
begin
  ret := FMailFinalizar;
  CheckResut(ret);

  UnLoadLib;
  inherited Destroy;
end;

procedure TACBrLibMail.LoadLib;
begin
  FHandle := LoadLibrary(CACBrMailLIBName);

  FMailInicializar := GetProcedureAddress(FHandle, 'MAIL_Inicializar');
  FMailFinalizar := GetProcedureAddress(FHandle, 'MAIL_Finalizar');
  FMailUltimoRetorno := GetProcedureAddress(FHandle, 'MAIL_UltimoRetorno');
  FMailGetMail := GetProcedureAddress(FHandle, 'MAIL_GetMail');
end;

procedure TACBrLibMail.UnLoadLib;
begin
  UnloadLibrary(FHandle);

  FMailInicializar := nil;
  FMailFinalizar := nil;
  FMailUltimoRetorno := nil;
  FMailGetMail := nil;
end;

procedure TACBrLibMail.CheckResut(const resultado: longint);
Var
  bufferLen: longint;
  sMensagem: string;
begin
  if resultado >= 0 then Exit;

  bufferLen := 256;
  sMensagem := Space(bufferLen);
  FMailUltimoRetorno(PChar(sMensagem), bufferLen);

  if bufferLen > 256 then
  begin
    sMensagem := Space(bufferLen);
    FMailUltimoRetorno(PChar(sMensagem), bufferLen);
  end;

  Raise Exception.Create(Trim(sMensagem));
end;

function TACBrLibMail.GetMail: TACBrMail;
Var
  ret: longint;
  mail: PACBrMail;
begin
  mail := nil;
  ret := FMailGetMail(mail);
  CheckResut(ret);

  Result := TACBrMail(mail^);
end;

end.