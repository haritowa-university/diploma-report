pipeline {
    agent any
    stages {
        stage('Parse config') {
            steps {
                script {
                    configData = readYaml file: env.CONFIG_FILE

                    env.ROOT_TEX_PATH = configData.root_tex_path ?: 'tex'
                    env.SECTIONS_PATH = configData.sections_path ?: 'sections'
                    env.PREAMBLE_CUSTOMIZATION_FILE = configData.preamble_customization_file ?: 'preamble-customization.tex'
                    env.BIBLIOGRAPHY_DB = configData.bibliographa_db ?: "bibliography_database"

                    def rawAdditionalIputs = configData.additional_inputs ?: ["title", "abstract", "table_of_contents", "glossary"]
                    env.ADDITIONAL_INPUTS = rawAdditionalIputs.join(' ')

                    echo env.ROOT_TEX_PATH
                    echo env.SECTIONS_PATH
                    echo env.PREAMBLE_CUSTOMIZATION_FILE
                    echo env.BIBLIOGRAPHY_DB
                    echo env.ADDITIONAL_INPUTS
                }
            }
        }
        stage('Preapre build folder') {
            steps {
            	sh 'rm -rf ${HOME}/bsuir-jenkins/build-result'
                sh 'mkdir -p ${HOME}/bsuir-jenkins/build-result'
            }
        }
        stage('Build') {
            agent {
                docker {
                    image 'haritowa/bsuir-latex-build-system:0.0.3'
                    args '-v ${HOME}/bsuir-jenkins/build-result:/build-result -u root'
                }
            }
            steps {
                sh 'cp -r /container/* .'
                sh 'cp -r stp/* $ROOT_TEX_PATH/'

                sh './latex-project-builder -r ${ROOT_TEX_PATH} -s ${SECTIONS_PATH} -p ${PREAMBLE_CUSTOMIZATION_FILE} -b ${BIBLIOGRAPHY_DB} -i ${ADDITIONAL_INPUTS}'

                // Stupid jenkins bug with dir inside docker container
                script {
                    try {
                        sh 'cd $ROOT_TEX_PATH && $PDFLATEX $MAINTEX'
                    }
                    catch(err) {
                        
                    }
                }

                sh 'cd $ROOT_TEX_PATH && makeglossaries $MAINTEX'
                sh 'cd $ROOT_TEX_PATH && bibtex $MAINTEX'

                script {
                    try {
                        sh '''cd $ROOT_TEX_PATH && $PDFLATEX $MAINTEX > /dev/null
                    $PDFLATEX $MAINTEX'''
                    }
                    catch(err) {
                        
                    }
                }


                sh 'cp $ROOT_TEX_PATH/$MAINTEX.pdf /build-result/$RESULT_PDF_NAME'
            }
        }
        stage('Cleanup') {
            steps {
                sh 'find -E $ROOT_TEX_PATH/ -maxdepth 1 -type f ! -regex ".*\\.(tex|log|blg|bib|cls|sty|bst|clo|asm|gitignore)" -exec rm -f {} \\; ;'
            }
        }
        stage('Release') {
            environment {
                newBuild = "${BRANCH_NAME}(${BUILD_NUMBER}).pdf"
                dropboxFolder = "build/${BRANCH_NAME}"
                dropboxURL = "$DROPBOX_ROOT_URL/${dropboxFolder}"
                buildResultPath = "${HOME}/bsuir-jenkins/build-result/${RESULT_PDF_NAME}"
            }
            steps {
            	sh 'cp ${buildResultPath} ${newBuild}'
                archiveArtifacts newBuild
                
                script {
                    if (env.DROPBOX_CONFIG_NAME != null) {
                        dropbox(sourceFiles: newBuild, remoteDirectory: dropboxFolder, configName: env.DROPBOX_CONFIG_NAME)
                    } else {
                        echo "Dropbox config name is not specified, skip upload step"
                    }
                }
            }
        }
    }
    environment {
        CONFIG_FILE = 'bsuir_build_config.yml'
        MAINTEX = 'compiled'
        PDFLATEX = 'pdflatex -interaction=nonstopmode -shell-escape -file-line-error'
        RESULT_PDF_NAME = 'result.pdf'

        // Insert yor config name to enable dropbox upload
        DROPBOX_CONFIG_NAME = 'diploma'
        DROPBOX_ROOT_URL = 'https://www.dropbox.com/home/Diploma/note'
    }
}
