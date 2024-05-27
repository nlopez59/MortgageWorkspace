#!/bin/sh
# mod njl 4/21/24 - dual mode Artifactory or CodeStation for Demos 
# Tested on UCD Server ver  7.2.1.2.1127228
# buztool Ref: https://www.ibm.com/docs/en/devops-deploy/7.2.1?topic=czcv-creating-zos-component-versions-from-zos-unix-system-services
# Jfrog repo https://eu.artifactory.swg-devops.com/ui/repos/tree/General/sys-dat-team-generic-local/Azure/poc-workspace

. /etc/profile

ucd_version=$1
ucd_Component_Name=$2
MyWorkDir=$3
ArtifactoryMode=$4

buzTool=~/ibm-ucd/agent/bin/buztool.sh
pub=$DBB_HOME/dbb-zappbuild/scripts/UCD/dbb-ucd-packaging.groovy  

# setup jFrog args.  Dont use codeStation for now 4/13/24  
artProp=""
if [ -z "$ArtifactoryMode" ]; then 
    artStore="UCD CodeStation"     
else
    artStore="jFroj_v2Pack" 
    artProp=" -prop $MyWorkDir/artifactoryProps  -ppf $MyWorkDir/artifactoryMapping --ucdV2PackageFormat"    
fi

## DEBUG ??? not sure above --ucdv2 var ... 

echo "**************************************************************"
echo "**  Started:  UCD_Pub.sh (V3b) Pack&Pub on HOST/USER: $(uname -Ia) $USER"
echo "**                           Version/Build_ID:" $ucd_version
echo "**                                 Component:" $ucd_Component_Name 
echo "**                                   workDir:" $MyWorkDir   
echo "**                              BuzTool Path:" $buzTool 
echo "**                          Packaging Script:" $pub 
echo "**                            Artifact Store:" $artStore                   

cli="sh groovyz $pub  --buztool $buzTool --workDir $MyWorkDir  --component $ucd_Component_Name --versionName $ucd_version $artProp"
echo "UCD_Pub.sh running groovy cli:"
echo " " $cli
#$cli 

groovyz $pub  --buztool $buzTool --workDir $MyWorkDir  --component $ucd_Component_Name --versionName $ucd_version $artProp

# groovyz $pub --buztool $buzTool  --workDir $MyWorkDir --component $ucd_Component_Name --versionName 135_20220531.113630.036   $artProp
exit $?
