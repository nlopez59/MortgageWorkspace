## A beginners guide to Cobol CICS/DB2 application development        
This was written for those new to zOS application development.  Its a very very basic walkthrough of the IBM sample 'MortgageApplication' (MortApp) included in this repo. This outlines how it works, and the various CICS and DB2 system level configurations it uses.

As a aid, links to external material are included for further learning. 

#### zOS Development - Foundational concepts
Mainframe programs are written mostly in Cobol. Others can be in Assembler, PLI and other programming languages. Applications are composed of one or more programs and be a mix of languages. Programs are designed to meet some specific business feature/solution. Applications and the data they process can be either interactive (online) or batch. 

**Interactive** applications use the IBM product [CICS](https://www.ibm.com/docs/en/zos-basic-skills?topic=zos-introduction-cics) or [IMS](https://www.ibm.com/docs/en/integration-bus/10.0?topic=ims-information-management-system).
  - They are designed to interact with users to gather and send data over a network connected text-based 3270 terminal. 
  - Modernized CICS applications substitute 3270 screens with a web front-end and other methods to access CICS. 
 
**Batch** applications run using [Job Control Language - JCL](https://www.ibm.com/docs/en/zos-basic-skills?topic=jobs-what-is-batch-processing).  
 - Batch applications use JCL to process large amounts of data in 'batches' without user interaction. 
 - A JCL job is a sequence of step(s) that execute application programs or IBM utilities like Sort, DB2 bind...
 - Each step includes one or more Data Definitions (DDs) that allocate DataSets by Name (DSN). They are the input/output files processed by the program. 
 - Batch applications can also access data in DB2 tables, MQ Queues and a variety of other methods. 
 - Jobs are submitted to the [Job Entry Subsystem - JES](https://www.ibm.com/docs/en/zos-basic-skills?topic=jobs-what-is-batch-processing) which allocates files and executes the program of each step. 
<br /> 
   This example JCL step executes the IBM utility program IEFBR14 and allocates a DSN with the DDname of DD1. The 'SYSOUT=*' DDs are special files used by JES to display output/logs produced by the program.
 <img src="../images/jcl.png" width="500">


## Anatomy of a CICS Application  
A basic [CICS application](https://www.ibm.com/docs/en/cics-ts/5.6?topic=fundamentals-cics-applications) has several parts.  We will examine the Mortgage Application to understand how to build, configure and run it in under a WaaS Stock image using CICS/DB2. 

**The Code**
- [cobol/eps**c**mort.cbl](../MortgageApplication/cobol/epscmort.cbl#L152) is the main program. It uses the "EXEC CICS" Cobol API to display a screen defined in program **bms/epsmort**.   
<br />   

- [bms/epsmort.bms](../MortgageApplication/bms/epsmort.bms) is a 3270 [BMS](https://www.ibm.com/docs/en/cics-ts/5.6?topic=programs-basic-mapping-support) screen definition program written in assembler language.  
  - The compiler transforms this source file into 2 artifacts; a [symbolic copybook 'EPSMORT' and a physical executable load module](https://www.ibm.com/docs/en/cics-ts/6.1?topic=map-physical-symbolic-sets). 
  

  - The symbolic copybook is saved in a [Partitioned Dataset - PDS](https://www.ibm.com/docs/en/zos-basic-skills?topic=set-types-data-sets) allocated with the dbb-zappbuild "HLQ' argument. 
  - This PDS is then used as the SYSLIB in subsequent DBB builds. 
  - SYSLIB is the DDname used to allocate the copybook PDS as input to the compiler.  
  - A program accesses the EPSMORT symbolic copybook with the ['COPY   EPSMORT'](../MortgageApplication/cobol/epscmort.cbl#L55) Cobol statement. This causes the compiler to add the copybook to the program as shown this sample listing of the EPSMORT compile.
    <img src="../images/epsmort.png" width="700">
  
    ```A special note on DBB builds is that BMS copybooks are not stored in the source repo like other copybooks.  Instead they are stored in the PDS created during the DBB build of the BMS program. ```
    <br />   

- [cobol/epscsmrt.cbl](../MortgageApplication/cobol/epscsmrt.cbl) is a program that is called by EPSCMORT to lculate a mortgage. 
  - The data is returned using a [COMMAREA](https://www.ibm.com/docs/en/cics-ts/6.1?topic=affinity-commarea) copybook.  
  - In Cobol, a COMMAREA is a data structure used to exchange data between programs. They are normally defined and shared as copybooks.  
<br />

- [copybook/epsmtcom.cpy](../MortgageApplication/copybook/epsmtcom.cpy) is the COMMAREA used between EPSCMORT and EPSCSMRT programs. It includes 2 other copybooks. One for  input and another output data structures.
<br />   


## The infrastructure
The diagram below illustrates the different layers of a mainframe application.  zOS, the operating system is at the bottom and supervises applications and subsystems (middleware) and the hardware resources they use (not shown).   Above zOS are the online and batch subsystems.  Others, like DB2, are common services used by both online and batch applications. The top layer represents applications and how they access subsystem services through an API layer. 
<img src="../images/zarch.png" width="700">

Let's examine how the Cobol source code ['EXEC CICS SEND MAP('EPMENU') MAPSET('EPSMORT') ...'](../MortgageApplication/cobol/epscmort.cbl#90-95) used in EPSCMORT is transformed into a CICS API:

- At compile time, this 'EXEC' is translated into a 'Send Map' CICS API to call the BMS program EPSMORT.   
- The API load module is defined as a SYSLIB PDS in dbb-zappbuild's cobol.groovy and 'build-conf/dataset.properties'.
  
- At link-edit time, he API is [statically ](https://www.ibm.com/docs/nl/cobol-zos/6.3?topic=program-examples-static-dynamic-call-statements) linked to EPSCMORT to create a single load module.    
  
- At runtime, when EPSCMORT calls the 'Send Map' API, CICS loads and executes the EPSMORT MAPSET to display its 3270 map (map and screen are the same thing).  

``` Side Note: A load module is another name for an executable program. Or the output artifact of the link-edit (binder) step of a build. They also called API, stubs, or objects. ```

The generic diagram below shows the compile and link of program 'PROGA' which includes a static link to program 'PROGB' 
<img src="../images/build1.png" width="600">


### CICS Application Definitions
Once the MortApp programs are built, they need to be defined to CICS.  This section outlines the Jobs used for those definitions.

- Transactions are CICS terminal commands that start applications or utilities. 
  - [EPSP](./initVSI-JCL/dfhcsdup.jcl#L22) is the main MortApp **Transaction ID** (tranid). All CICS applications must have at least one tranid. 
  - When this tranid is entered on a CICS screen, CICS starts program EPSCMORT. 
  - The transaction also defines what group its in. A CICS group is a set resources that are common to an application.  In this case, EPSMTM is the group name. 
<br />   
- Transactions and all other CICS resources are defined using the IBM batch utility [DFHCSDUP](https://www.ibm.com/docs/en/cics-ts/6.1?topic=resources-defining-dfhcsdup). Or they can be defined with the CICS tranid CEMT ([here is a list of other useful CICS commands](https://www.tutorialspoint.com/cics/cics_transactions.htm)).  In the example JCL you will see lines (control cards) that define:
  - [DB2CONN](https://www.ibm.com/docs/en/cics-ts/6.1?topic=sources-defining-cics-db2-connection) - defines the DB2 connection to the DB2 subsystem 'DBD1'. It also defines the default DB2 'EPSPLAN' for this group (see DB2 definitions below). 
  - [DB2ENTRY](https://www.ibm.com/docs/en/cics-ts/6.1?topic=sources-defining-cics-db2-connection) - defines default DB2 properties  for all transactions in the group. 
  - MAPSET  - defines the physical BMS load module.
  - PROGRAM - defines the individual programs that make up MortApp. 
 
- Installing the MortApp in CICS  
  - In CICS "install" refers to making a resource or group of resources known to CICS so that they can be used during runtime. 
  - Run an install once, from a CICS terminal with the cmd ```'CEDA INS GROUP(EPSMTM)'```


### CICS System Layer
Application teams focus on the various parts of their application and work the CICS Admins to design the resources and definitions needed to run their code. 

CICS Admins also configure system-wide settings used across all applications.  The list of things they do is extensive.  But for our example, there are 2 key components needed to make MortApp run in a Stock WaaS image; the Started Task and the SIP. 

**The CICS Started Task**
In simple terms, CICS runs like a batch job under JES.  The main difference is that its a long running job like a unix daemon task.  This type of job is called a 'Started Task' (STC).  

The CICS STC in WaaS 3.1
<img src="../images/cicsstc.png" width="500">



Application load modules are added to a PDS defined in CICS's STC JCL under the DDname [DFH**RPL**](../WaaS_Setup/initVSI-JCL/cicsts61-mod.jcl#L69).  That DDname (RPL for short) is an input dataset to the program [DFHSIP](../WaaS_Setup/initVSI-JCL/cicsts61-mod.jcl#L38) which is CICS. 

When a user enters the transaction EPSP, CICS checks the transaction's resource definition created with DFHCSDUP to find the program name EPSCMORT. CICS loads it from the RPL PDS and starts it. 

For performance reasons, CICS caches loaded programs in memory.  When the program is changed, a CICS Newcopy command is used to refresh the cache.  A newcopy is executed using  the CICS cmd ```'CEMT SET PROG(EPSCMORT) NEWCOPY'```


**The CICS [SIP](https://www.ibm.com/docs/en/cics-ts/5.6?topic=areas-sip-system-initialization-program)**
  The CICS 'System Initialization Program' file or SIP is the main configure file.   In a WaaS stock image it is updated to enable the DB2Conn [DB2CONN](../WaaS_Setup/initVSI-JCL/dfh$sip1#L7) feature.



### DB2 Application Definitions
As illustrated below, programs are defined to DB2 using a [Plan](https://www.ibm.com/docs/ru/db2-for-zos/12?topic=recovery-packages-application-plans).  Plans are collections of DB2 packages. A package represents the DB2 resources used by a program.  

When a DB2 program is compiled, a DB2 DBRM artifact is created. The DBRM is then bound to DB2 to update its resource requirements before it can run.  
<img src="../images/plan.png" alt="DB2 Plans and packages" width="500">
  
<br />   

- [epsbind.jcl](../../WaaS_Setup/initVSI-JCL/epsbind.jcl#12-17) binds the EPSCMORT  package. 
    -  The conrtol cards for the bind utility follow the "SYSTSIN DD *" line. 
    -  The DSN control card connects the job to the DBD1 DB2 subsystem.  
    -  It then Binds the package EPSCMORT from the PDS allocated with the "//DBRMLIB DD ...". Thats where DBB stores the DBRM when it builds the program. 
    -  Bind Package names the plan 'EPSPLAN' it belongs too and includes the application (PKLIST) package list also called a collection.  
    -  The Plan is defined once.  But Package bind must be executed whenever a new DBRM is created. 
    
**DB2 System layer**
Developers work with Database Administrators (DBAs) to define DB2 resources like tables, stored procs, plans, packages and other objects related to their application.  

In addition to their many tasks, DBAs maintain the DB2 Subsystem which, like CICS, is an STC.  In the WaaS stock environment, the STC job name starts with the prefix DBD1. DB2 has seveal supporting STCs with the same prefix. 

**DB2 STC in WaaS 3.1**
<img src="../images/db2stc.png"  width="500">



### RACF Security 
RACF is the security subsystem for zOS and its subsystems.  There are other security products like 'Top Secret' and ACF2. On WaaS, RACF profiles are defined to allow CICS to connect to DB2.

The [racfdef.jcl](../../WaaS_Setup/initVSI-JCL/racfdef.jcl#12) job is run once to define the permission to access these resources:   
 - RDEFINE FACILITY DFHDB2.AUTHTYPE.DBD1 - defines the security for the **DB2CONN** CICS resource created in the DFHCSDUP job. 
 - RDEFINE FACILITY DFHDB2.AUTHTYPE.EPSE defines security for the **DB2ENTRY** resource. 
 - The 'PE' cards define the RACF User(s) PErmission to use the resource. 
   - In a WaaS environment, the IBMUSER is a special (root-like) user that with READ permission. 
   - The CICSUSER is CICS's STC RACF ID given the same access.  
 - The RDELETE cards clean out definitions when rerunning the job. 
  