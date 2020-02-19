@ECHO OFF
@rem **************************************************************************
@rem shared.cmd
@rem
@rem Copyright (c) 2020, Oracle Corporation and/or its affiliates.
@rem Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
@rem
@rem     NAME
@rem       shared.cmd - shared script for use with WebLogic Deploy Tooling.
@rem
@rem     DESCRIPTION
@rem       This script contains shared functions for use with WDT scripts.
@rem

CALL %*

GOTO :ENDFUNCTIONS

:javaSetup
    @rem Make sure that the JAVA_HOME environment variable is set to point to a
    @rem JDK with the specified level or higher (and that it isn't OpenJDK).

    SET MIN_JDK_VERSION=%1

    IF NOT DEFINED JAVA_HOME (
      ECHO Please set the JAVA_HOME environment variable to point to a Java 8 installation >&2
      EXIT /B 2
    ) ELSE (
      IF NOT EXIST "%JAVA_HOME%" (
        ECHO Your JAVA_HOME environment variable to points to a non-existent directory: %JAVA_HOME% >&2
        EXIT /B 2
      )
    )
    FOR %%i IN ("%JAVA_HOME%") DO SET JAVA_HOME=%%~fsi
    IF %JAVA_HOME:~-1%==\ SET JAVA_HOME=%JAVA_HOME:~0,-1%

    IF EXIST %JAVA_HOME%\bin\java.exe (
      FOR %%i IN ("%JAVA_HOME%\bin\java.exe") DO SET JAVA_EXE=%%~fsi
    ) ELSE (
      ECHO Java executable does not exist at %JAVA_HOME%\bin\java.exe does not exist >&2
      EXIT /B 2
    )

    FOR /F %%i IN ('%JAVA_EXE% -version 2^>^&1') DO (
      IF "%%i" == "OpenJDK" (
        ECHO JAVA_HOME %JAVA_HOME% contains OpenJDK^, which is not supported >&2
        EXIT /B 2
      )
    )

    FOR /F tokens^=2-5^ delims^=.-_^" %%j IN ('%JAVA_EXE% -fullversion 2^>^&1') DO (
      SET "JVM_FULL_VERSION=%%j.%%k.%%l_%%m"
      SET "JVM_VERSION_PART_ONE=%%j"
      SET "JVM_VERSION_PART_TWO=%%k"
    )

    SET JVM_SUPPORTED=1
    IF %JVM_VERSION_PART_ONE% LEQ 1 (
        IF %JVM_VERSION_PART_TWO% LSS %MIN_JDK_VERSION% (
            SET JVM_SUPPORTED=0
            IF %JVM_VERSION_PART_TWO% LSS 7 (
                ECHO You are using an unsupported JDK version %JVM_FULL_VERSION% >&2
            ) ELSE (
                ECHO JDK version 1.8 or higher is required when using encryption >&2
            )
        )
    )

    IF %JVM_SUPPORTED% NEQ 1 (
      EXIT /B 2
    ) ELSE (
      ECHO JDK version is %JVM_FULL_VERSION%, setting JAVA_VENDOR to Sun...
      SET JAVA_VENDOR=Sun
    )
GOTO :EOF

:loggerSetup
    @REM set up variables for logger configuration. see WLSDeployLoggingConfig.java

    SET LOG_CONFIG_CLASS=oracle.weblogic.deploy.logging.WLSDeployCustomizeLoggingConfig
    SET WLSDEPLOY_LOG_HANDLER=oracle.weblogic.deploy.logging.SummaryHandler

    IF NOT DEFINED WLSDEPLOY_LOG_PROPERTIES (
      SET WLSDEPLOY_LOG_PROPERTIES=%WLSDEPLOY_HOME%\etc\logging.properties
    )
    IF NOT DEFINED WLSDEPLOY_LOG_DIRECTORY (
      SET WLSDEPLOY_LOG_DIRECTORY=%WLSDEPLOY_HOME%\logs
    )
    IF NOT DEFINED WLSDEPLOY_LOG_HANDLERS (
      SET WLSDEPLOY_LOG_HANDLERS=%WLSDEPLOY_LOG_HANDLER%
    )
