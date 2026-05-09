Flexo MMS Layer 1 Service
=====================

This service provides the main api for Flexo MMS. It will need a SPARQL 1.1 compliant quadstore as a backend.

Other supporting MMS 5 services such as the Auth and Load service can be used to provide authentication and large model loads. Please see their respective documentation on matching configurations.

Quadstore Configs
--------------------------

  PORT
    Port to run on

    | `Default: 8080`

  FLEXO_MMS_QUERY_URL
    SPARQL endpoint URL for read queries

    | `Default: https://quad-store-domain-ro/sparql`

  FLEXO_MMS_MASTER_QUERY_URL
    Optional SPARQL endpoint URL to use when querying for latest data (only needed when backend has separate reader/writer instances).1
    If omitted, application will default to using the configured SPARQL endpoint for queries.

    | `Default: (empty)`

  FLEXO_MMS_UPDATE_URL
    SPARQL endpoint URL for updates

    | `Default: https://quad-store-domain/sparql`

  FLEXO_MMS_GRAPH_STORE_PROTOCOL_URL
    SPARQL Graph Store Protocol (GSP) endpoint URL

    | `Default: https://quad-store-domain/sparql/gsp`

Services Configs
-----------------------

  FLEXO_MMS_STORE_SERVICE_URL
    Optional. If using the store service, provide its URL here (if not given, load operations will use the GSP endpoint). URL should be in the form <Store service domain and port>/store

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

    | `Default: test1234`

Other Configs
---------------------

  FLEXO_MMS_ROOT_CONTEXT
    This should be the same context url as given to the initialization script.

    | `Default: http://layer1-service`

  FLEXO_MMS_GLOMAR_RESPONSE
    If true, respond with 404 to unauthorized requests, even when a resource exists (neither confirming nor denying its existence)

    | `Default: true`

  FLEXO_MMS_MAXIMUM_LITERAL_SIZE_KIB
    Large patch strings above this threshold size will not be stored in the triplestore. if unset, no limit on literal size enforced

    | `Default: 61440`

  FLEXO_MMS_GZIP_LITERALS_LARGER_THAN_KIB
    Patch strings above this threshold size will be gzipped when stored in the triplestore. if unset, will not attempt to gzip any strings

    | `Default: 512`

  FLEXO_MMS_SPARQL_REQUEST_TIMEOUT
    Timeout per request sent to the triplestore, in seconds.

    | `Default: 1800`

Generate the initialization file
--------------------------------

The quadstore needs to be initialized with configuration data before it can be used. This data is unique to a deployment and needs a context.

To generate the init file, checkout https://github.com/Open-MBEE/flexo-mms-layer1-service and do the following:

.. code:: bash

   cd deploy
   npx ts-node src/main.ts $APP_URL > cluster.trig

Where ``$APP_URL`` is the root URL for where the Flexo MMS Layer 1 instance is deployed, e.g., ``https://mms.openmbee.org``. For local development, we simply use the stand-in ``http://layer1-service``.

This context is also important in the configuration of other Flexo MMS services like the Auth service - the context needs to match.

If there is a specific user or group that should be the cluster admin, edit the trig file so their iri is part of the super admins policy. See Flexo MMS Auth Service documentation for more details.

Apply the initialization file
-----------------------------

Once the initialization file has been generated at ``cluster.trig``, apply this file to your empty quadstore (for example, by using its Graph Store Protocol API to insert the data) before using Flexo MMS.

Performance Considerations
--------------------------

Writing to a triplestore can impact query performance significantly. For production deployments with moderate to high load, we recommend using a dedicated write node and separate read-only nodes for the triple store.

The service configuration supports this architecture through the following settings:

- ``FLEXO_MMS_UPDATE_URL``: Points to your dedicated write node
- ``FLEXO_MMS_QUERY_URL``: Points to your read-only node(s)
- ``FLEXO_MMS_MASTER_QUERY_URL``: Optional endpoint for when you need the most up-to-date data (typically points to the write node)

With this configuration:

1. All write operations (updates, deletes) will be directed to the dedicated write node
2. Most read operations (queries) will be directed to the read-only node(s)
3. When absolute consistency is required, queries will use the master query URL

This separation provides several benefits:

- Improved query performance by offloading read traffic from the write node
- Better write throughput by dedicating resources to write operations
- Horizontal scalability by adding more read nodes as query demand increases
- Improved reliability as read operations can continue even if the write node is under heavy load

For smaller deployments with limited traffic, a single node configuration may be sufficient, but as your model size and user base grow, the separated architecture becomes increasingly important.

API
---------

See API documentation at https://www.openmbee.org/flexo-mms-layer1-openapi/, generated from https://github.com/Open-MBEE/flexo-mms-layer1-openapi
