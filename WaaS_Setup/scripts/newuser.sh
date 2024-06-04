#!/bin/sh
# create a new racf user to tso and omvs with ssh key init 
# manual steps:
#  - for ssh access, add users local public ssh key to /u/$uid/.ssh/authorized_keys 
#     >  ssh-keygen -t rsa -b 4096 
#  - for 3270, install local 3270 cert and connect with tls 1.2 on port 922 
#  - for vscode use rseapi with racf user $uid and temp password sys1 

# arg: $1 = user id to create 
. /etc/profile

uid=$1 
if [ -z "$1" ]; then
  echo "newuser.sh: Error  missing RAFC ID ."
  pause 
  exit 
fi  
echo "***   newuser.sh (beta): Creating account for $uid  ***" 
echo " ***" 
sleep 1


tsocmd "AU  $uid NAME(wass_$uid) PASSWORD(SYS1) OWNER(IBMUSER)  TSO(ACCTNUM(ACCT001) PROC(PROC001) JOBCLASS(A) MSGCLASS(H) )  "						
tsocmd "ALU $uid OMVS(AUTOUID HOME("/u/$uid") PROGRAM(/bin/sh) AUTOUID)     "												
tsocmd "PE  PROC001 CLASS(TSOPROC) ID($uid) ACCESS(READ)"						
tsocmd "PE  ACCT001 CLASS(ACCTNUM) ID($uid) ACCESS(READ)"						
tsocmd "SETROPTS RACLIST(TSOPROC TSOAUTH ACCTNUM) REFRESH                    "						
tsocmd "lu $uid tso,omvs"

mkdir -p /u/$uid/.ssh
touch /u/$uid/.ssh/authorized_keys
ssh-keygen  -t rsa -b 4096 -C "$uid@ibm.com"  -f "/u/$uid/.ssh/id_rsa" -q -N ""						

chown -R $uid /u/$uid
chmod -R 700 /u/$uid/.ssh

ls -las /u/$uid 
echo " ***" 

#  ref 
# tsocmd "RDEFINE SURROGAT BPX.SRV.$uid  UACC(READ) "						
# tsocmd "SETROPTS RACLIST(SURROGAT) REFRESH                    "						