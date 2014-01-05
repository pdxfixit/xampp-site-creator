@Echo Off
REM XAMPP Site Creation Script v2.4.1
REM Copyleft (c) 2012-2013, PDXfixIT, LLC
REM
REM -= Begin Variables =-
REM
REM Default User Details
SET DEFAULTEMAIL=ben@pdxfixit.com
SET DEFAULTNAME=Ben Sandberg
SET DEFAULTUSER=ben
REM
REM Database prefix string.  No underscores here, please.
SET DEFAULTPREFIX=jos
REM
REM Current Directory
SET DIR=%CD%
REM
REM Same as the htdocs, but with a forward slash, to match Unix-style.
SET DOCROOT=B:/www
REM 
REM Extracted contents of a Joomla 2.5.x release -- installation folder and all.
SET J2INSTALLERFOLDER=B:\www\J2installer
REM 
REM Extracted contents of a Joomla 3.x release -- installation folder and all.
SET J3INSTALLERFOLDER=B:\www\J3installer
REM
REM Web root (htdocs) folder.
SET WWW=B:\www
REM
REM XAMPP root folder.
SET XAMPP=B:\xampp
REM
REM -= End Variables =-

:INITIALIZATION
REM Check Windows version
ver | findstr /i "5\.0\." > NUL
IF %ERRORLEVEL% == 0 (
  ECHO Sorry, Windows XP SP2 or later is required, due to PowerShell dependencies.
  GOTO ERROR
)

REM Check for Administrator elevation
NET SESSION >nul 2>&1
IF NOT %ERRORLEVEL% == 0 (
  ECHO Administrator privileges are required.
  GOTO ERROR
)

:MENU
CLS
ECHO.
ECHO /=============================================================================\
ECHO ^|                       XAMPP Site Creation Script v2.5                       ^|
ECHO ^|                        Last Updated: January 4, 2014                        ^|
ECHO ^|                https://github.com/pdxfixit/xampp-site-creator               ^|
ECHO ^>=============================================================================^<
ECHO ^|                                                                             ^|
ECHO ^|                   Please type a selection and press ENTER.                  ^|
ECHO ^|                                                                             ^|
ECHO ^|    1     Generic Website                                                    ^|
ECHO ^|                                                                             ^|
ECHO ^|    2     Joomla! 2.5.x Installation                                         ^|
ECHO ^|                                                                             ^|
ECHO ^|    3     Joomla! 3.x Installation                                           ^|
ECHO ^|                                                                             ^|
ECHO ^|    4     Kickstart Joomla! Installation                                     ^|
ECHO ^|                                                                             ^|
ECHO ^|    5     RocketLauncher Joomla! Installation                                ^|
ECHO ^|                                                                             ^|
ECHO ^|    0     Delete an Installation                                             ^|
ECHO ^|                                                                             ^|
ECHO ^|                              Or, type EXIT.                                 ^|
ECHO ^|                                                                             ^|
ECHO \=============================================================================/
ECHO.
SET /p CHOICE=Your selection? 
REM Escape Hatch
IF /i "%CHOICE%" == "EXIT" GOTO EXIT

:PROCESSOR
CLS
IF %CHOICE% == 0 (
	SET CHOICE=DELETE
	GOTO SITENAME
)
IF %CHOICE% == 1 (
	SET CHOICE=GENERIC
	GOTO SITENAME
)
IF %CHOICE% == 2 (
	SET CHOICE=JOOMLA
	SET JVER=2
	GOTO SITENAME
)
IF %CHOICE% == 3 (
	SET CHOICE=JOOMLA
	SET JVER=3
	GOTO SITENAME
)
IF %CHOICE% == 4 (
	SET CHOICE=KICKSTART
	GOTO SITENAME
)
IF %CHOICE% == 5 (
	SET CHOICE=ROCKETLAUNCHER
	GOTO SITENAME
)
GOTO ERROR

:SITENAME
SET /p SITE=What is the short name of the site? 
IF %CHOICE% == DELETE (
	GOTO DELETE
) ELSE (
REM todo: Future feature -- check to see if the site already exists.
	GOTO FILES
)

:FILES
chdir /d %WWW%
mkdir %SITE%
IF NOT EXIST %SITE% (
	ECHO.
	ECHO.
	ECHO Error creating directory.
	GOTO ERROR
)
REM todo: Future feature -- check for Joomla! installation folder before proceeding
IF %CHOICE% == GENERIC GOTO DBCHOICE
IF %CHOICE% == JOOMLA GOTO JOOMLA
IF %CHOICE% == KICKSTART GOTO KICKSTART
IF %CHOICE% == ROCKETLAUNCHER GOTO ROCKETLAUNCHER
ECHO.
ECHO.
ECHO Error choosing a path.
GOTO ERROR

