@echo off
REM filepath: run.bat

REM Get Intel oneAPI path from command line or use default
IF "%~1"=="" (
    SET ONEAPI_PATH="C:/Program Files (x86)/Intel/oneAPI/setvars.bat"
) ELSE (
    SET ONEAPI_PATH=%~1
)

REM Initialize Intel oneAPI environment
echo Initializing Intel oneAPI environment from %ONEAPI_PATH%...
call %ONEAPI_PATH%

REM Navigate to build_windows directory and build the project
echo Building project in build_windows directory...
if not exist build_windows mkdir build_windows
cd build_windows
cmake ..
if %ERRORLEVEL% NEQ 0 (
    exit /b errorcode
)

cmake --build . --config Release
if %ERRORLEVEL% NEQ 0 (
    cd ..
    echo Build completely or partially failed
    exit /b errorcode
)

REM Navigate back to root directory
cd ..

REM Add OpenBLAS to path
echo Adding OpenBLAS to PATH...
set PATH=%CD%\cmake\openblas\bin;%PATH%

REM Run the MKL version
echo Waiting 5 seconds before running MKL version...
timeout /t 5 /nobreak
echo Running MKL version...
target\main_mkl_windows.exe

REM Run the OpenBLAS version
echo Waiting 5 seconds before running OpenBLAS version...
timeout /t 5 /nobreak
echo Running OpenBLAS version...
target\main_openblas_windows.exe

echo Done!

pause
