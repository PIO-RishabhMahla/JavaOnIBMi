**FREE
// ============================================================
// Program  : MAINJOB
// Purpose  : Orchestrator  reads IFS text file, loads CSV to
//            DB2, calls Java report generator via QShell,
//            confirms output on IFS
// Author   : Developer
// Date     : 2026-04-15
// Changes  :
//   2026-04-15  Developer  INC#0001  Initial creation
// ============================================================

// --- Control Options ---
Ctl-Opt Option(*SrcStmt : *NoDebugIO)
        DftActGrp(*No)
        ActGrp(*Caller)
        BndDir('QC2LE' : 'APPBND')
        Main(MainProc)
        ExtBinInt(*Yes)
        Date(*ISO)
        DateFmt(*ISO)
        TimFmt(*ISO)
        AlwNull(*UsrCtl)
        Debug(*Yes);

// --- Prototypes (cross-program) ---
/COPY QCPYSRC,APPPROTS

// ============================================================
// Procedure : MainProc
// Purpose   : Top-level orchestration of all IFS + DB2 + Java
//             operations in sequence
// Parameters: None
// Returns   : None
// ============================================================
Dcl-Proc MainProc;
  Dcl-Pi *N;
  End-Pi;

  // --- Constants ---
  Dcl-C IFS_INPUT_TXT  '/appdata/input/employees.txt';
  Dcl-C IFS_INPUT_CSV  '/appdata/input/employees.csv';
  Dcl-C IFS_OUTPUT_DIR '/appdata/output/';
  Dcl-C JAVA_CLASS     'com.example.ibmi.ReportGenerator';
  Dcl-C JAVA_CLASSPATH '/appdata/java/reportgen.jar:/QIBM/ProdData/OS400/jt400/lib/jt400.jar';
  Dcl-C JAVA_ARGS      '/appdata/output/report';

  // --- Standalone Variables ---
  Dcl-S lineBuffer  Varchar(1024);
  Dcl-S lineCount   Int(10)  Inz(0);
  Dcl-S rowsLoaded  Int(10)  Inz(0);
  Dcl-S javaRc      Int(10)  Inz(0);
  Dcl-S successFlag Ind      Inz(*Off);

  // --------------------------------------------------------
  // Step 1  Read IFS text file and echo first line to joblog
  // Demonstrates basic IFS read via C runtime APIs
  // --------------------------------------------------------
  successFlag = ReadIfsLine(IFS_INPUT_TXT : lineBuffer);
  If Not successFlag;
    LogError(0 : '     ' : 'MainProc : ReadIfsLine failed for ' + IFS_INPUT_TXT);
    *InLR = *On;
    Return;
  EndIf;

  // lineBuffer holds first line of employees.txt  available for downstream use
  lineCount += 1;

  // --------------------------------------------------------
  // Step 2  Load CSV file into DB2 staging table CSVSTAGE
  // --------------------------------------------------------
  successFlag = LoadCsvToDb2(IFS_INPUT_CSV : rowsLoaded);
  If Not successFlag;
    LogError(0 : '     ' : 'MainProc : LoadCsvToDb2 failed');
    *InLR = *On;
    Return;
  EndIf;

  // --------------------------------------------------------
  // Step 3  Call Java report generator via QShell / PASE
  //          Java reads DB2 and writes report.csv + report.pdf
  // --------------------------------------------------------
  successFlag = CallJavaProgram(JAVA_CLASSPATH : JAVA_CLASS : JAVA_ARGS : javaRc);
  If Not successFlag Or javaRc <> 0;
    LogError(javaRc : '     ' : 'MainProc : CallJavaProgram failed rc=' + %Char(javaRc));
    *InLR = *On;
    Return;
  EndIf;

  // --------------------------------------------------------
  // Step 4  Confirm output files exist on IFS
  // --------------------------------------------------------
  successFlag = IfsFileExists(IFS_OUTPUT_DIR + 'report.csv');
  If Not successFlag;
    LogError(0 : '     ' : 'MainProc : report.csv not found after Java run');
    *InLR = *On;
    Return;
  EndIf;

  successFlag = IfsFileExists(IFS_OUTPUT_DIR + 'report.pdf');
  If Not successFlag;
    LogError(0 : '     ' : 'MainProc : report.pdf not found after Java run');
    *InLR = *On;
    Return;
  EndIf;

  *InLR = *On;
  Return;

End-Proc;