GOTO :EOF

:jythonSetup
    @REM setup up logger, classpath for Jython-based script

    SET ORACLE_SERVER_DIR=

    IF EXIST "%ORACLE_HOME%\wlserver_10.3" (
        SET ORACLE_SERVER_DIR=%ORACLE_HOME%\wlserver_10.3"
    ) ELSE IF EXIST "%ORACLE_HOME%\wlserver_12.1" (
        SET ORACLE_SERVER_DIR=%ORACLE_HOME%\wlserver_12.1"
    ) ELSE (
        SET ORACLE_SERVER_DIR=%ORACLE_HOME%\wlserver
    )

    CALL :loggerSetup
    SET "JAVA_PROPERTIES=-Djava.util.logging.config.class=%LOG_CONFIG_CLASS%"
    SET "JAVA_PROPERTIES=%JAVA_PROPERTIES% -Dpython.cachedir.skip=true"
    SET "JAVA_PROPERTIES=%JAVA_PROPERTIES% -Dpython.path=%ORACLE_SERVER_DIR%/common/wlst/modules/jython-modules.jar/Lib"
    SET "JAVA_PROPERTIES=%JAVA_PROPERTIES% -Dpython.console="
    SET "JAVA_PROPERTIES=%JAVA_PROPERTIES% %WLSDEPLOY_PROPERTIES%"

    SET CLASSPATH=%WLSDEPLOY_HOME%\lib\weblogic-deploy-core.jar
    SET CLASSPATH=%CLASSPATH%;%ORACLE_SERVER_DIR%\server\lib\weblogic.jar
GOTO :EOF

:checkExitCode
    @REM print a message for the exit code passed in, and set ERRORLEVEL to 100 if usage should be printed.
    @REM assume that SCRIPT_NAME environment variable was set by the caller.

    SET RETURN_CODE=%1

    IF "%RETURN_CODE%" == "103" (
      ECHO.
      ECHO %SCRIPT_NAME% completed successfully but the domain requires a restart for the changes to take effect ^(exit code = %RETURN_CODE%^)
      EXIT /B 0
    )
    IF "%RETURN_CODE%" == "102" (
      ECHO.
      ECHO %SCRIPT_NAME% completed successfully but the effected servers require a restart ^(exit code = %RETURN_CODE%^)
      EXIT /B 0
    )
    IF "%RETURN_CODE%" == "101" (
      ECHO.
      ECHO %SCRIPT_NAME% was unable to complete due to configuration changes that require a domain restart.  Please restart the domain and re-invoke the %SCRIPT_NAME% script with the same arguments ^(exit code = %RETURN_CODE%^)
      EXIT /B 0
    )
    IF "%RETURN_CODE%" == "100" (
      EXIT /B 100
    )
    IF "%RETURN_CODE%" == "99" (
      EXIT /B 100
    )
    IF "%RETURN_CODE%" == "98" (
      ECHO.
      ECHO %SCRIPT_NAME% failed due to a parameter validation error >&2
      EXIT /B 0
    )
    IF "%RETURN_CODE%" == "2" (
      ECHO.
      ECHO %SCRIPT_NAME% failed ^(exit code = %RETURN_CODE%^)
      EXIT /B 0
    )
    IF "%RETURN_CODE%" == "1" (
      ECHO.
      ECHO %SCRIPT_NAME% completed but with some issues ^(exit code = %RETURN_CODE%^) >&2
      EXIT /B 0
    )
    IF "%RETURN_CODE%" == "0" (
      ECHO.
      ECHO %SCRIPT_NAME% completed successfully ^(exit code = %RETURN_CODE%^)
      EXIT /B 0
    )
    @REM Unexpected return code so just print the message and exit...
    ECHO.
    ECHO %SCRIPT_NAME% failed ^(exit code = %RETURN_CODE%^) >&2
GOTO :EOF

:ENDFUNCTIONS
