# Concepts in Mainframe Application Design, Configuration and Deployment
For those new to z/OS application development, exploring the IBM sample CICS/DB2 'MortgageApplication' (MortApp) in this repository can be a valuable reference. By studying MortApp, you can gain insights into several key areas:

- Basic CICS Application Design: MortApp serves as a practical example of how CICS applications are structured and designed. You can learn about the components that make up a typical CICS application, such as transactions, programs, and resources.

- Application and System Level Configurations: MortApp provides insights into the configurations required at both the application and system levels. You can understand how to define users, resources, and profiles in RACF, as well as configure CICS and DB2 for application execution.

- Build and Deploy Concepts (Non-CD Mode): Studying MortApp can help you grasp the concepts involved in building and deploying z/OS applications. You can learn about the steps and processes involved in compiling, linking, and deployment.

- Considerations for Porting Applications to New Environments: MortApp can also guide you on the considerations and best practices for porting a CICS/DB2 application to a new z/OS environment, such as a Wazi as a Service (WaaS) 3.1 stock image. This includes understanding the necessary configurations, dependencies, and environment-specific settings.

Additionally, external reference material is provided to supplement your learning and provide further insights into z/OS application development concepts.

### zOS Application Infrastructure Services
The diagram below illustrates the different software layers used by mainframe applications.  
- zOS is the operating system, shown at the bottom, that supervises applications, subsystems (middleware) and the hardware (not shown). Systems Programmers install, patch, upgrade and tune this layer as well as support Systems Administrators and Developers. 
  
-In the middle are online, common, and batch services, which are managed by various systems administrators with specialized skills to configure, secure, and tune these services. They also support application teams during development and operations.

- The top layer, represents the business applications and the subsystem services they can use through one or more application programming interfaces (API).
<img src="images/zarch.png" width="700">


### zOS Application Design Basics 
Mainframe programs are mostly written in the COBOL programming language. Other mainframe languages include Assembler, PL/I, and others. Applications are composed of one or more programs and can be a mix of languages. Programs are designed to fulfill specific business features or solutions. Applications and the data they process can be either interactive (online) or batch.


#### Interactive Applications use the IBM product [CICS](https://www.ibm.com/docs/en/zos-basic-skills?topic=zos-introduction-cics) or [IMS](https://www.ibm.com/docs/en/integration-bus/10.0?topic=ims-information-management-system).
  - CICS is like a Distributed Application Server; JBoss, Apache, WebSphere and others.  Its purpose is to provide a runtime environment where zOS applications are deployed, executed and managed.
  - Interactive applications are designed to 'interact' with users to gather and send small amounts of data over a networked 3270 terminal (text based green screen). 
  - CICS can handle thousands of concurrent user sessions. 
  - Modernized CICS applications substitute 3270 screens with a web front-end and other methods to access  application back-end services. 
 
 Example CICS 3270 screen
 <img src="images/epsmap.png" width="400">

