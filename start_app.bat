@echo off
cd /d "C:\Users\kk188\Downloads\BorrowAThing_R"

:: Launch browser after 3 seconds in the background
start "" timeout /t 3 /nobreak >nul && start http://127.0.0.1:8000

:: Run R script directly
"Rscript.exe" run.R
pause