# ThumbnailProvider 
Показан пример реализации интерфейса IThumbnailprovider для отображения 
миниатюр файлов в окне просмотра Проводника Windows.
Библиотека должна быть собрана под Win64 или под Win32.
И в том и в другом случае для регистрации используется команда

regsvr32 SampleThumbnail.dll

В тестовом примере регистрируется просмотр для выдуманных файлов bmp2.
Для проверки работы, просто переименуйте расширение какого-нибудь bmp-файл в bmp2.

Описание параметров  cx, pdwAlpha  см. в справке MSDN на IThumbnailprovider.

Замечание: для корректного отображения файлов в TOpenDialog вам может также потребоваться 
реализация интерфейса IPreviewHandler.
См. например: http://www.uweraabe.de/Blog/2011/06/01/windows-7-previews-the-delphi-way/

An example of implementation of the IThumbnailprovider interface for displaying
file thumbnails in the Windows Explorer viewer.
The library must be compiled under Win64 or under Win32.
In both cases, the command is used to register

regsvr32 SampleThumbnail.dll

The test case registers a view for fake bmp2 files.
To test it, just rename the extension of some bmp file to bmp2.

For a description of the cx, pdwAlpha parameters, see the MSDN Help on IThumbnailprovider.

Note: to display files correctly in TOpenDialog, you may also need
implementation of the IPreviewHandler interface.
See for example: http://www.uweraabe.de/Blog/2011/06/01/windows-7-previews-the-delphi-way/