####  Batch Applications run using [Job Control Language - JCL](https://www.ibm.com/docs/en/zos-basic-skills?topic=jobs-what-is-batch-processing).  
 - They are designed to process large amounts of data in 'batches' without user interaction. 
 - JCL is like a script with a sequence of step(s) that makeup a job. 
 - The JCL line ```"EXEC PGM=???"``` defines a step and the program it will EXECute like an application program or utility like Sort, DB2 bind...
 - Steps have one or more ```"DD DSN=???,..."``` lines that are Data Definitions (DD) used to create a new file or allocate an existing file by DataSet by Name (DSN).
 - Applications process data in files or other format like DB2 tables, MQ Queues and a variety of other methods. 
 - Jobs are submitted to the [Job Entry Subsystem - JES](https://www.ibm.com/docs/en/zos-basic-skills?topic=jobs-what-is-batch-processing) to execute the program(s) in  each step(s). 
 - Some processes can run outside of JES like dbb-zappbuild. This java process runs under an SSH session without JCL and JES.  However, it allocates files and executes programs just like a JCL job.  
 - Security for all processes on zOS is managed by RACF - see below. 
<br/> 

   The example job below has one step to execute the IBM utility program IEFBR14. That step allocates a new DSN with the DD name of DD1. A new file is allocated with certain attributes like logical record size and disk space on a volume (disk).  The ```"SYSOUT=*"``` DDs are allocated by JES for program logs. 
 <img src="images/jcl.png" width="500">


## BBMM ***


#### Build and Deploy
A modern z/OS DevOps process typically utilizes IBM Dependency Based Build (DBB) and a deployment server like Urban Code Deploy. However, there are also other non-DevOps processes such as Endevor and Changeman that can build and deploy mainframe applications using traditional batch JCL jobs.

In general they all perform the following basic steps: 
1. **Compile**: transforms source code into object code like the Cobol compiler. 

2. **Linkage Edit (linkedit)**:  transforms object code into an executable load module. The linkage editor is also referred to as the binder and is not the same as the DB2 bind process. 
 
3. **Deploy**: 
   - load module(s) are copied into a Library (Library and PDS are the same thing and are types of zOS file systems)
   - for Online or Common services, a CICS Newcopy or DB2 Bind may be needed
   - batch applications may require new or updated JCL 
   - there are many other system resource defintions or updates like a DB2 table, a CICS screen that may be needed as part of a deployment
   

   
## MortApp Design 
A basic [CICS/DB2 application](https://www.ibm.com/docs/en/cics-ts/5.6?topic=fundamentals-cics-applications) has business logic, a data layer, and screen(s) that are also called map(s) and various other system resources. 

The MortApp is designed with 4 types of source files; A main program, a map program, subprograms and COMMAREAs:
1. [eps**c**mort.cbl](MortgageApplication/Cobol/epscmort.cbl#L149-L154) 
   - is the main program. 
   - it uses the ```"EXEC CICS SEND MAP ..."``` Cobol statement to call program **bms/epsmort**.   
   - it also uses ```"EXEC SQL ..."``` to access DB2 data. 
   -  
1. [epsmort.bms](MortgageApplication/bms/epsmort.bms) 
   - is a 3270 [BMS](https://www.ibm.com/docs/en/cics-ts/5.6?topic=programs-basic-mapping-support) program written in assembler language.  
   - the compiler creates 2 artifacts from this source code:
     - a symbolic copybook
     - a physical load module  
   - when EPSCMORT is built, the compiler allocates the copybook SYSLIB PDS and adds the source to the program
   - **Note** BMS copybooks are not stored in the application repo like other copybooks.  Instead they are stored in the PDS created during the DBB build of the BMS program.
  
1. [Cobol/epscsmrt.cbl](MortgageApplication/Cobol/epscsmrt.cbl) 
   - is a subprogram called by EPSCMORT ```"EXEC CICS LINK PROGRAM( W-CALL-PROGRAM ) **COMMAREA**( W-COMMUNICATION-AREA )"``` to calculate a mortgage. 

1. [copybook/epsmtcom.cpy](MortgageApplication/copybook/epsmtcom.cpy)  
   - is the COMMAREA used to exchange data between programs
   - in Cobol, they are included in each program from a shared copybook PDS
   - COMMAREAs are designed  for this application. It includes 2 other copybooks; one for input the other for output data structures


#### CICS API
Let's see how an API call is created from the Cobol source code [```"EXEC CICS SEND MAP('EPMENU') MAPSET('EPSMORT') ..."```](MortgageApplication/Cobol/epscmort.cbl#L149-L154) in EPSCMORT: 

- At compile time, the command is _translated_ into a CICS API service call. 
- At linkedit time, the API is [statically](https://www.ibm.com/docs/nl/Cobol-zos/6.3?topic=program-examples-static-dynamic-call-statements) linked from a SYSLIB PDS into EPSCMORT to create a single load module.      
- At runtime, when EPSCMORT issues the 'Send Map' command, the CICS API loads and executes the EPSMORT BMS program to display its 3270 map (map and screen are the same thing).  


#### DB2 API
DB2 on z/OS is an IBM product that provides common database services to interactive and batch applications. Programmers use Structured Query Language (SQL) to read from and write to DB2 tables using DB2 APIs.

- At compile time, all ```"EXEC SQL ..."``` source code statements are _precompiled_ into DB2 API calls. 
- The compiler also outputs a DB2 DBRM file for the program.
- At linkedit time, the DB2 API is statically linked from a SYSLIB PDS into EPSCMORT to create a single load module.     
- Load modules can be linked with a mix of CICS, DB2 and many other subsystem APIs. 
- For DB2 based programs, a job is executed to Bind the program's DBRM to the DB2 subsystem. 

The diagram below illustrates how a static program or API like "PROGB" is linked into another main program "PROGA" to produce one load module. Notice how the source languages can be different; Cobol and Assembler in this case. 
<img src="images/build1.png" width="600">

_Side Notes_ 
 - In addition to including copybooks, modern Cobol compilers _translate_ and _precompile_ CICS and DB2 source before the final compile phase.
 -  In older versions of the compiler,   translation and precompile were executed as pre-processor steps before the compile. 
 -  The output of a compile is called  Object Code (or Object Deck) and used as input to the linkedit phase.   
 - A load module is another name for an executable program. Or the output artifact of the linkedit (binder) step of a build. They are also called API, stubs, binaries or objects. 
 - Load modules can be statically linked during the linkedit phase as explained above.  Or they can be dynamically called at runtime were the 'system' finds and loads the program for execution. 
 - The member name of a load module is typically the same as the input object deck. However, in some cases, the name can be changed using an 'alias' linkedit control card, which renames the output load module. One reason for doing this is to ensure backward compatibility. For example, the IBM MQ API starting with 'CSQ*' can also be called using the newer 'DFH*' prefix. This allows older build JCL that includes a 'CSQ' API to still work while newer builds can use the new prefix.   
<img src="images/alias.png" width="600">


## CICS Application Resource Definitions  
This section outlines how the resources of a new application are defined in CICS, using MortApp as an example.

#### CICS Transactions
All CICS applications have a least one transaction that is used as a starting point: 
  - EPSP is the MortApp **Transaction ID** (tranid). 
  - When EPSP its entered on a CICS terminal, CICS starts the main program EPSCMORT.   
  - EPSCMORT calls EPSMORT to send a Map to the user screen.
  - The user enters data in the screen that is sent back to the main program.  
  - This can be repeated until the user enters PF3 to terminate the transaction.  
<img src="images/pgmflow.png" width="700">


#### CICS Resource Definitions  
Transactions and all other CICS application resources are configured using the IBM batch utility [DFHCSDUP](https://www.ibm.com/docs/en/cics-ts/6.1?topic=resources-defining-dfhcsdup). The example JCL below shows the resource definitions needed for the MortApp:
  - GROUP(EPSMTM) is used to define all related application resources.  CICS commands and global properties can be performed at the group level like the 'DELETE GROUP' command that removes all resources for the group.
  - [DB2CONN](https://www.ibm.com/docs/en/cics-ts/6.1?topic=sources-defining-cics-db2-connection) - is the DB2 subsystem and DB2 plan used to connect any DB2 program in the group to the DB2 subsystem name DBD1.
  - [DB2ENTRY](https://www.ibm.com/docs/en/cics-ts/6.1?topic=sources-defining-cics-db2-connection) - provides the default DB2 properties for all transactions in the group. 
  - MAPSET  - defines EPSMORT as the physical BMS load module. 
  - PROGRAM - defines each program. 
  
<img src="images/dfhcsdup.png" width="700">

#### Installing a CICS Application Definition
As a final step, MortApp is added (installed) once to CICS with the  commands:
  - ```'CEDA INSTALL GROUP(EPSMTM)'``` installs the MortApp group 
  - ```'CEDA INSTALL DB2CONN(DBD1)'``` installs the DB2 Connect resource

Use the CICS command ```"CEDA DISPLAY GROUP(EPSMTM)"``` to view the installed definitions for the MortApp group:
<img src="images/ceda1.png" width="700">
 

As shown above, tab over to an entry and enter **V** to view more details:
<img src="images/ceda2.png" width="700">



## The CICS System Layer 
Application teams focus on the various parts of their application and work with Systems Admins to define the resources needed to run their code. 

In addition to application level configurations, CICS Admins configure system-wide settings used across all applications.  The list of things they do is extensive.  But for our example, there are 2 key components needed to enable a new application like MortApp on a new environment; the CICS Started Task and the CICS SIP. 

#### The CICS Started Task** 
In simple terms, CICS runs like a batch job under JES, but with a key difference—it's a long-running job, similar to a Unix daemon task. This type of job is called a 'Started Task' (STC), which is configured to automatically start when z/OS is IPLed (Initial Program Load, also called boot).

Example CICS STC running in WaaS 3.1
<img src="images/cicsstc.png" width="500">


CICS loads applications from the DFH**RPL** DD in its JCL. That DD is modified to include the load PDS(s) of all CICS applications. 

Using dbb-zappbuild's "HLQ='DBB.POC'" will add MortApp load modules to a PDS called "DBB.POC.LOAD" PDS that is part of the RPL DD concatenation.
<img src="images/rpl.png" width="700">

This is a short-cut in deploying a load module during a DBB User Build. Typically, a Deployment server is used to copy a load module into an RPL lib. 

#### CICS Newcopy 
When EPSP is started, CICS loads and executes program EPSCMORT from the RPL lib. 

For performance reasons, CICS caches loaded programs in memory.  During early dev and test, as new versions of a program are tested, the CICS command  ```'CEMT SET PROG(EPSCMORT) NEWCOPY'``` is required to reload the module from the RPL and refresh CICS's cache. 

The batch job [newcopy.jcl](jcl/newcopy.jcl) can be used to run that command. 



#### The CICS [SIP](https://www.ibm.com/docs/en/cics-ts/5.6?topic=areas-sip-system-initialization-program)** 
The CICS 'System Initialization Program' file or SIP is the main configuration file.   In a new environment, it must be configured to enable the DB2CONN feature as shown below. This enables the attachment facility between CICS and DB2. 
<img src="images/sip2.png" width="500">  
<br/>   

## DB2 Application Configuration 
Applications that use DB2 require several predefined resources like, data tables, a  plan and security.

The diagram below shows how a plan is a collection of packages. Each represents the resources used by a program like a data table.
<img src="images/plan.png" width="600">  

When a DB2 program is _precompiled_, a DB2 "Database Request Module" (DBRM) artifact is created and [bound](https://www.ibm.com/docs/en/db2-for-zos/12?topic=zos-binding-application-packages-plans) to a package within a plan.   

[bind.jcl](jcl/bind.jcl) is an example DB2 bind package job for the EPSCMORT program. 
-  The ```"SYSTSIN DD *"``` in-stream control cards define: 
   -  ```'DSN SYSTEM(DBD1)'``` command  that connects the job to the DB2 subsystem named DBD1.
   -  ```'BIND PACKAGE(EPS) MEMBER(EPSCMORT)'``` reads the DBRM member EPSCMORT from the PDS allocated by the "DBRMLIB" DD and performs the bind. 
   -  A bind package must be performed each time a DB2 program is changed. 
  
On a new environment, a DBA initializes an application's plan and grant the owning team access once.
   - The ```"BIND PLAN(EPSPLAN) PKLIST(EPS.*)"``` db2 command creates plan "EPSPLAN" that is also used in the ```"DEFINE DB2CONN(DBD1)    GROUP(EPSMTM) PLAN(EPSPLAN) DB2ID(DBD1)"``` resource defined in the the DFHCSDUP job.
   -  This command also defines the plan's PKLIST "Package List" named "EPS.\*".   A PKLIST is a _collection_ of one or more packages for a plan.   Once the plan is created, a developer simply runs the bind package job to apply new DBRMs when testing changes. 
<img src="images/epsbind2.png"  width="500">  
<br/><br/>

   - The ```"GRANT EXECUTE ON PLAN EPSPLAN TO PUBLIC"``` grants public access to execute EPSPLAN.  - A grant is a DB2 command to manage access to resources. 
   - In a WasS environment access can be given to all.  In a production environment, access is normally given to a RACF group assigned to an application like, for example, EPS. 
<img src="images/epsgrant2.png"  width="500">  
 
_Side Notes_ 
- The create Plan and Grant are performed once by a DBA to initialize a new application.
- The package bind job is performed by developers each time a DB2 programs is changed. 
- These jobs require the DSNTEP2 utility described below. 


## DB2 System Layer
Developers collaborate with DB2 System Administrators (DBAs) to define DB2 resources such as tables, stored procedures, plans, packages, and other objects related to their applications.

DBAs also maintain the DB2 subsystem, which, like CICS, is a Started Task (STC). In the WaaS 3.1 stock image, the DB2 STC job name starts with the prefix DBD1. DB2 has several supporting STCs with the same prefix that provide various services.
**DB2 Subsystem STC in WaaS 3.1**
<img src="images/db2stc.png"  width="500">


On a new environment, the sample batch job below is executed once to install the DB2 utility "DSNTEP2" that is used to define and update DB2 application resources like bind plan and grant: 
<img src="images/dsntep2.png"  width="500">



## Resource Access Control Facility (RACF) - z/OS Security 
RACF is the security subsystem on z/OS, responsible for defining users, resources, and profiles that govern user access to resources. Other security subsystems like 'Top Secret' and ACF2 are generically referred to as the "Security Access Facility" or SAF. Resources can include files, applications like CICS, TSO, Unix System Services, and many others.

All processes run under an authenticated user ID.  CICS and TSO use a login screen to authenticate users with a secret password. An SSH connection to zOS can authenticate users with a password, SSH key or zOS Certs. 

STCs like CICS, DB2, UCD Agent, pipeline runners are assigned a RACF user ID by the zOS Security Admins.  This special ID is called a [protected account](https://www.ibm.com/docs/no/zos/2.4.0?topic=users-defining-protected-user-ids) and they tend to have a high level of access privileges.  

In a new zOS environment, authroization to connect [CICS to DB2](https://www.ibm.com/docs/en/cics-ts/5.6?topic=interface-overview-how-cics-connects-db2) requires RACF permission. The example job below defines 2 facility class resources and the permissions to use them:
 - ```'RDEFINE FACILITY DFHDB2.AUTHTYPE.DBD1'``` - defines a resource name ending in **"DBD1"** that is the name of the "DB2CONN=**DBD1**" resource defined in the DFHCSDUP job. "DBD1" is an example name. Any name can be used as long as they match.  This example uses the DB2 subsystem name DBD1.
    
- ```'RDEFINE FACILITY DFHDB2.AUTHTYPE.EPSE'``` defines a resource name ending in **"EPSE"** that is the "DB2ENTRY(**EPSE**)" resource name defined in DFHCSDUP.  Any name can be used as long as they match. 
   

The 'PE' RACF commands create profiles to '**PE**rmit' user(s) access to a resource. This example permits the CICSUSER ID to connect to the DB2 instance DBD1 using the EPSE entry.
<img src="images/racdef2.png"  width="700">
 

The System Security Admin role typically provides RACF access to all users in an organization, including administrators. In a WaaS environment, the default RACF user, 'IBMUSER', has special privileges to perform all system-related tasks."

## Summary
When you examine MortApp, you're gaining insights into the architecture and configuration requirements of CICS/DB2 applications for deployment in new environments. This knowledge is transferable, allowing you to apply similar principles and configurations when migrating other CICS/DB2 applications to different z/OS environments.

Integrating additional DevOps practices involves leveraging tools like Jenkins or IBM DBB for automated build processes, and implementing CI/CD pipelines to automate testing and deployment tasks. 

By incorporating these tools and practices, you can establish an end-to-end DevOps workflow that enhances development efficiency, promotes collaboration, and improves the overall reliability of your applications across diverse z/OS environments. 
<img src="images/waasdevops.png"  width="700">