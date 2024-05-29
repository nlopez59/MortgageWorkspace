# DBB DevOps Proof of Concept (POC) with IBM WaaS Stock Image  

## Overview
This repo contains a script to install a sample CICS/DB2 Cobol application for use in a DevOps POC running on WaaS.  To get started, clone this repo and run the [initPOC.bat](Waas_Setup/initPOC.bat) script from a Windows DOS terminal.  When it completes, use the default `IBMUSER` RACF ID and the password 'sys1' to login to CICS. Then run transaction `EPSP` to verify the installation. As a final step, configure your IDE, IDz or vsCode, and any CI/CD orchestrator to run DBB based build and deploy pipelines. 

For those new to CICS/DB2 programming, the [WaaS_Setup](WaaS_Setup/readme.md) page provides a general overview and the steps performed by the script to install and configure the sample app.   


### General Information
WaaS stock images do **not** include a sample app or other DevOps/SDLC configurations like dbb-zappbuild, DB2 connection to CICS and several others settings. The initPOC script was created to address those needs.

The script has been tested with the z/OS 3.1 image shown below. Unfortunately, new stock images may introduce new system libraries that will require manual reconfiguration of this script. <img src="images/vsi.png" alt="Supported Stock Image" width="400">

### Why a Windows Batch Script?
- Its small and simple. 
- It does not require any knowledge of specialized tools like Ansible, Terraform...
- IBM’ers with access to create a WaaS instance can use this for testing and learning.
- Customers with access WaaS VSI can follow these same steps as part of a POC.
  
### PreReqs - Before Running the Script 
- Add the active VSI’s IP to your local `.ssh/config` with the entry name `poc-waas`:
   ```plaintext
   Host poc-waas
       HostName <VSI_IP>
       User IBMUSER
- Ensure your local SSH key can access the VSI.  
- Ensure the VSI is active and the z/OS IPL complete by using the ssh cmd - ```ssh poc-waas ```
- You will need Windows Admin rights to install the z/OS Certificate for 3270 and IDz access. 
  
### After the script completes  
- Genrate and add the zOS IBMUSER's public SSH key to your github server account using the zOS Unix cmd:
    - ssh-keygen  -t rsa -b 4096 -C 'ibmuser@ibm.com'        
- Configure your IDE, Git, CI and CD servers
- Ensure all WaaS/zOS IP ports are opened for use by the tools in your stack like:
    - 992 for secure 3270 with TLS 1.2  (login with IBMUSER and password 'sys1' using the your WaaS VSI IP
    - 8115 JMON for UCD and IDz
    - 8137-8139 for IDz over RSED STC
    - 8195 for Zowe over RSEAPI 
    - 10443 for Zowe over zOSMF as an alternative to RSEAPI
  - [Here is the full list of stock image products and ports](https://www.ibm.com/docs/en/wazi-aas/1.0.0?topic=vpc-configurations-in-zos-stock-images)

Example initPOC.bat output:    
<img src="images/initrun.png" alt="Init Script Run" width="700">


### Build and unit testing: 
- The sample CICS Mortgage application is installed and configured in the WaaS zOS instance.
- With IDz or vsCode, edit and build it with DBB using the '-HLQ' of 'DBB.POC'. 
- The app's CICS transaction is 'EPSP' which runs program 'cobol/epscmort' and displays the 'bms/epsmort.bms' map.

Sample CEDA DIsplay of the sample app's group (EPSMTM):
<img src="images/ceda1.png" alt="CEDA DI G(EPSMTM)" width="500">

- The JCL folder has jobs to run the applications DB2 Bind and CICS newcopy.
  - [jcl\newcopy.jcl](jcl\newcopy.jcl)  
  - [jcl\bind.jcl](jcl\bind.jcl)  
  - Changes to the main program EPSCMORT requires a DB2 bind.
  - All programs require a newcopy. 
- As a test, use IDz or vsCode to change and test the BMS map.
- Configure your CD pipeline to automate newcopy and binds. 
    
     
### Helpful CICS tips and transactions:  
-  CEDF - start a debug session
-  CESF - logoff
-  CEMT - manage resources like "CEMT SET PROG(EPSCMORT) NEWCOPY"
-  press the 'clear' key to reset the screen an enter to start a new transaction 
  
### CICS sample app screen shots:
Login to CICS with IBMUSER and the default password sys1.  You must reset the password on first login. 
Then run the EPSP transaction to view the main application menu.

<figure>
  <figcaption>Start a CICS Session </figcaption>
  <img src="images/scics.png" width="500">
</figure>

<figure>
  <figcaption>CICS logon with ibmuser password sys1 </figcaption>
  <img src="images/login.png" width="500">
</figure>

<figure>
  <figcaption>Start the EPSP transaction</figcaption>
  <img src="images/epsp.png" width="500">
</figure>

<figure>
<figcaption>THE EPSP main map EPSMORT</figcaption>
<img src="images/epsmap.png" width="500"> 
</figure> 
