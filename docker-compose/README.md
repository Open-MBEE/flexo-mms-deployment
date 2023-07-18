# MMS5 docker-compose

## What is this?
This docker-compose will start all services required for all current MMS5 microservices. It utilizes the following open source services in the backend:

- OpenLDAP - for Auth Service
- Apache Fuseki - Quadstore
- MinIO - for Store Service

With these initial services, the docker-compose will then start and connect the following MMS5 microservices:

- MMS5 Auth Service
- MMS5 Store Service
- MMS5 Layer 1 Service

All services will be on a bridged docker network named `mms5-test-network`.

An initial trig file has been pre-generated under `mount/cluster.trig` and will be automatically added to Fuseki when it starts up. This includes policies that adds the default ldap users and group created to be admins.

For MinIO, a client can be installed to inspect objects https://min.io/docs/minio/linux/reference/minio-mc.html?ref=docs

## Default MMS5 Users and Groups
The following user / passwords are created by default:
- `user01` / `password1`
- `user02` / `password2`

## Usage
Install Docker Desktop from https://www.docker.com/

Run `docker-compose up` in this directory, once something like the following appears, the MMS5 api should be ready.

    layer1-service   | 2023-07-09T21:39:48,468Z [main] INFO  Application - Responding at http://0.0.0.0:8080

The first step will be the retrieve an authentication token from the auth-service, with `password1`. 

`curl -u user01 -X GET http://localhost:8082/login`

You can now use the token returned as a bearer token for all subsequent mms5-layer1 api calls to http://localhost:8080, for api documentation, see https://www.openmbee.org/mms5-layer1-openapi/

An example Postman collection is available in this directory that demonstrates basic api usage. Download the Postman app from https://www.postman.com/ and import the collection file to use.

## Connecting Jupyter Notebook Quick Start

    docker run -p 8888:8888 --network=mms5-test-network jupyter/scipy-notebook:latest

Example of using python `requests` lib to call the login url (note the host should be the host defined in the docker-compose file)

```python
import requests
from requests.auth import HTTPBasicAuth
response = requests.get("http://auth-service:8080/login", auth=HTTPBasicAuth('user01', 'password1'))
print(response.json())
```

## Potential Errors

You may see an error related to the `store-service` such that it doesn't start up (we believe this is due to issues with docker on m1/m2 mac). If this happens, the `store-service` is optional and can be taken out entirely. To remove it, remove the following lines and restart the compose:

- `MMS5_LOAD_SERVICE_URL=http://store-service:8080/store` in env/mms5-layer1.env

- `store-service` under `depends_on:` in the docker-compose.yml file for layer1-service

## Shutdown
`Ctrl-C` from the terminal and run `docker-compose down` once all containers are shut down.
