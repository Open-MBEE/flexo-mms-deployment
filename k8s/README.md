# flexo-mms-k8s
YAML files for deployment of Flexo MMS services in k8s

This repository is to assist in deploying Flexo MMS Microservices on kubernetes clusters. SSL is enabled on the ingress, so a valid cert is necessary in secrets/flexo-mms-cert.yaml. All other options configurations are provdied as ConfigMaps, which will need to be updated before deployment as well.

>[/configmaps/dockerhub.yaml](/configmaps/dockerhub.yaml) - Contains credentials necessary to pull the docker images from dockerhub

>[/configmaps/flexo-mms-layer-1-config.yaml](/configmaps/flexo-mms-layer-1-config.yaml) - Contains all configurations necessary for the layer1-service

>[/configmaps/jwt-config.yaml](/configmaps/jwt-config.yaml) - Contains the shared configuration of JSON Web Tokens used for authentication and authorization

>[/configmaps/s3-config.yaml](/configmaps/s3-config.yaml) - Contains configuration of S3 Bucket access, needed by the storage-service

>[/configmaps/ldap-config.yaml](/configmaps/ldap-config.yaml) - Contains configuration of LDAP, needed by the auth-service

>[/configmaps/logback-config.yaml](/configmaps/logback-config.yaml) - Contains the shared logging configuration used by all services
