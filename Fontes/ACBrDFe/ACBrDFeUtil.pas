{******************************************************************************}
{ Projeto: Componente ACBrNFe                                                  }
{  Biblioteca multiplataforma de componentes Delphi para emiss�o de Nota Fiscal}
{ eletr�nica - NFe - http://www.nfe.fazenda.gov.br                          }

{ Direitos Autorais Reservados (c) 2008 Wemerson Souto                         }
{                                       Daniel Simoes de Almeida               }
{                                       Andr� Ferreira de Moraes               }

{ Colaboradores nesse arquivo:                                                 }

{  Voc� pode obter a �ltima vers�o desse arquivo na pagina do Projeto ACBr     }
{ Componentes localizado em http://www.sourceforge.net/projects/acbr           }


{  Esta biblioteca � software livre; voc� pode redistribu�-la e/ou modific�-la }
{ sob os termos da Licen�a P�blica Geral Menor do GNU conforme publicada pela  }
{ Free Software Foundation; tanto a vers�o 2.1 da Licen�a, ou (a seu crit�rio) }
{ qualquer vers�o posterior.                                                   }

{  Esta biblioteca � distribu�da na expectativa de que seja �til, por�m, SEM   }
{ NENHUMA GARANTIA; nem mesmo a garantia impl�cita de COMERCIABILIDADE OU      }
{ ADEQUA��O A UMA FINALIDADE ESPEC�FICA. Consulte a Licen�a P�blica Geral Menor}
{ do GNU para mais detalhes. (Arquivo LICEN�A.TXT ou LICENSE.TXT)              }

{  Voc� deve ter recebido uma c�pia da Licen�a P�blica Geral Menor do GNU junto}
{ com esta biblioteca; se n�o, escreva para a Free Software Foundation, Inc.,  }
{ no endere�o 59 Temple Street, Suite 330, Boston, MA 02111-1307 USA.          }
{ Voc� tamb�m pode obter uma copia da licen�a em:                              }
{ http://www.opensource.org/licenses/lgpl-license.php                          }

{ Daniel Sim�es de Almeida  -  daniel@djsystem.com.br  -  www.djsystem.com.br  }
{              Pra�a Anita Costa, 34 - Tatu� - SP - 18270-410                  }

{******************************************************************************}

{$I ACBr.inc}

unit ACBrDFeUtil;

interface

uses
  Classes, StrUtils, SysUtils,
  ACBrDFeSSL;

function FormatarNumeroDocumentoFiscal(AValue: String): String;
function FormatarNumeroDocumentoFiscalNFSe(AValue: String): String;
function GerarChaveAcesso(AUF:Integer; ADataEmissao:TDateTime; ACNPJ:String; ASerie:Integer;
                           ANumero,ACodigo: Integer; AModelo:Integer=55): String;
function FormatarChaveAcesso(AValue: String): String;

function XmlEstaAssinado(const AXML: String): Boolean;
function SignatureElement(const URI: String; AddX509Data: Boolean;
    IdSignature: String = ''; const Digest: TSSLDgst = dgstSHA1): String;
function ExtraiURI(const AXML: String; IdAttr: String = ''): String;


implementation

uses
  Variants, DateUtils,
  ACBrDFeException, ACBrUtil, ACBrValidador ;

function FormatarNumeroDocumentoFiscal(AValue: String): String;
begin
  AValue := Poem_Zeros(AValue, 9);
  Result := copy(AValue, 1, 3) + '.' + copy(AValue, 4, 3) + '.' + copy(AValue, 7, 3);
end;

function FormatarNumeroDocumentoFiscalNFSe(AValue: String): String;
begin
  AValue := Poem_Zeros(AValue, 15);
  Result := copy(AValue, 1, 4) + '.' + copy(AValue, 5, 12);
end;

function GerarChaveAcesso(AUF: Integer; ADataEmissao: TDateTime; ACNPJ: String;
  ASerie: Integer; ANumero, ACodigo: Integer; AModelo: Integer): String;
var
  vUF, vDataEmissao, vSerie, vNumero, vCodigo, vModelo: String;
begin
  vUF          := Poem_Zeros(AUF, 2);
  vDataEmissao := FormatDateTime('YYMM', ADataEmissao);
  vModelo      := Poem_Zeros(AModelo, 2);
  vSerie       := Poem_Zeros(ASerie, 3);
  vNumero      := Poem_Zeros(ANumero, 9);
  vCodigo      := Poem_Zeros(ACodigo, 9);

  Result := vUF + vDataEmissao + ACNPJ + vModelo + vSerie + vNumero + vCodigo;
  Result := Result + Modulo11(Result);
end;

function FormatarChaveAcesso(AValue: String): String;
var
  I: Integer;
begin
  AValue := OnlyNumber(AValue);
  I := 1;
  Result := '';
  while I < Length(AValue) do
  begin
    Result := Result+copy(AValue,I,4)+' ';
    Inc( I, 4);
  end;

  Result := Trim(Result);
end;

function XmlEstaAssinado(const AXML: String): Boolean;
begin
  Result := (pos('<signature', lowercase(AXML)) > 0);
end;

function SignatureElement(const URI: String; AddX509Data: Boolean;
  IdSignature: String; const Digest: TSSLDgst): String;
var
  MethodAlgorithm, DigestAlgorithm: String;
begin
  case Digest of
    dgstSHA256:
      begin
        MethodAlgorithm := 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256';
        DigestAlgorithm := 'http://www.w3.org/2001/04/xmlenc#sha256';
      end;
    else
      begin
        MethodAlgorithm := 'http://www.w3.org/2000/09/xmldsig#rsa-sha1';
        DigestAlgorithm := 'http://www.w3.org/2000/09/xmldsig#sha1';
      end;
  end;

  {(*}
  Result :=
  '<Signature xmlns="http://www.w3.org/2000/09/xmldsig#"' + IdSignature + '>' +
    '<SignedInfo>' +
      '<CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315" />' +
      '<SignatureMethod Algorithm="'+MethodAlgorithm+'" />' +
      '<Reference URI="' + IfThen(URI = '', '', '#' + URI) + '">' +
        '<Transforms>' +
          '<Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />' +
          '<Transform Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315" />' +
        '</Transforms>' +
        '<DigestMethod Algorithm="'+DigestAlgorithm+'" />' +
        '<DigestValue></DigestValue>' +
      '</Reference>' +
    '</SignedInfo>' +
    '<SignatureValue></SignatureValue>' +
    '<KeyInfo>' +
    IfThen(AddX509Data,
      '<X509Data>' +
        '<X509Certificate></X509Certificate>'+
      '</X509Data>',
      '')+
    '</KeyInfo>'+
  '</Signature>';
  {*)}
end;

function ExtraiURI(const AXML: String; IdAttr: String): String;
var
  I, J: integer;
begin
  Result := '';
  if IdAttr = '' then
    IdAttr := 'Id';

  I := PosEx(IdAttr+'=', AXML);
  if I = 0 then       // XML n�o tem URI
    Exit;

  I := PosEx('"', AXML, I + 2);
  if I = 0 then
    raise EACBrDFeException.Create('N�o encontrei inicio do URI: aspas inicial');

  J := PosEx('"', AXML, I + 1);
  if J = 0 then
    raise EACBrDFeException.Create('N�o encontrei inicio do URI: aspas final');

  Result := copy(AXML, I + 1, J - I - 1);
end;


end.
