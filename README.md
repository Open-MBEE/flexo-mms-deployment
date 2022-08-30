# mms5-k8s
YAML files for deployment of MMS5 services in k8s

This repository is to assist in deploying MMS5 Microservices on kubernetes clusters. SSL is enabled on the ingress, so a valid cert is necessary in secrets/mms5-cert.yaml. All other options configurations are provdied as ConfigMaps, which will need to be updated before deployment as well.
