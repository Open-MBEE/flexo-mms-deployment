Setting up the MMS5-Layer1 Service on Mac
==========================================

This document explains how to set up the local dev environment for Mac machines.

This tutorial assumes that you have already installed Docker, NodeJS and NPX onto your machine.

After pulling this repo into your machine, you will need to go to the directory where the repository is located and run the following command:
::
    docker-compose -f src/test/resources/docker-compose.yml up -d

This will run the service set where you can then issue SPARQL queries directly against the quadstore. After doing this, you will need to run the following commands:
::
    cd deploy
    export APP_URL="http://layer1-service"
    npx ts-node src/main.ts $APP_URL > ../src/test/resources/cluster.trig

In order to run the tests, you can return to your root directory and run the following commands.
::
    cd..
    docker build -t mms5-test:latest -f Dockerfile .
    docker run -p 8080:8080 --name mms5-test-container mms5-test:latest
    docker cp mms5-test-container:/application/build/reports/tests <directory you want to store results>/results
