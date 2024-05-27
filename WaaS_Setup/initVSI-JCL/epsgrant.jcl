//IBMUSERD  JOB ACCT#,MSGCLASS=H,MSGLEVEL=(1,1)
//*
//*------------------------------------------------------
//* njl - 
//* Grant DB2 access tot the EPS App 
//*   - Also grant access to the Plan 
//*   - This only needs to be run once 
//*   - Needs dsntep2 util see dsntep2.jcl 
//*------------------------------------------------------
//JOBLIB  DD  DISP=SHR,DSN=DB2V13.SDSNLOAD
//* 
//GRANT EXEC PGM=IKJEFT01,REGION=0M
//SYSPRINT DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
 DSN SYSTEM(DBD1)
 RUN PROGRAM(DSNTEP2) PLAN(DSNTEP22) LIB('DBD1.RUNLIB.LOAD')
//SYSIN    DD *
 SET CURRENT SQLID = 'IBMUSER';
 GRANT EXECUTE ON PLAN EPSPLAN TO PUBLIC; 
/*
//* 