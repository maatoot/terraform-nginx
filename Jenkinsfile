pipeline {
    agent any

    environment {
        CREDS = credentials('aws-creds')
        AWS_DEFAULT_REGION = "eu-west-1"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/maatoot/terraform-nginx.git'
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Clean State') {
            steps {
                // إزالة IGW القديم من الـ state
                sh '''
                terraform state rm aws_internet_gateway.igw || true
                '''
            }
        }

        stage('Terraform Apply') {
            steps {
                sh '''
                export AWS_ACCESS_KEY_ID=$CREDS_USR
                export AWS_SECRET_ACCESS_KEY=$CREDS_PSW
                terraform apply -auto-approve
                '''
            }
        }

        stage('Wait for Nginx') {
            steps {
                script {
                    def ip = sh(script: "terraform output -raw instance_public_ip", returnStdout: true).trim()
                    sh """
                    echo 'Waiting for Nginx on ${ip}...'
                    until curl -s http://${ip} >/dev/null 2>&1; do
                      sleep 10
                    done
                    echo 'Nginx is up and running on ${ip}!'
                    """
                }
            }
        }
    }
}
