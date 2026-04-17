      Dcl-Pr OpenIfsFile   Ind;
        filePath Varchar(512) Const;
      End-Pr;

      Dcl-Pr ReadIfsLine   Ind;
        filePath Varchar(512)  Const;
        lineOut  Varchar(1024);
      End-Pr;

      Dcl-Pr ReadAllLines  Ind;
        lineOut Varchar(1024);
      End-Pr;

      Dcl-Pr WriteIfsLine  Ind;
        filePath Varchar(512)  Const;
        lineIn   Varchar(1024) Const;
      End-Pr;

      Dcl-Pr CloseIfsFile;
      End-Pr;

      Dcl-Pr IfsFileExists Ind;
        filePath Varchar(512) Const;
      End-Pr;

      Dcl-Pr LoadCsvToDb2  Ind;
        csvPath    Varchar(512) Const;
        rowsLoaded Int(10);
      End-Pr;

