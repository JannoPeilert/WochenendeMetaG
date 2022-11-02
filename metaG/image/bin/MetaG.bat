@echo off
set DIR="%~dp0"
set JAVA_EXEC="%DIR:"=%\java"



pushd %DIR% & %JAVA_EXEC% %CDS_JVM_OPTS%  -p "%~dp0/../app" -m eu.kwrhannover.jufo.metag/eu.kwrhannover.jufo.metag.MetaGApplication  %* & popd
