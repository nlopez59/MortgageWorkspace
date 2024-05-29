// Sample Jenkinsfile for WaaS POC's (Nlopez)
// for help: https://www.jenkins.io/doc/book/pipeline/jenkinsfile/
 
// Change these values to match your configuration
// The UCD stage is not configured.

def myAgent  = 'yourJenkinsAgent???'
def repo = 'git@???/MortgageWorkspace.git'

def dbbbuild ='/u/ibmuser/dbb-zappbuild/build.groovy'
def appworkspace = 'MortgageWorkspace'
def appname = 'MortgageApplication'

// a sample groovy script to package dbb artifacts an publish to UCD for deploy. Pending configuration 
def ucdPublish = '/u/ibmuser/dbb-zappbuild/scripts/CD/UCD_Pub.sh'

def buzTool  = '/u/ibmuser/???/agent/bin/buztool.sh'
def ucdComponent = '???'

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

        stage('Stage for Deploy- on HOLD ') {
            steps {
                println  '** Package and Publish to UCDs CodeStation...'                  
                script {
                   echo "NOP" 
                   //sh  ucdPublish + ' Jenkins_Build_${BUILD_NUMBER} ' + ucdComponent + ' ${WORKSPACE}/'+appworkspace  
                } 
            }
        }        
    }   
    
    post {
            always {
                echo 'Saving DBB Build Logs ...'
                archiveArtifacts artifacts: '**/*.log', fingerprint: false                
                }
    }        
}