:DBCHOICE
ECHO.
SET /p DBDESIRE=Would you like a database created? 
IF /i %DBDESIRE% == Y (
  GOTO CREATEDB
)
GOTO HOSTS

:JOOMLA
ECHO.
ECHO Copying Joomla files...
chdir /d %WWW%\%SITE%
IF %JVER% == 2 (
	SET INSTALLERFOLDER=%J2INSTALLERFOLDER%
)
IF %JVER% == 3 (
	SET INSTALLERFOLDER=%J3INSTALLERFOLDER%
)
xcopy %INSTALLERFOLDER% . /q /s /v > NUL
GOTO DBPREP

:KICKSTART
CLS
ECHO.
ECHO.
ECHO Next, please copy the JPA file into the available folder.
ECHO.
SET /p CONTINUE=Press ENTER to open the folder and continue.
START %WWW%\%SITE%
CLS
ECHO.
ECHO.
SET /p CONTINUE=Close the window and press ENTER here when ready to continue.
chdir /d %WWW%\%SITE%
copy %INSTALLERFOLDER%\kickstart.php . /v > NUL
GOTO CREATEDB

:ROCKETLAUNCHER
CLS
ECHO.
ECHO.
ECHO Please extract the contents of the RocketLauncher into the available folder.
ECHO.
SET /p CONTINUE=Press ENTER to open the folder and continue.
START %WWW%\%SITE%
CLS
ECHO.
ECHO.
SET /p CONTINUE=Close the window and press ENTER here when ready to continue.
CLS
GOTO DBPREP

