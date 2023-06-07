MMS 5 Layer 1
=============

|CircleCI|

This project is currently under development. This document describes how
to set up a local dev environment.

Setting up local dev environment
--------------------------------

You will need to run a local quadstore. There are a few other
complementary services that help with authentication and uploading RDF
data, but they are not strictly required (i.e., the stack *can* operate
without them, but may require special configuration or in some cases may
impact performance).

Run the service set
~~~~~~~~~~~~~~~~~~~

Therefore, the simplest way to get started is to stand up the prescribed
service set:

.. code:: bash

   docker-compose -f src/test/resources/docker-compose.yml up -d

Apache Jena’s Fuseki quadstore will bind locally on port 3030. Should
you want to issue SPARQL queries directly against the quadstore itself,
Fuseki exposes the following HTTP APIs by default:

+-------------------+--------------------------------------------------+
| Endpoint          | Purpose                                          |
+===================+==================================================+
| `                 | `SPARQL 1.1                                      |
| `http://localhost | Query <https://www.w3.org/TR/sparql11-query/>`__ |
| :3030/ds/sparql`` |                                                  |
+-------------------+--------------------------------------------------+
| `                 | `SPARQL 1.1                                      |
| `http://localhost | Up                                               |
| :3030/ds/update`` | date <https://www.w3.org/TR/sparql11-update/>`__ |
+-------------------+--------------------------------------------------+
| ``http://localho  | `SPARQL 1.1 Graph Store                          |
| st:3030/ds/data`` | Protocol <htt                                    |
|                   | ps://www.w3.org/TR/sparql11-http-rdf-update/>`__ |
+-------------------+--------------------------------------------------+

Generate the initialization file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The next step is to populate the quadstore with configuration data since
MMS5 stores all of its state information in the quadstore alongside user
data.

This configuration data is unique to your deployment.

To generate a new deployment configuration:

.. code:: bash

   cd deploy
   npx ts-node src/main.ts $APP_URL > ../src/test/resources/cluster.trig

Where ``$APP_URL`` is the root URL for where the MMS5 Layer 1 instance
is deployed, e.g., ``https://mms5.openmbee.org/``. For local
development, we simply use the stand-in ``http://layer1-service``.

Apply the initialization file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Once the initialization file has been generated at
``src/test/resources/cluster.trig``, this file will automatically be
used when running tests. Otherwise, make sure to apply this file to your
empty quadstore (for example, by using its Graph Store Protocol API)
before using MMS5.

Deploy the MMS5 Layer 1 Application
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Make sure the following environment variables are set when running the
application. If running tests, make sure these variables are set in the
test configuration. These will be picked up by
``src/main/resources/application.conf.*`` which you can also configure
for further customization.

.. code:: shell

   MMS5_ROOT_CONTEXT=http://layer1-service
   MMS5_QUERY_URL=http://localhost:3030/ds/sparql
   MMS5_UPDATE_URL=http://localhost:3030/ds/update
   MMS5_GRAPH_STORE_PROTOCOL_URL=http://localhost:3030/ds/data

.. |CircleCI| image:: https://circleci.com/gh/Open-MBEE/mms5-layer1-service.svg?style=shield
   :target: https://circleci.com/gh/Open-MBEE/mms5-layer1-service
