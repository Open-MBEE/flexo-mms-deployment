# mms5 docker-compose

## What is this?
This docker-compose will start all services required for all current MMS5 microservices. It utilizes the following open source services in the backend:

- OpenLDAP
- Apache Fuseki
- MinIO

With these initial services, the docker-compose will then start and connect the following MMS5 microservices:

- MMS5 Auth Service
- MMS5 Store Service
- MMS5 Layer 1 Service

All services will be on a bridged docker network named `mms5-network`. 

## Default MMS5 Users and Groups
The following user / passwords are created by default:
- `user01` / `password1`
- `user02` / `password2`

## MMS5 Authenticating

The first step will be the retrieve an authentication token from the auth-service. 

`curl -u user01 -X GET http://$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' auth-service):8080/login`