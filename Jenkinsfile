pipeline{
    agent{
        node{
            label "Slave-1"
            customWorkspace "/home/k8s-management/3tierapp/"
        }
    }
    environment {
        JAVA_HOME="/usr/lib/jvm/java-17-amazon-corretto.x86_64"
        PATH="$PATH:$JAVA_HOME/bin:/usr/local/bin:/opt/apache-maven/bin:/opt/node-v16.0.0/bin"
    }
    parameters { 
        string(name: 'COMMIT_ID', defaultValue: '', description: 'Provide the Commit ID') 
        string(name: 'REPO_NAME', defaultValue: '', description: 'Provide the Repository Name')
        string(name: 'TAG_NAME', defaultValue: '', description: 'Provide the Tag Name')
        string(name: 'REPLICA_COUNT', defaultValue: '', description: 'Provide the Replica Count')
    }
    stages{
        stage("Clone-code"){
            steps{
                cleanWs()
                checkout scmGit(branches: [[name: '${COMMIT_ID}']], extensions: [], userRemoteConfigs: [[credentialsId: 'github-cred', url: 'https://github.com/singhritesh85/Three-tier-WebApplication.git']])
            }
        }
        stage("SonarQubeAnalysis-and-Build"){
            steps {
                withSonarQubeEnv('SonarQube-Server') {
                    sh 'mvn clean package sonar:sonar'
                }
            }
        }
        stage("Quality Gate") {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
        //            waitForQualityGate abortPipeline: false, credentialsId: 'sonarqube'
                }
            }
        }
        stage("Nexus-Artifact Upload"){
            steps{
                script{
                    def mavenPom = readMavenPom file: 'pom.xml'
                    def nexusRepoName = mavenPom.version.endsWith("SNAPSHOT") ? "maven-snapshot" : "maven-release"
                    nexusArtifactUploader artifacts: [[artifactId: 'vprofile', classifier: '', file: 'target/vprofile-v2.war', type: 'war']], credentialsId: 'nexus', groupId: 'com.visualpathit', nexusUrl: 'nexus.singhritesh85.com', nexusVersion: 'nexus3', protocol: 'https', repository: "${nexusRepoName}", version: "${mavenPom.version}"
                }    
            }
        }
        stage("Create docker image, scan it and push to ECR"){
            steps{
                sh '''
                      docker system prune -f --all
                      docker build -t ${REPO_NAME}:${TAG_NAME} .
                      trivy image --exit-code 0 --severity MEDIUM,HIGH ${REPO_NAME}:${TAG_NAME}
                      #trivy image --exit-code 1 --severity CRITICAL ${REPO_NAME}:${TAG_NAME}
                      aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 027330342406.dkr.ecr.us-east-2.amazonaws.com
                      docker push ${REPO_NAME}:${TAG_NAME}
                '''
            }
        }
        stage("Deployment"){
            steps{
                sh 'yes|argocd login argocd.singhritesh85.com --username admin --password Admin123 --grpc-web'
                sh 'argocd app create demo5 --project default --repo https://github.com/singhritesh85/helm-repo-for-ArgoCD.git --path ./folo --dest-namespace three-tier-webapp --sync-option CreateNamespace=true --dest-server https://kubernetes.default.svc --helm-set service.port=80 --helm-set image.repository=${REPO_NAME} --helm-set image.tag=${TAG_NAME} --helm-set replicaCount=${REPLICA_COUNT} --upsert'
                sh 'argocd app sync demo5'
            }
        }
    }
}
