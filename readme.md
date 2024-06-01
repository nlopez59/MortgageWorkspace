# DevOps Proof of Concept (POC) setup with IBM DBB and WaaS Stock Image v3.1 

Running a POC on a WaaS 3.1 image requires customization. The script [initPOC.bat](Waas_Setup/initPOC.bat) automates many of the steps to install a sample CICS v61 DB2 v13 application for running test cases. 

To get started:
1. clone this repo and run 'initPOC.bat' from a Windows DOS terminal
2. logon to CICSTS61 with IBMUSER and temp password 'sys1'. You will be required to reset the temp password.
3. run the 'EPSP' CICSTS61 transaction to verify the installation 
4. after the script:
   1. configure your IDE (IDz or vsCode)
   2. configure your CI/CD orchestrator 
   3. generate a zOS IBMUSER SSH key and cut/paste it into your git server account. SSH into zOS Unix and run:
    ```ssh-keygen  -t rsa -b 4096 -C 'ibmuser@ibm.com'```
- Open WaaS/zOS IP ports for use in your stack: 
    - 992 for 3270 access with TLS 1.2 (requires the install of the zOS cert) 
    - 8115 JMON for UCD and IDz
    - 8137 for IDz over RSED STC. Use 8137 as the main host port. 
    - 8195 for Zowe over RSEAPI 
    - 10443 for Zowe over zOSMF as an alternative to RSEAPI
    - [Here is the full list of stock image products and ports](https://www.ibm.com/docs/en/wazi-aas/1.0.0?topic=vpc-configurations-in-zos-stock-images)

### Prerequisites 
- SSH access to a WaaS instance.
- Add your WaaS instance's IP to your local PC's  `.ssh/config` file with the entry name `poc-waas`:
   ```plaintext
   Host poc-waas
       HostName <VSI_IP>
       User IBMUSER
- Test your connectivty using the ssh cmd - ```ssh poc-waas ```
- Windows Admin rights is required to install the z/OS Certificate for 3270 and IDz access. 
- A 3270 emulator.

### Build and Test: 
- Use the sample Mortgage application to run your POC use cases.  
- Define the [dbb-zappbuild](https://github.com/IBM/dbb-zappbuild) '--hlq' argument as 'DBB.POC' to add your load modules to the deafult CICS RPL PDS.
- The 'EPSP' CICSTS61 transaction runs program 'MortgageApplication\cobol\epscmort.cbl' which displays the 'MortgageApplication\bms\epsmlis.bms' map.

CEDA DIsplay of the MortApp's CICS group (EPSMTM):
<img src="images/ceda1.png" alt="CEDA DI G(EPSMTM)" width="500">

- The JCL folder has jobs to run DB2 Bind and CICS newcopy.
  - [jcl\newcopy.jcl](jcl\newcopy.jcl)  
  - [jcl\bind.jcl](jcl\bind.jcl)  
  - Changes to the main program EPSCMORT requires a DB2 bind.
  - All programs require a newcopy. 
    
     
### Additional Tips and References 
Some helpful CICS commands:
-  CEDF - enable debug session (EDF - disable with PF3)
-  CESF - logoff cics
-  CEMT - run various utility functions like "CEMT SET PROG(EPSCMORT) NEWCOPY"
-  press the 'clear' key to reset the screen


For general guidance on DevOps for z/OS see https://ibm.github.io/z-devops-acceleration-program/

For those new to CICS/DB2 concepts, the readme in this repo's [WaaS_Setup](WaaS_Setup/readme.md) folder describes the concepts, terminology and steps required to install a new mainframe application.  

  
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
