//IBMUSERD  JOB ACCT#,MSGCLASS=H,MSGLEVEL=(1,1)
//*
//*------------------------------------------------------
//* BIND DBRM 
//*  - Run bind package after each Build of EPSCMORT
//*  - Run bind plan once but its ok as is
//*------------------------------------------------------
//JOBLIB  DD  DISP=SHR,DSN=DB2V13.SDSNLOAD
//STEP1    EXEC PGM=IKJEFT01,DYNAMNBR=20
//DBRMLIB  DD  DSN=DBB.POC.DBRM,DISP=SHR
//SYSPRINT DD  SYSOUT=*
//SYSTSPRT DD  SYSOUT=*
//SYSTSIN  DD  *
 DSN SYSTEM(DBD1) 
 BIND PACKAGE(EPS) MEMBER(EPSCMORT) OWNER(IBMUSER) QUAL(SYS1) ACTION(REPLACE)  
 
 BIND PLAN(EPSPLAN)  PKLIST(EPS.*) ACTION(ADD) +                
      CURRENTDATA(NO) ISO(CS) ENCODING(EBCDIC) SQLRULES(DB2)       
END 