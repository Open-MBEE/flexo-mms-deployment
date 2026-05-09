=================
FLexo MMS Store Service
=================

This service helps large Flexo MMS load operations by saving a large file to s3 compliant storage, and returning the url for Flexo MMS layer 1 service to issue a SPARQL LOAD operation on. (It also depends on the performance of the underlying quad store load operation)

S3 Config Options
--------------------

  S3_REGION

    | `Default: us-gov-west-1`

  S3_BUCKET

    | `Default: load`

  S3_ENDPOINT
    Endpoint of s3 compliant service

  AWS_ACCESS_KEY_ID
    S3 credential

  AWS_SECRET_ACCESS_KEY
    S3 credential

If AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are not defined, it'll follow the AWS default credentials provider chain, details at https://docs.aws.amazon.com/sdk-for-java/latest/developer-guide/credentials-chain.html

Service Config Options
-----------------------

  PORT
    Port to run on

    | `Default: 8080`

  JWT_DOMAIN
    This should be the same as what's configured for Flexo MMS Auth Service

    | `Default: https://jwt-provider-domain/`

  JWT_AUDIENCE
    This should be the same as what's configured for Flexo MMS Auth Service

    | `Default: jwt-audience`

  JWT_REALM
    This should be the same as what's configured for Flexo MMS Auth Service

    | `Default: Flexo MMS Microservices`

  JWT_SECRET
    This should be the same as what's configured for Flexo MMS Auth Service

    | `Default: secret123`
