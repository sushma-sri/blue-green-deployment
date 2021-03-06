pipeline{
    agent any
    stages{
        stage('Lint HTML') {
            steps {
                sh 'tidy -q -e app/*.html'
            }
        }
        stage('Build Docker Image') {
           steps {
                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD']]){
                    sh '''
                        docker build --no-cache -t sushmasri/capstonerepository:latest .
                    '''
                }

            }
        }
        stage('Push Docker Image') {
           steps {
                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD']]){
                    sh '''
                        docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
                        docker push sushmasri/capstonerepository:latest
                    '''
                }
            }
        }
        stage('Set Kubectl Context to Cluster') {
            steps{
                sh 'kubectl config use-context arn:aws:eks:ap-southeast-2:048353547478:cluster/capstonecluster'
            }
        }

        stage('Create Staging Controller') {
            steps{
                withAWS(region:'ap-southeast-2',credentials:'aws-static') {
                    sh 'kubectl apply -f ./staging-controller.json'

                }
            }
        }
        stage('Rollout Staging Changes') {
            steps{
                withAWS(region:'ap-southeast-2',credentials:'aws-static') {
                    sh 'kubectl rolling-update staging --image=sushmasri/capstonerepository:latest'
                }
            }
        }
        stage('Create Staging service') {
            steps{
                withAWS(region:'ap-southeast-2',credentials:'aws-static') {
                    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD']]){
                        sh 'docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD'
                        sh 'kubectl apply -f ./staging-service.json'
                        sh 'kubectl get pods'
                        sh 'kubectl describe service staginglb'
                    }
                }
            }
        }
        stage('Deploy to Production?') {
              when {
                expression { env.BRANCH_NAME != 'master' }
              }

              steps {
                milestone(1)
                input 'Deploy to Production?'
                milestone(2)
              }
        }
        stage('Create Blue Controller') {
            when {
                expression { env.BRANCH_NAME == 'blue' }
            }
            steps{
                withAWS(region:'ap-southeast-2',credentials:'aws-static') {
                    sh 'kubectl apply -f ./blue-controller.json'

                }
            }
        }
        stage('Create Green Controller') {
            when {
                expression { env.BRANCH_NAME == 'green' }
            }
            steps{
                withAWS(region:'ap-southeast-2',credentials:'aws-static') {
                    sh 'kubectl apply -f ./green-controller.json'

                }
            }
        }
        stage('Rollout Blue Changes') {
            when {
                expression { env.BRANCH_NAME == 'blue' }
            }
            steps{
                withAWS(region:'ap-southeast-2',credentials:'aws-static') {
                    sh 'kubectl rolling-update blueversion --image=sushmasri/capstonerepository:latest'
                }
            }
        }
        stage('Rollout Green Changes') {
            when {
                expression { env.BRANCH_NAME == 'green' }
            }
            steps{
                withAWS(region:'ap-southeast-2',credentials:'aws-static') {
                     sh 'kubectl rolling-update greenversion --image=sushmasri/capstonerepository:latest'
                }
            }
        }
        stage('Create Blue-Green service') {
            when {
                expression { env.BRANCH_NAME != 'master' }
            }
            steps{
                withAWS(region:'ap-southeast-2',credentials:'aws-static') {
                    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD']]){
                        sh 'docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD'
                        sh 'kubectl apply -f ./blue-green-service.json'
                        sh 'kubectl get pods'
                        sh 'kubectl describe service bluegreenlb4'
                    }
                }
            }

        }
    }
}
