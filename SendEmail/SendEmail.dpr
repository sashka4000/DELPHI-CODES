program SendEmail;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Classes, IdGlobal, System.Generics.Collections,
  IdTCPConnection, IdTCPClient,
  IdExplicitTLSClientServerBase, IdMessageClient, IdSMTPBase, IdSMTP, IdMessage,
  IdAttachment, IdAttachmentFile,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
  CommandParser in 'CommandParser.pas',
  ParseIds in 'ParseIds.pas',
  PropertyHelpers in 'PropertyHelpers.pas';

type
 TSenderClass = class (TComponent)
  private
    idsmtp2: TIdSMTP;
    idmsg1: TIdMessage;
    idssl1: TIdSSLIOHandlerSocketOpenSSL;
    AttachList : TObjectList<TIdAttachmentFile>;
    FBodyText: String;
    FAttachFiles: String;
    FSubject: String;
    FPort: Integer;
    FPassword: String;
    FUseSSL: Integer;
    FLogin: String;
    Fhost: string;
    FCP : TCommandParser;
    FFromMail: String;
    FToMail: String;
    FUseLogin: Integer;
  public
    constructor Create;
    destructor Destroy; override;
  published
   property Host : string read Fhost write FHost;
   property Port: Integer read FPort write FPort;
   property Login: String read FLogin write FLogin;
   property Password: String read FPassword write FPassword;
   property UseLogin: Integer read FUseLogin write FUseLogin;
   property UseSSL: Integer read FUseSSL write FUseSSL;
   property Subject: String read FSubject write FSubject;
   property BodyText: String read FBodyText write FBodyText;
   property AttachFiles: String read FAttachFiles write FAttachFiles;
   property FromMail: String read FFromMail write FFromMail;
   property ToMail: String read FToMail write FToMail;
 end;

{ TSenderClass }

constructor TSenderClass.Create;
begin
  idsmtp2 := TIdSMTP.Create(nil);
  idmsg1 := TIdMessage.Create(nil);
  idssl1 := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  AttachList := TObjectList<TIdAttachmentFile>.Create;
  Self.Host := '';
  Self.Port := 25;
  Self.Login := '';
  Self.Password := '';
  Self.UseLogin := 1;
  Self.FUseSSL := 0;
  Self.AttachFiles := '';
  Self.Subject := '';

  FCP := TCommandParser.Create(Self,False,'SendEmail via command line','');
  FCP.AddSwitch('mto',stString,true,'','E-mail адрес получателя','','ToMail');
  FCP.AddSwitch('mfrom',stString,true,'','E-mail адрес отправителя','','FromMail');
  FCP.AddSwitch('host',stString,true,'smtp.mail.ru','Адрес SNMP-сервера','','Host');
  FCP.AddSwitch('port',stInteger,false,'25','Порт SNMP-сервера','','Port');
  FCP.AddSwitch('auth',stInteger,false,'1','Аутентификация по логину и паролю (Да:1, Нет:0)','','UseLogin');
  FCP.AddSwitch('user',stString,true,'login','Логин','','Login');
  FCP.AddSwitch('pass',stString,true,'password','Пароль','','Password');
  FCP.AddSwitch('ssl',stInteger,false,'0','Использовать SSL-подключение (Да:1, Нет:0)','','UseSSL');
  FCP.AddSwitch('subj',stString,true,'','Тема письма','','Subject');
  FCP.AddSwitch('bodyt',stString,false,'','Текст сообщения','','BodyText');
  FCP.AddSwitch('attfiles',stString,false,'','Прикрепить файлы file1, file2','','AttachFiles');
end;


destructor TSenderClass.Destroy;
begin
  AttachList.Free;
  idssl1.Free;
  idmsg1.Free;
  idsmtp2.Free;
  inherited;
end;

var
 SS : TSenderClass;
 tmpfilename : String;

begin
 SS := TSenderClass.Create;
 try
    try
      if (not SS.FCP.ProcessCommandLine)  then
      begin
         writeln (SS.FCP.HelpText);
         ExitCode := 1;
         Exit;
      end;

      if SS.UseSSL = 1 then
      begin
        ss.idsmtp2.IOHandler := ss.idssl1;
        ss.idssl1.SSLOptions.Method := sslvTLSv1;
        SS.idsmtp2.UseTLS := utUseImplicitTLS;
      end
      else
      begin
        ss.idsmtp2.IOHandler := nil;
        ss.idsmtp2.UseTLS := utNoTLSSupport;
      end;
      if (SS.UseLogin = 1) then
      begin
        ss.idsmtp2.AuthType := satDefault;
        ss.idsmtp2.Username := ss.Login;
        ss.idsmtp2.Password := ss.Password;
      end
      else
        ss.idsmtp2.AuthType := satNone;

      ss.idsmtp2.Host := ss.Host;
      ss.idsmtp2.Port := ss.Port;

     // ss.idmsg1.ContentType := 'text/plain';
      ss.idmsg1.CharSet := 'Windows-1251';
      ss.idmsg1.From.Address :=  SS.FromMail;
      ss.idmsg1.Recipients.EMailAddresses := SS.ToMail;
      ss.idmsg1.Subject := ss.Subject;
      ss.idmsg1.Body.Text := ss.BodyText;

      ss.idmsg1.IsEncoded := true;

      ss.idmsg1.MessageParts.Clear;
      if SS.AttachFiles <> '' then
      begin
        while SS.AttachFiles <> '' do
        begin
           tmpfilename := Trim(fetch (SS.FAttachFiles,','));
           if not FileExists(tmpfilename) then
           begin
              writeln ('Не найден файл: ' + tmpfilename);
              Exit;
           end;
          ss.AttachList.Add (TIdAttachmentFile.Create(ss.idmsg1.MessageParts,tmpfilename));
        end;
      end;

      if ss.AttachList.Count > 1 then
         ss.idmsg1.Encoding:= meMIME;

      ss.idsmtp2.Connect;
      SS.idsmtp2.Send(ss.idmsg1);
      ss.idsmtp2.Disconnect();


    except
      on E: Exception do
      begin
        Writeln(E.ClassName, ': ', E.Message);
        ExitCode := 2;
      end;
    end;
 finally
    SS.Free;
 end;
end.
