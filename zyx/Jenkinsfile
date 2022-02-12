pipeline {
    agent any
    
    environment{
        nombre_imagen = "vincenup/$JOB_NAME"
        mi_imagen = ""
    }

    tools { maven "Maven" }

    stages {
        stage('Check out Repo Git') {
            steps{
                git([url: 'https://github.com/jvinc86/rihanna-java-maven-app.git', branch: 'master'])
            }
        }        
        stage('Buildear Codigo con Maven') {
            steps { sh 'mvn clean package' }
        }
        stage('Construir imagen Docker') {
            steps {
                script{
                    mi_imagen = docker.build nombre_imagen
                }
            }
        }
        stage('Pushar imagen a HubDocker') {
            environment{
                credencialesMiDockerHub = "DockerHub Usuario"
            } 
            steps {           
                script{
                    docker.withRegistry('', credencialesMiDockerHub) {
                        mi_imagen.push("latest")
                        mi_imagen.push("$BUILD_NUMBER")
                    }
                }
            }
        }
        stage('Eliminar imagenes ya pushadas'){
            steps{
                sh 'docker rmi $nombre_imagen:latest'
                sh 'docker rmi $nombre_imagen:$BUILD_NUMBER'
            }
        }
    }
}