:DBPREP
CLS
ECHO.
ECHO What is your preferred database prefix?
ECHO (no underscores please; we'll add them)
ECHO (or, press ENTER to accept the default)
SET /p PREFIX=prefix: 
IF "%PREFIX%" == "" SET PREFIX=%DEFAULTPREFIX%
chdir /d %WWW%\%SITE%
powershell -Command "Get-Content installation\sql\mysql\joomla.sql | ForEach-Object { $_ -replace '#__', '%PREFIX%_' } | Set-Content jinstaller.sql"
GOTO CONFIGURATION

:CONFIGURATION
chdir /d %WWW%\%SITE%
CLS
ECHO.
SET /p SITENAME=What is the descriptive name of this site? 
ECHO.
ECHO Thank you, generating configuration.php...
(ECHO ^<?php&&ECHO class JConfig {&& ECHO(     public $offline = "0";&& ECHO(     public $offline_message = "This site is down for maintenance. Please check back again soon.";&& ECHO(     public $sitename = "%SITENAME%";&& ECHO(     public $editor = "tinymce";&& ECHO(     public $list_limit = "20";&& ECHO(     public $debug = "0";&& ECHO(     public $debug_lang = "0";&& ECHO(     public $dbtype = "mysql";&& ECHO(     public $host = "localhost";&& ECHO(     public $user = "root";&& ECHO(     public $password = "";&& ECHO(     public $db = "%SITE%";&& ECHO(     public $dbprefix = "jos_";&& ECHO(     public $live_site = "";&& ECHO(     public $secret = "VwsRXPuVWTntR4wg";&& ECHO(     public $gzip = "0";&& ECHO(     public $error_reporting = "-1";&& ECHO(     public $helpurl = "http://help.joomla.org/proxy/index.php?option=com_help&amp;keyref=Help{major}{minor}:{keyref}";&& ECHO(     public $ftp_host = "127.0.0.1";&& ECHO(     public $ftp_port = "21";&& ECHO(     public $ftp_user = "";&& ECHO(     public $ftp_pass = "";&& ECHO(     public $ftp_root = "";&& ECHO(     public $ftp_enable = "0";&& ECHO(     public $offset = "America/Los_Angeles";&& ECHO(     public $mailer = "mail";&& ECHO(     public $mailfrom = "webmaster@%SITE%";&& ECHO(     public $fromname = "%SITENAME%";&& ECHO(     public $sendmail = "/usr/sbin/sendmail";&& ECHO(     public $smtpauth = "0";&& ECHO(     public $smtpuser = "";&& ECHO(     public $smtppass = "";&& ECHO(     public $smtphost = "localhost";&& ECHO(     public $smtpsecure = "none";&& ECHO(     public $smtpport = "25";&& ECHO(     public $caching = "0";&& ECHO(     public $cache_handler = "file";&& ECHO(     public $cachetime = "15";&& ECHO(     public $MetaDesc = "";&& ECHO(     public $MetaKeys = "";&& ECHO(     public $MetaTitle = "0";&& ECHO(     public $MetaAuthor = "0";&& ECHO(     public $sef = "1";&& ECHO(     public $sef_rewrite = "0";&& ECHO(     public $sef_suffix = "0";&& ECHO(     public $feed_limit = "10";&& ECHO(     public $log_path = "%DOCROOT%/%SITE%/logs";&& ECHO(     public $tmp_path = "%DOCROOT%/%SITE%/tmp";&& ECHO(     public $lifetime = "15";&& ECHO(     public $session_handler = "database";&& ECHO(     public $access = "1";&& ECHO(     public $offset_user = "America/Los_Angeles";&& ECHO(     public $unicodeslugs = "0";&& ECHO }&& ECHO.) > configuration.php
copy htaccess.txt .htaccess > NUL
GOTO SAMPLECONTENT

:SAMPLECONTENT
chdir /d %WWW%\%SITE%
CLS
ECHO.
SET /p SAMPLECONTENT=Do you want sample content installed? (Y/N) 
IF /i %SAMPLECONTENT% == Y (
  ECHO.
  ECHO Including sample content...
  powershell -Command "Get-Content installation\sql\mysql\sample_data.sql | ForEach-Object { $_ -replace '#__', '%PREFIX%_' } | Set-Content jdata.sql"
  copy /b jinstaller.sql+jdata.sql jinstaller.sql > NUL
  del jdata.sql
)
GOTO MYSQL

:MYSQL
CLS
ECHO.
ECHO Please provide configuration details.
ECHO (press ENTER to accept defaults)
SET /p NAME=Your name: 
SET /p USER=Your username:
SET /p EMAIL=Your email address: 
IF "%EMAIL%" == "" SET EMAIL=%DEFAULTEMAIL%
IF "%NAME%" == "" SET NAME=%DEFAULTNAME%
IF "%USER%" == "" SET USER=%DEFAULTUSER%
GOTO CREATEDB

:CREATEDB
CLS
ECHO.
ECHO Creating the database...
chdir /d %XAMPP%\mysql\bin
mysql --host=localhost --user=root --execute="CREATE USER '%SITE%'@'localhost' IDENTIFIED BY 'password';CREATE DATABASE IF NOT EXISTS `%SITE%`;GRANT ALL PRIVILEGES ON `%SITE%`.* TO '%SITE%'@'localhost';"
IF %CHOICE% == GENERIC GOTO HOSTS
IF %CHOICE% == KICKSTART GOTO HOSTS
GOTO IMPORTSQL

:IMPORTSQL
chdir /d %XAMPP%\mysql\bin
mysql --host=localhost --user=root --database=%SITE% --execute="SOURCE %DOCROOT%/%SITE%/jinstaller.sql"
mysql --host=localhost --user=root --database=%SITE% --execute="INSERT INTO %PREFIX%_users (id, name, username, email, password, block, sendEmail, registerDate, lastvisitDate, activation, params) VALUES (5, '%NAME%', '%USER%', '%EMAIL%', 'c6bc538c76f52d7e7fc9e37827f9975c:19ujHiJIBekABNGepBIsWGT7VLpJcEgj', 0, 1, NOW(), NOW(), '', '')"
mysql --host=localhost --user=root --database=%SITE% --execute="INSERT INTO %PREFIX%_user_usergroup_map (user_id, group_id) VALUES (5, 8)"
REM mysql --host=localhost --user=root --database=%SITE% --execute="INSERT INTO %PREFIX%_schemas (`extension_id`, `version_id`) VALUES (700, '2.5.4-2012-03-19');"
GOTO CLEANUP

:CLEANUP
chdir /d %WWW%\%SITE%
ECHO.
ECHO Cleaning up...
del %WWW%\%SITE%\jinstaller.sql
rmdir /s /q installation
ECHO.
GOTO HOSTS

:DELETE
CLS
ECHO.
ECHO.
SET /p CONFIRM=Are you sure you want to delete the site: '%SITE%'? 
IF /i %CONFIRM% == N GOTO EXIT
ECHO.
ECHO Deleting hosts entry for %SITE%...
chdir /d %WINDIR%\system32\drivers\etc
copy hosts hosts.bak > NUL
powershell -Command "$s = Select-String -pattern '^127\.0\.0\.1\swww\.%SITE%\.local$' -path 'hosts'; $n = $s.LineNumber; if ($n -lt 0) { exit; } Get-Content hosts | Foreach {$i=1}{if ($i++ -ne $n) {$_}} | Set-Content -Encoding UTF8 hosts.new"
del hosts
ren hosts.new hosts
powershell -Command "$s = Select-String -pattern '^127\.0\.0\.1\s%SITE%\.local$' -path 'hosts'; $n = $s.LineNumber; if ($n -lt 0) { exit; } Get-Content hosts | Foreach {$i=1}{if ($i++ -ne $n) {$_}} | Set-Content -Encoding UTF8 hosts.new"
del hosts
ren hosts.new hosts
powershell -Command "$s = Select-String -pattern '^127\.0\.0\.1\s%SITE%$' -path 'hosts'; $n = $s.LineNumber; if ($n -lt 0) { exit; } Get-Content hosts | Foreach {$i=1}{if ($i++ -ne $n) {$_}} | Set-Content -Encoding UTF8 hosts.new"
del hosts
ren hosts.new hosts
ECHO.
ECHO Deleting entry in vhosts configuration...
chdir /d %XAMPP%\apache\conf\extra
copy httpd-vhosts.conf httpd-vhosts.bak > NUL
powershell -Command "$s = Select-String -pattern '\s%SITE%\.local' -path 'httpd-vhosts.conf'; $n = $s.LineNumber - 5; if ($n -lt 0) { exit; } $o = $n + 9; Get-Content httpd-vhosts.conf | Foreach {$i=1}{if ($i++ -lt $n -or $i -gt $o) {$_}} | Set-Content -Encoding UTF8 httpd-vhosts.new"
IF EXIST httpd-vhosts.new (
	del httpd-vhosts.conf
	ren httpd-vhosts.new httpd-vhosts.conf
)
ECHO.
ECHO Deleting database...
chdir /d %XAMPP%\mysql\bin
mysql --host=localhost --user=root --execute="DROP DATABASE IF EXISTS %SITE%;DROP USER IF EXISTS '%SITE%'@'localhost;"
ECHO.
ECHO Deleting files...
chdir /d %WWW%
rmdir /s /q %SITE% > NUL
GOTO RESTARTAPACHE

:HOSTS
ECHO.
ECHO Creating entry in hosts file...
chdir /d %WINDIR%\system32\drivers\etc
copy hosts hosts.bak > NUL
(ECHO 127.0.0.1 %SITE%&& ECHO 127.0.0.1 %SITE%.local&& ECHO 127.0.0.1 www.%SITE%.local) > temp
copy /b hosts+temp hosts > NUL
del temp
GOTO VHOSTS

:VHOSTS
ECHO.
ECHO Creating entry in vhosts configuration...
chdir /d %XAMPP%\apache\conf\extra
copy httpd-vhosts.conf httpd-vhosts.bak > NUL
(ECHO ^<VirtualHost *:80^>&& ECHO(    ServerAdmin postmaster@%SITE%&& ECHO(    DocumentRoot "%DOCROOT%/%SITE%"&& ECHO(    ServerName %SITE%&& ECHO(    ServerAlias %SITE%.local www.%SITE%.local&& ECHO(    ErrorLog "logs/%SITE%-error.log"&& ECHO(    CustomLog "logs/%SITE%-access.log" combined&& ECHO ^</VirtualHost^>&& ECHO.) > temp
copy /b httpd-vhosts.conf+temp httpd-vhosts.conf > NUL
del temp
GOTO RESTARTAPACHE

:RESTARTAPACHE
REM This (the following GOTO) should get updated with each Apache version.
GOTO APACHE24

:APACHE24
sc query apache2.4 > NUL
IF ERRORLEVEL 1060 GOTO APACHE22
ECHO.
ECHO Restarting Apache 2.4...
net stop Apache2.4
net start Apache2.4
GOTO START

:APACHE22
sc query apache2.2 > NUL
IF ERRORLEVEL 1060 GOTO APACHEERROR
ECHO.
ECHO Restarting Apache 2.2...
net stop Apache2.2
net start Apache2.2
GOTO START

:APACHEERROR
ECHO.
ECHO The Apache service seems to be missing.
GOTO ERROR

:START
IF %CHOICE% == GENERIC (
	START %WWW%\%SITE%
	EXPLORER "http://%SITE%.local"
	GOTO EXIT
)
IF %CHOICE% == JOOMLA (
	EXPLORER "http://%SITE%.local/administrator/index.php"
	GOTO EXIT
)
IF %CHOICE% == KICKSTART (
	EXPLORER "http://%SITE%.local/kickstart.php"
	GOTO EXIT
)
IF %CHOICE% == ROCKETLAUNCHER (
	EXPLORER "http://%SITE%.local"
	GOTO EXIT
)
GOTO EXIT

:ERROR
ECHO.
ECHO FAIL.
ECHO.
pause

:EXIT
chdir /d %DIR%
