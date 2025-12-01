pipeline {
    agent any

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

        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve'
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
                    echo 'Nginx is up!'
                    """
                }
            }
        }
    }
}
