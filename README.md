<p align="center">
  <a href="https://www.openmbee.org/">
    <img alt="OpenMBEE" src="https://raw.githubusercontent.com/Open-MBEE/openmbee-graphic-assets/main/Logo/openmbee-logo%20Light.svg" width="360">
  </a>
</p>

<h1 align="center">Flexo MMS Deployment</h1>

<p align="center">
  Deployment examples and local development entry points for the Flexo Model Management System.
</p>

<p align="center">
  <a href="https://flexo-mms-deployment-guide.readthedocs.io/en/latest/index.html">
    <img alt="Documentation" src="https://img.shields.io/badge/docs-ReadTheDocs-8CA1AF">
  </a>
  <a href="https://github.com/Open-MBEE/flexo-mms-deployment/actions/workflows/docs.yml">
    <img alt="Docs workflow" src="https://github.com/Open-MBEE/flexo-mms-deployment/actions/workflows/docs.yml/badge.svg">
  </a>
  <a href="https://github.com/Open-MBEE/flexo-mms-deployment/blob/develop/LICENSE">
    <img alt="License" src="https://img.shields.io/github/license/Open-MBEE/flexo-mms-deployment">
  </a>
  <a href="https://github.com/Open-MBEE/flexo-mms-deployment/issues">
    <img alt="Issues" src="https://img.shields.io/github/issues/Open-MBEE/flexo-mms-deployment">
  </a>
</p>

## What is this repository?

This repository contains sample deployment files for running Flexo MMS with Docker Compose or Kubernetes.

Flexo MMS is OpenMBEE's Model Management System. It provides services for managing models and versioning model data, with native RDF support.

For the full deployment guide, see the [Flexo MMS documentation](https://flexo-mms-deployment-guide.readthedocs.io/en/latest/index.html).

## Quickstart

The fastest way to start the local service set is Docker Compose:

```sh
cd docker-compose
docker compose up -d
curl -u user01:password1 http://localhost:8082/login
```

The login request should return a JSON response containing a bearer token. Use that token with the Flexo MMS Layer 1 API at `http://localhost:8080`.

To stop the local stack:

```sh
docker compose down
```

For more details, see the [Docker Compose README](docker-compose/README.md).

## Services

The default Docker Compose stack starts the backing services and Flexo MMS microservices needed for a local deployment:

| Service | Purpose |
| --- | --- |
| OpenLDAP | Demo users and groups for authentication |
| Apache Fuseki | Quad store for model and access-control data |
| MinIO | S3-compatible artifact storage |
| Flexo MMS Auth Service | Authentication token service |
| Flexo MMS Store Service | Artifact storage service |
| Flexo MMS Layer 1 Service | Main model management API |

Default demo users are documented in the [Docker Compose README](docker-compose/README.md#default-flexo-mms-users-and-groups).

For service-specific configuration details, see the hosted docs for the
[Layer 1 Service](https://flexo-mms-deployment-guide.readthedocs.io/en/latest/flexo-mms-layer1-service/index.html),
[Auth Service](https://flexo-mms-deployment-guide.readthedocs.io/en/latest/flexo-mms-auth-service/index.html),
and [Store Service](https://flexo-mms-deployment-guide.readthedocs.io/en/latest/flexo-mms-store-service/index.html).

## Repository layout

| Path | Description |
| --- | --- |
| [`docker-compose/`](docker-compose/) | Local Docker Compose deployment, environment files, seed data, and API examples |
| [`k8s/`](k8s/) | Kubernetes manifests for Flexo MMS services and configuration |
| [`local/`](local/) | Source files for the hosted deployment documentation |

## API examples

The Docker Compose directory includes API examples for exercising a local Flexo MMS deployment:

- [Bruno collection](docker-compose/Flexo%20MMS%20Local%20Example%20Bruno/)
- [Postman collection](docker-compose/Flexo%20MMS%20Local%20Example.postman_collection.json)

Layer 1 API documentation is available at the [Flexo MMS Layer 1 OpenAPI site](https://www.openmbee.org/flexo-mms-layer1-openapi/).

## Contributing

Documentation fixes, deployment clarifications, and improvements to the local development workflow are welcome. If you are new to the project, useful first contributions include:

- verifying quickstart commands on your platform
- improving troubleshooting notes for Docker Compose or Kubernetes
- adding small API examples for common local workflows
- clarifying configuration values in the deployment files

For more about the community, see [OpenMBEE participation resources](https://www.openmbee.org/participate.html).
