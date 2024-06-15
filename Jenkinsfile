// Sample Jenkinsfile using pGH, ssh and a waas for dxc poc  (Nlopez)
// for help: https://www.jenkins.io/doc/book/pipeline/jenkinsfile/

def myAgent  = 'dxc'
def wkDir = 'build_${BUILD_NUMBER}'
def repo = 'git@github.com:nlopez1-ibm/MortgageWorkspace.git'
def dbbbuild ='/u/ibmuser/dbb-zappbuild/build.groovy'
def appworkspace = 'MortgageWorkspace'
def appname = 'MortgageApplication'


//def ucdPublish = '/u/ibmuser/waziDBB/dbb-v2/dbb-zappbuild/scripts/UCD/dbb-ucd-packaging.groovy' 
def ucdPublish = '/u/ibmuser/dbb-zappbuild/scripts/CD/UCD_Pub.sh'
def buzTool  = '/u/ibmuser/ibm-ucd/agent/bin/buztool.sh'
def ucdComponent = 'poc-component'

// no changes required to this section 
pipeline {
    agent   { label myAgent } 
    options { skipDefaultCheckout(true) }       
    stages  {
        stage('Pre Actions') {
            steps {
                script {
                    // Run your shell commands here
                    sh """ 
                    echo "Cleaning up old logs ..."
                    rm -rf *
                    ls -las                    
                    """
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
                        mkdir -p "${wkDir}"                         
                        cd "${wkDir}"
                        git clone -b dxc "${repo}"
                    """
                }
            }          
        }  

        stage('Build') {
            steps {
                println  '** Building with DBB in Impact Mode ...'                  
                script { 
                    sh '. /etc/profile ;  groovyz -DBB_DAEMON_HOST 127.0.0.1 -DBB_DAEMON_PORT 8180 ' + dbbbuild + ' -w ${WORKSPACE}/'+wkDir+'/'+appworkspace  + ' -a ' + appname + ' -o ${WORKSPACE}/'+wkDir+'/'+appworkspace + ' -l UTF-8  -h DBB.POC --impactBuild'                                    
                }
            }
        }

        stage('Stage for Deploy') {
            steps {
                println  '** Package and Publish to UCDs CodeStation...'                  
                script {
                    // sh 'groovyz ' + ucdPublish + ' --buztool ' + buzTool  + ' --workDir ${WORKSPACE}/'+appworkspace + ' --component ' + ucdComponent + ' --versionName ${BUILD_NUMBER}'
                    //sh  ucdPublish + ' Jenkins_Build_${BUILD_NUMBER} ' + ucdComponent + ' ${WORKSPACE}/'+appworkspace  
                    echo 'UCD Disabled for now'
                } 
            }
        }        
    }   
    
    post {
            always {
                echo 'CICS Newcopy and uploading Logs ...'                    
                sh ". /etc/profile ;  opercmd 'F CICSTS61,CEMT SET PROG(EPSMORT) PH' > /dev/null 2>&1"
                sh ". /etc/profile ;  opercmd 'F CICSTS61,CEMT SET PROG(EPSCMORT) PH'> /dev/null 2>&1"
                archiveArtifacts artifacts: '**/*.log', fingerprint: false                                
                }
    }        
}
