# Run newcopy and bind rom IDz  
# In IDz DBB 'preferences/groovy prefix' add this line 
#    "sh /u/ibmuser/dbb-zappbuild/scripts/cics-newcopy.sh &; groovyz  -DBB_DAEMON_HOST 127.0.0.1 -DBB_DAEMON_PORT 8180 "

# See db2 bind jcl example in 'IBMUSER.INITVSI.EPSBIND' 

# do twice to be sure and cheat using install 

sleep 3
opercmd 'F CICSTS61,CEDA INSTALL GROUP(EPSMTM)' > /dev/null

sleep 10
opercmd 'F CICSTS61,CEDA INSTALL GROUP(EPSMTM)' > /dev/null
