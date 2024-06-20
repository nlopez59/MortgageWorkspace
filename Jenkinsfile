// Sample Jenkinsfile using pGH, ssh and a waas for dxc poc  (Nlopez)
// for help: https://www.jenkins.io/doc/book/pipeline/jenkinsfile/
// Note: can double ref a $ var in the the arc step  
 
// The zOS Jenkins in-bound Agent name
def myAgent  = 'dxc'
 
//* The app repo abd DBB args - test with https 

//* Careful not to add leading spaces
def repo = 'https://github.com/nlopez1-ibm/MortgageWorkspace.git'
//def repo = 'git@github.com:gandalf68000/MortgageWorkspace.git'
 
def appworkspace = 'MortgageWorkspace'
def appname = 'MortgageApplication'
//def branch = 'dxcBranch01' 
def branch = 'dxc' 

// Location of the DBB build script
def dbbbuild ='/u/ibmuser/dbb-zappbuild/build.groovy'
 
 
// Location of UCD agent and application component name
def ucdPublish = '/u/ibmuser/dbb-zappbuild/scripts/CD/UCD_Pub.sh'
def buzTool  = '/u/ibmuser/ibm-ucd/bin/buztool.sh'
def ucdComponent = 'dxc-component'
 
 
 
pipeline {
    agent   { label myAgent }
    options { skipDefaultCheckout(true) }      
    stages  {
        stage('Pre Actions') {
            steps {
                script {                                        
                    echo "Pre-Step: Cleaning up old logs and set woriking Dir ..."                                        
                    sh "set +x; ls  -tD  |  awk 'NR>3'  |  xargs -L1 rm -Rf  "
 
                    env.wkSpace = "${WORKSPACE}/build_${BUILD_NUMBER}/${appworkspace}"
                    echo "Set Env Var wkSpace=${env.wkSpace}"
                }
            }
        }
        stage('Clone') {
            steps {
                println '** Cloning ' + repo + ' Branch dxc ...'
                script {                                        
                    sh """
                        set +x
                        . /etc/profile
                        mkdir -p "build_${BUILD_NUMBER}"
                        cd "build_${BUILD_NUMBER}"
                        git clone "${repo}" 
                    """
                }
            }          
        }  
 
        stage('Build') {
            steps {
                println  "** Building with DBB ... "
                script {
                    sh """
                        set +x
                        . /etc/profile
                        groovyz  -DBB_DAEMON_HOST 127.0.0.1 -DBB_DAEMON_PORT 8180 ${dbbbuild} -w ${env.wkSpace}  -a ${appname}  -o ${env.wkSpace} -l UTF-8  -h DBB.POC --impactBuild                        
                    """                
                }
            }
        }
 
        stage('Stage for Deploy') {
            steps {
                println  '** Publishing to UCD ...'                  
                script {    
                    sh ucdPublish + " Jenkins_Build_${BUILD_NUMBER} " + ucdComponent +  " ${env.wkSpace}"                                      
                }                
            }
        }        
    }  
   
    post {
            always {                                
                echo "Post step: Uploading DBB Logs and UCD Ouptut ... "                              
                archiveArtifacts artifacts: "build_${BUILD_NUMBER}/**/**.log",  fingerprint: false                              
                archiveArtifacts artifacts: "build_${BUILD_NUMBER}/**/**.output",  fingerprint: false                              
 
               // Sample newcopy during builds  
               // echo 'CICS Newcopy and uploading Logs ...'                    
               // sh """
               //     set +x
               //     . /etc/profile
               //     opercmd "F CICSTS61,CEMT SET PROG(EPSMORT)  PH" > /dev/null 2>&1
               //     opercmd "F CICSTS61,CEMT SET PROG(EPSCMORT) PH" > /dev/null 2>&1
               // """              
            }
    }        
}
 