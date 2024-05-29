//IBMUSERD  JOB ACCT#,MSGCLASS=H,MSGLEVEL=(1,1)
//*
//* njl - Define the mortgage app to CICS  - run once
//* Compatible with CICS61 of WaaS Stock image ver 3.1  
//*
//TRN  EXEC PGM=DFHCSDUP,REGION=0M,
//          PARM='CSD(READWRITE),PAGESIZE(60),NOCOMPAT'
//STEPLIB  DD DISP=SHR,DSN=CICSTS61.CICS.SDFHLOAD
//DFHCSD   DD DISP=SHR,DSN=CICSTS61.DFHCSD
//SYSPRINT DD SYSOUT=*
//SYSIN    DD * 
DELETE GROUP(EPSMTM)       
                                                                    
DEFINE DB2CONN(DBD1)    GROUP(EPSMTM) PLAN(EPSPLAN) DB2ID(DBD1)        
      CONNECTERROR(SQLCODE) MSGQUEUE1(CSMT)                         
      COMAUTHID(IBMUSER)    AUTHID(IBMUSER)                        
                                                                    
DEFINE DB2ENTRY(EPSE)   GROUP(EPSMTM)                               
      ACCOUNTREC(NONE) AUTHTYPE(USERID) DROLLBACK(YES) PLAN(EPSPLAN)   
      PRIORITY(HIGH) PROTECTNUM(0) THREADLIMIT(10) THREADWAIT(YES)              
                                                                    
DEFINE TRANSACTION(EPSP) GROUP(EPSMTM) PROGRAM(EPSCMORT)            

DEFINE MAPSET(EPSMORT)   GROUP(EPSMTM)                              
DEFINE PROGRAM(EPSCMORT) GROUP(EPSMTM) LANGUAGE(COBOL)              
DEFINE PROGRAM(EPSCSMRT) GROUP(EPSMTM) LANGUAGE(COBOL)              
DEFINE PROGRAM(EPSMPMT)  GROUP(EPSMTM) LANGUAGE(COBOL)              
DEFINE PROGRAM(EPSMLIST) GROUP(EPSMTM) LANGUAGE(COBOL)              

ADD GROUP(EPSMTM) LIST(STDLIST) 


/*

