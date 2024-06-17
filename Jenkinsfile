// Sample Jenkinsfile using pGH, ssh and a waas for dxc poc  (Nlopez)
// for help: https://www.jenkins.io/doc/book/pipeline/jenkinsfile/
// Note: can double ref a $ var in the the arc step  

def myAgent  = 'dxc'
def repo = 'git@github.com:nlopez1-ibm/MortgageWorkspace.git'
def dbbbuild ='/u/ibmuser/dbb-zappbuild/build.groovy'
def appworkspace = 'MortgageWorkspace'
def appname = 'MortgageApplication'



//def ucdPublish = '/u/ibmuser/waziDBB/dbb-v2/dbb-zappbuild/scripts/UCD/dbb-ucd-packaging.groovy' 
def ucdPublish = '/u/ibmuser/dbb-zappbuild/scripts/CD/UCD_Pub.sh'
def buzTool  = '/u/ibmuser/ibm-ucd/bin/buztool.sh'
def ucdComponent = 'dxc-component'

// no changes required to this section 
pipeline {
    agent   { label myAgent } 
    options { skipDefaultCheckout(true) }       
    stages  {
        stage('Pre Actions') {
            steps {
                script {                            
                    // Define an environment variable
                    env.wkSpace = "${WORKSPACE}/build_${BUILD_NUMBER}/${appworkspace}" 
                    echo "Set Env Var wkSpace=${env.wkSpace}"


                    // Remove build across all runs  - keep last 3
                    echo "Cleaning up old logs ..."
                    sh "ls  -tD  |  awk 'NR>3'  |  xargs -L1 rm -Rf  "
                }
            }
        }
        stage('Clone') {
            steps {
                println '** Clone ' + repo + ' Branch dxc ..' 
                script {                                        
                    sh """ 
                        set +x
                        . /etc/profile 
                        mkdir -p "build_${BUILD_NUMBER}"
                        cd "build_${BUILD_NUMBER}"
                        git clone -b dxc "${repo}"
                    """
                }
            }          
        }  

        stage('Build') {
            steps {
                println  "** Building with DBB in Impact Mode ... "
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
                println  '** Publish to UCD ...'                  
                script {     
                    sh ucdPublish + " Jenkins_Build_${BUILD_NUMBER} " + ucdComponent +  "${env.wkSpace}"                                      
                } 
                
                // archiveArtifacts artifacts: "/"+"${WORKSPACE}"+"/"+"${wkSpace}"+"/"+"${appworkspace}"+"/*.output"
            }
        }        
    }   
    
    post {
            always {                                
                echo "Post step: Uploading Logs ...  ${env.wkSpace}"               
                archiveArtifacts artifacts: "${env.wkSpace}/**.log",  fingerprint: false                               
                
               // Sample newcopy during builds  
               // echo 'CICS Newcopy and uploading Logs ...'                    
               // sh """
               //     set +x
               //     . /etc/profile 
               //     opercmd "F CICSTS61,CEMT SET PROG(EPSMORT)  PH" > /dev/null 2>&1
               //     opercmd "F CICSTS61,CEMT SET PROG(EPSCMORT) PH" > /dev/null 2>&1
               // """
               //archiveArtifacts artifacts: '${WORKSPACE}/${wkSpace}/${appworkspace}/*.log', fingerprint: false  
            }
    }        
}
