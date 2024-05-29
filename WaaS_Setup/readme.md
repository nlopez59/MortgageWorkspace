## A beginners guide to Cobol CICS/DB2 application development        

This was written for those new to zOS application development.  As a reference, the IBM sample 'MortgageApplication' (MortApp), in this repo, will be used to introduce basic concepts, terminology and application design with a focus on CICS/DB2. As a aid in further learning, links to external material have been included. 

#### Foundational concepts
Mainframe programs are written mostly in Cobol. Others can be in Assembler, PLI and other programming languages. Applications are a set of one or more programs. Each program specializes in some specific business feature. Applications and the data they process can be designed as interactive (online) or as batch processes. 

**Interactive** applications use the IBM product [CICS](https://www.ibm.com/docs/en/zos-basic-skills?topic=zos-introduction-cics) or [IMS](https://www.ibm.com/docs/en/integration-bus/10.0?topic=ims-information-management-system).
  - They are designed to interact with users to gather and send data over a network connected text-based 3270 terminal. 
  - Modern interactive applications can substitute 3270 screens with a Web front-end to access CICS programs and resources. 
 
**Batch** applications run using [Job Control Language - JCL](https://www.ibm.com/docs/en/zos-basic-skills?topic=jobs-what-is-batch-processing).  
 - Batch is designed to process large amounts of data (batches) without user interaction. 
 - A JCL job is a sequence of step(s) that execute an application program or some utility like sort or DB2 bind. 
 - Steps also have Data Definitions (DDs) to allocate the files (Datasets) used by the program. 
 - Jobs are submitted to the [Job Entry Subsystem - JES](https://www.ibm.com/docs/en/zos-basic-skills?topic=jobs-what-is-batch-processing) which allocates the DDs and executes the program in  each step. 
<br /> 
   Sample JCL step that executes program IEFBR14 and allocates a dataset with the DDname of DD1. The 'SYSOUT=*' DDs are special JES files to display output logs produced a program.  
 <img src="../images/jcl.png" width="500">

The diagram below illustrates the different layers of a mainframe application.  zOS, the operating system is at the bottom and supervises all the work to support program execution and the hardware resources they use (not shown).   Above zOS are the online and batch subsystems.  Other subsystems, like DB2, are common across online and batch applications. The top layer represents mainframe applications. They access subsystem services through an API layer. For example, EPSCMORT accesses CICS services using ['EXEC CICS ...'.](../MortgageApplication/cobol/epscmort.cbl#90-95) and it accesses DB2 resources with ['EXEC SQL ...'](../MortgageApplication/cobol/epscmort.cbl#230-234).  These 'EXEC' statements are translated by the Cobol compiler to call subsystem stub programs to handle the data exchange. 

<img src="../images/zarch.png" alt="App Arch" width="600">


### Anatomy of a CICS Application  
A basic [CICS application](https://www.ibm.com/docs/en/cics-ts/5.6?topic=fundamentals-cics-applications) has several parts.   In our example, we will look at the source code used by DBB to build the MortApp.


**The code**
MortApp is a basic online CICS application made up of several programs:
- [cobol/eps**c**mort.cbl](../MortgageApplication/cobol/epscmort.cbl#L155-157) is the main program. It uses the "EXEC CICS" api to call **bms/epsmort**.   
<br />   

- [bms/epsmort.bms](../MortgageApplication/bms/epsmort.bms) is a 3270 [BMS](https://www.ibm.com/docs/en/cics-ts/5.6?topic=programs-basic-mapping-support) screen definition program written in assembler language.  
  - The compiler transforms this source file into 2 artifacts; a [symbolic copybook 'EPSMORT' and a physical executable load module](https://www.ibm.com/docs/en/cics-ts/6.1?topic=map-physical-symbolic-sets). 
  - A load module is another name for an executable program. Or the output artifact of the link-edit (binder) step of a build. 

  - The symbolic copybook is saved in a [Partitioned Dataset - PDS](https://www.ibm.com/docs/en/zos-basic-skills?topic=set-types-data-sets) allocated with the dbb-zappbuild "HLQ' argument. 
  - This PDS is then used as a SYSLIB in subsequent builds. 
  - SYSLIB is a DDname to allocate a copybook PDS as input to the compiler. 
  - The compilee replaces a Cobol program's ```Copy some-copybook``` statement with the actual copybook source file during the build like in the [epscmort](../MortgageApplication/cobol/epscmort.cbl#L55) program.  
   
    <br />   
    
    Example epsmort copybook member

    <img src="../images/epsmort.png" width="500">
  
    ```A special note on DBB builds is that BMS copybooks are not stored in the source repo like other copybooks.  Instead they are stored in the PDS created during the DBB build of the BMS program. ```
    <br />   

- [cobol/epscsmrt.cbl](../MortgageApplication/cobol/epscsmrt.cbl) is a program that is called by EPSCMORT to calculate a mortgage. 
  - The data is returned using a [COMMAREA](https://www.ibm.com/docs/en/cics-ts/6.1?topic=affinity-commarea) copybook.  
  - In Cobol, COMMAREAs are data structures defined as copybooks within the 'Linkage Section' and used to exchange data between programs.
<br />

- [copybook/epsmtcom.cpy](../MortgageApplication/copybook/epsmtcom.cpy) is the COMMAREA used between EPSCMORT and EPSCSMRT. It includes 2 other copybooks. One for  input and another output data structures.
<br />   

## The infrastructure
Once the MortApp is built, it needs to be defined to CICS and DB2.  This section outlines the Jobs used for the definitions.

**CICS Application Defintions**
- Transactions are what drive CICS applications. 
  - [EPSP](../../WaaS_Setup/initVSI-JCL/dfhcsdup.jcl#L22) is the main MortApp **Transaction ID** (tranid). All CICS applications must have at least one tranid. 
  - When this tranid is entered on a CICS 3270 screen, CICS starts program EPSCMORT. 
  - The transaction also defines what group its in. A CICS group is a set resources that are common to an application.  In this case, EPSMTM is the group name for the MortApp. 
<br />   
- Transactions and all other CICS resources are defined using the IBM batch utility  [DFHCSDUP](https://www.ibm.com/docs/en/cics-ts/6.1?topic=resources-defining-dfhcsdup) , as in this example. Or they can be defined with the CICS tranid CEMT [here is a list of other CICS utilities](https://www.tutorialspoint.com/cics/cics_transactions.htm).  In the example JCL you will see lines (control cards) that define:
  - [DB2CONN](https://www.ibm.com/docs/en/cics-ts/6.1?topic=sources-defining-cics-db2-connection) - that is used to connect the MortApp to the DB2 subsystem 'DBD1'. It also defines 'EPSPLAN' as the DB2 plan for this group (see DB2 definitions below). 
  - [DB2ENTRY](https://wwtestw.ibm.com/docs/en/cics-ts/6.1?topic=sources-defining-cics-db2-connection) - defines DB2 properties related to all transaction for the EPSMTM group. 
  - MAPSET  - is the physical BMS load module that displays a 3270 screen (map)
  - PROGRAM - are the individual programs that make up the rest of the MortApp. 
 

**CICS System Layer**
Application teams focus on the various parts of thier application and work with the CICS Admins to design the respource and defintion needed to run their code. 

CICS Admin also configure system-wide settings  used across all approvlication.  The list of things they do is extensive.  But for our example there are 2 key componebts that need to be configure to run our sample applicaiton: 

- **The CICS Started Task**
In simple terms, CICS runs like a batch job under JES.  The main difference is that its a long running job like a unix daemon task.  This type of job is called a 'Started Task' (STC).  

The CICS STC in WaaS 3.1
<img src="../images/cicsstc.png" width="500">




Application load modules are added to a PDS defined in CICS's JCL under the DDname [DFH**RPL**](../WaaS_Setup/initVSI-JCL/cicsts61-mod.jcl#L69).  That DDname (RPL for short) is an input dataset to the program [DFHSIP](../WaaS_Setup/initVSI-JCL/cicsts61-mod.jcl#L38) which is CICS. 

When a user enters the transaction EPSP, CICS checks the transaction's resource definition, defined in the DFHCSDUP job, and finds the program name EPSCMORT. CICS loads and executes that program from the RPL PDS. The first thing EPSCMORT does is issue an ['EXEC CICS SEND-MAPONLY MAPSET('EPSMORT')](../MortgageApplication/cobol/epscmort.cbl#L152-L157). This api call tells CICS to load and execute the physical BMS load module from the RPL PDS to display its 3270 map. 

For performance reasons, CICS chace loaded program in memory.  A CICS Newcopy command is issue to refresh that cache when the load module is updated.  A newcopy can be excuted using the CICS utility CEMT like ``` CEMT SET PROG(EPSMORT) NEWCOPY ```




- **The CICS [SIP](https://www.ibm.com/docs/en/cics-ts/5.6?topic=areas-sip-system-initialization-program)**
  This is CICS's main staup configuration file.   In a WaaS Stock image it is not define to start the DB2 Connection.   A copy was made and stored in this repo to replace the SIP and enable the [DB2CONN](../WaaS_Setup/initVSI-JCL/dfh$sip1#L7) property.




 




**DB2 Application Definitions**
As illustrated below, programs are defined to DB2 using a [Plan](https://www.ibm.com/docs/ru/db2-for-zos/12?topic=recovery-packages-application-plans).  Plans are collections of DB2 packages. A package represents the DB2 resources used by a program.  

When a DB2 program is compiled, a DB2 DBRM artifact is created. The DBRM is then bound to DB2 to update its resource requirement before it could run.  
<img src="../images/plan.png" alt="DB2 Plans and packages" width="500">
  
<br />   

- [epsbind.jcl](../../WaaS_Setup/initVSI-JCL/epsbind.jcl#12-17) binds the EPSCMORT  package. 
    -  The conrtol cards for the bind utility follow "SYSTSIN DD *". 
    -  The DSN control card connects to the DBD1 DB2 subsystem.  
    -  The BIND package point to the PDS member EPSCMORT in the PDS alloacted with the "//DBRMLIB DD ..." card. Thats where DBB stored the DBRM when it built EPSCMORT. 
    -  Bind Package names the plan 'EPSPLAN' and includes the collection of packages for the application (PKLIST).  
    -  The Plan is defined once.  But whenever a package is changed and a new DRBM creatd, it must be bind again.  
    

**DB2 System layer**
Developers work with Database Adminitrators (DBAs) to define DB2 resoruces like tables, stored procs, plans, packages and other objects related to their applcaition.  

In addition to their many tasks, they maintain the DB2 Subsystem STC.  In our WaaS environment that STC is called  DBD1 ans is made up of several supporting STCs starting with the same jobname. 

DB2 STC in WaaS 3.1
<img src="../images/db2stc.png"  width="500">



**RACF Security**
RACF is the security subsystem for zOS.     There are others like Top Secret and ACF2. In the MortApp, access to its DB2 resources is from CICS is defined in RACF  

The [racfdef.jcl](../../WaaS_Setup/initVSI-JCL/racfdef.jcl#12) job is run once to define the permission to access these CICS/DB2 resources:   
 - RDEFINE FACILITY DFHDB2.AUTHTYPE.DBD1 - defines the security profile for the **DB2CONN** CICS resource defined in DFHCSDUP job. 
 - RDEFINE FACILITY DFHDB2.AUTHTYPE.EPSE defines security for the **DB2ENTRY** resource. 
 - The 'PE' cards define which RACF User can access these profiles. 
   - In a WaaS environment, the IBMUSER is a special (root-like) user that is given access. 
   - The CICSUSER is CICS's RACF ID is also given access.  
 - The RDELETE cards are used to clean out the definitions when rerunning the job. 
  




## Other useful terms 
... tbd 










core 

There are severla layers of mainframe programmering to consider 
 1. Operating System it selft. In this case we are using z/OS ver 3.1. That the latest IBM release as of 2024.
   - System's programmers (sysProg) are responsibenl for installign and maintaint this layer   - 
   - They also install key system products like CICS, DB2 and others. These are sometimes called subsystems. 
   
 2. Subsystem Admin - These are Adminstrators for each type of subsystems with epertise in designing, configuring, maintaining subsystems 
   - CICS Admins - work with Application developement teams to degien and support their applications 
   - Database Admin (DBA) -  is responsible for simialr tasks for DB2
   - There can be many other roles like the MQ Admin, RACF, Networking, Data storage 
 3. The application layer, This  

There are other groups like those who manage the physical hardawre and the operations team who monitor day to day acitites and report issues to owning appliaciton or systems teams. 
 
Anatomy of a CICS DB2 application:
- using the cobol programms in the MortApp repo, you will see folder for 
  - bms - which is the source of Basic Mapping Support (bms or maps for short) files.   I know I said MortApp is a Cobol program but maps are an exceptin. They are assmebler progrsm.  There job is the 'map' text and input fields o na 3270 screen to get/set data to a user.  bms/epsmort is the main bms map. NOrmally the main map is a menu whith options ot other maps (Screen).
  - cobol - is the where the main code lives.   EPSCMORT is the main program that starts the application process.
  - copybook - in this example are files used by cobol prgrmas to define certain data structures. They are typcail created when 2 or more pgms needs share the same data layout - also called a record layout. 
  
##So how does this all work?
A CICS program is 'installed' into a cics subsystem also called region. A region is just a Started Task (STC) running all the time like a deamon in the distributed world. An STC is like any JCL Job submitted to JES (Job Entry Subsystm) to allocate files (DDs) and run programs.  

Some jobs, like batch applications, start and end in a short amount of time.  Others, like CICS and DB2 run all the time. 

Ther can be many parts to a CICS program.  In this example, we will look at the runtime aspects like:
    - load modules:
      - Just like batch programs, pgms not executed in CICS, CICS programs are complied and linked and stored in a load PDS. 
      - In CICS the load pds is also called the Resource Parameter List or DFH**RPL** DD statement of the CICS STC JCL.  Take a look ....
      - changes to load modules will require a special CICS cmd to refresh it. Thats callaed a 'newcopy' 
      - If the program uses DB2, a Database Request Module (DBRM) is created as part of the compile. It must bound to the DB2 subsytem used by the applicaiotn. 
    - ...
      - 
     like another other program.  The diffenrebce is it will include some CICS system programs to , CICS and DB2 defiA CICS application has many parts To create a





.... wasteland 




The also use several 'system' level services provided by CICS and in out case DB2. 

When designing an applicaiotn, teams normally collaborate with zOS system admins to help archtect the optimum design that also follows some organizational  standard. 

 program designed has several CICS resource definition; program, map, transaction and more.  
