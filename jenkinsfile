// Sample Jenkinsfile using pGH, ssh and a waas for dxc poc  (Nlopez)
// for help: https://www.jenkins.io/doc/book/pipeline/jenkinsfile/
// testing v2

def myAgent  = 'dxc'
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
    agent  { label myAgent } 
    options { skipDefaultCheckout(true) }
    
    stages {
        stage('Clone') {
            steps {
                println '** Cloning on USS ...'     
                script {
                    sh 'rm -rf *'
                    sh 'git clone ' + repo 
                    sh 'cd ' + appworkspace  + '; git log --graph --oneline --decorate -n 3'
                }
            }          
        }  

        stage('Build') {
            steps {
                println  '** Building with DBB in Impact Mode ...'                  
                script { 
                    sh 'groovyz ' + dbbbuild + ' -w ${WORKSPACE}/'+appworkspace  + ' -a ' + appname + ' -o ${WORKSPACE}/'+appworkspace + ' -l UTF-8   -h ' + env.USER+'.JENKINS' + ' --impactBuild'                
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
                echo 'Saving Logs ...'
                archiveArtifacts artifacts: '**/*.log', fingerprint: false                
                }
    }        
}
