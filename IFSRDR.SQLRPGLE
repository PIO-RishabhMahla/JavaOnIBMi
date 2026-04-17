**FREE
// ============================================================
// Program  : IFSRDR
// Purpose  : IFS reader service program exposes procedures
//            to open, read lines from, close, and check
//            existence of IFS stream files using C runtime
//            APIs bound via QC2LE
// Author   : Developer
// Date     : 2026-04-15
// Changes  :
//   2026-04-15  Developer  INC#0001  Initial creation
// ============================================================

Ctl-Opt Option(*SrcStmt : *NoDebugIO)
        BndDir('QC2LE')
        NoMain
        ExtBinInt(*Yes)
        AlwNull(*UsrCtl)
        Debug(*Yes);


Dcl-Pr COpen  Pointer  ExtProc('fopen');
path    Pointer  Value Options(*String);
mode    Pointer  Value Options(*String);
End-Pr;

Dcl-Pr CFgets Pointer  ExtProc('fgets');
buffer  Pointer  Value;
size    Int(10)  Value;
stream  Pointer  Value;
End-Pr;

Dcl-Pr CFclose Int(10) ExtProc('fclose');
stream  Pointer  Value;
End-Pr;

Dcl-Pr CFputs Int(10) ExtProc('fputs');
buffer  Pointer  Value Options(*String);
stream  Pointer  Value;
End-Pr;

Dcl-Pr CStat  Int(10)  ExtProc('stat');
path    Pointer  Value Options(*String);
statDs  Pointer  Value;
End-Pr;

Dcl-S fileHandle Pointer Inz(*Null);

//COPY QRPGLESRC,APPPROTS

// ============================================================
// Procedure : OpenIfsFile
// Purpose   : Open an IFS stream file for reading
// Parameters: filePath absolute IFS path
// Returns   : *On if file opened successfully, *Off otherwise
// ============================================================
Dcl-Proc OpenIfsFile Export;
Dcl-Pi *N Ind;
    filePath Varchar(512) Const;
End-Pi;

fileHandle = COpen(%Trim(filePath) : 'r');

If fileHandle = *Null;
    Return *Off;
EndIf;

Return *On;

End-Proc;


// ============================================================
// Procedure : ReadIfsLine
// Purpose   : Read a single line from a previously opened IFS
//             file; wraps fopen+fgets+fclose for single-shot use
// Parameters: filePath   absolute IFS path
//             lineOut    receives the line content (trimmed)
// Returns   : *On if a line was read, *Off on EOF or error
// ============================================================
Dcl-Proc ReadIfsLine Export;
Dcl-Pi *N Ind;
    filePath Varchar(512) Const;
    lineOut  Varchar(1024);
End-Pi;

Dcl-S localHandle Pointer  Inz(*Null);
Dcl-S rawBuffer   Char(1025) Inz(*Blanks);
Dcl-S fetchResult Pointer  Inz(*Null);

localHandle = COpen(%Trim(filePath) : 'r');
If localHandle = *Null;
    Return *Off;
EndIf;

fetchResult = CFgets(%Addr(rawBuffer) : 1025 : localHandle);

CFclose(localHandle);

If fetchResult = *Null;
    Return *Off;
EndIf;

// Strip trailing newline/CR before returning
lineOut = %TrimR(%Str(%Addr(rawBuffer)));

Return *On;

End-Proc;


// ============================================================
// Procedure : ReadAllLines
// Purpose   : Read all lines from an IFS file into a pre-opened
//             handle; caller must call OpenIfsFile first and
//             CloseIfsFile when done
// Parameters: lineOut receives each line in turn
// Returns   : *On while lines remain, *Off at EOF or error
// ============================================================
Dcl-Proc ReadAllLines Export;
Dcl-Pi *N Ind;
    lineOut Varchar(1024);
End-Pi;

Dcl-S rawBuffer   Char(1025) Inz(*Blanks);
Dcl-S fetchResult Pointer  Inz(*Null);

If fileHandle = *Null;
    Return *Off;
EndIf;

rawBuffer   = *Blanks;
fetchResult = CFgets(%Addr(rawBuffer) : 1025 : fileHandle);

If fetchResult = *Null;
    Return *Off;
EndIf;

lineOut = %TrimR(%Str(%Addr(rawBuffer)));

Return *On;

End-Proc;


// ============================================================
// Procedure : WriteIfsLine
// Purpose   : Append a single text line to an IFS stream file,
//             creating the file if it does not exist
// Parameters: filePath absolute IFS path
//             lineIn content to write (newline appended)
// Returns   : *On if written successfully, *Off on error
// ============================================================
Dcl-Proc WriteIfsLine Export;
Dcl-Pi *N Ind;
    filePath Varchar(512) Const;
    lineIn   Varchar(1024) Const;
End-Pi;

Dcl-S writeHandle Pointer Inz(*Null);
Dcl-S writeBuffer Char(1026);
Dcl-S writeResult Int(10) Inz(0);

writeHandle = COpen(%Trim(filePath) : 'a');
If writeHandle = *Null;
    Return *Off;
EndIf;

writeBuffer = %Trim(lineIn) + X'0A';  // append Unix newline

// Use fputs to write the buffer to the file
writeResult = CFputs(%Trim(writeBuffer) : writeHandle);

CFclose(writeHandle);

Return (writeResult >= 0);

End-Proc;


// ============================================================
// Procedure : CloseIfsFile
// Purpose   : Close the module-level file handle opened by
//             OpenIfsFile
// Parameters: None
// Returns   : None
// ============================================================
Dcl-Proc CloseIfsFile Export;
Dcl-Pi *N;
End-Pi;

If fileHandle <> *Null;
    CFclose(fileHandle);
    fileHandle = *Null;
EndIf;

Return;

End-Proc;


// ============================================================
// Procedure : IfsFileExists
// Purpose   : Check whether an IFS path exists using the C
//             stat() system call; does not open the file
// Parameters: filePath absolute IFS path to test
// Returns   : *On if file exists, *Off if not found or error
// ============================================================
Dcl-Proc IfsFileExists Export;
Dcl-Pi *N Ind;
    filePath Varchar(512) Const;
End-Pi;

// stat() requires a 128-byte output buffer (struct stat)
Dcl-Ds StatBuf Len(128);
  st_dev      Int(10);
  st_ino      Int(10);
  st_mode     Int(10);
  st_nlink    Int(10);
  st_uid      Int(10);
  st_gid      Int(10);
  st_rdev     Int(10);
  st_size     Int(10);
  st_atime    Int(10);
  st_mtime    Int(10);
  st_ctime    Int(10);
  st_blksize  Int(10);
  st_blocks   Int(10);
End-Ds;

Dcl-S rc Int(10) Inz(0);

rc = CStat(%Trim(filePath) : %Addr(StatBuf));

Return (rc = 0);

End-Proc;
