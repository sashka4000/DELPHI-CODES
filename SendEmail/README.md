# SendEmail
Утилита предназначена для отправки сообщений электронной почты из командной строки.

Утилита позволяет:
* отправить текстовое сообщение 
* отправить текстовое сообщение с прикрепленным файлом, файлами

SendEmail via command line
Syntax:
  SendEmail.exe /mto /mfrom /host [/port] [/auth] /user /pass [/ssl] /subj [/bodyt] [/attfiles]
Parameters:
  /mto - E-mail адрес получателя
  /mfrom - E-mail адрес отправителя
  /host - Адрес SNMP-сервера
    Default: smtp.mail.ru. Example: /host:smtp.mail.ru
  [/port] - Порт SNMP-сервера (Optional)
    Default: 25. Example: /port:25
  [/auth] - Аутентификация по логину и паролю (Да:1, Нет:0) (Optional)
    Default: 1. Example: /auth:1
  /user - Логин
    Default: login. Example: /user:login
  /pass - Пароль
    Default: password. Example: /pass:password
  [/ssl] - Использовать SSL-подключение (Да:1, Нет:0) (Optional)
    Default: 0. Example: /ssl:0
  /subj - Тема письма
  [/bodyt] - Текст сообщения (Optional)
  [/attfiles] - Прикрепить файлы file1, file2 (Optional)
