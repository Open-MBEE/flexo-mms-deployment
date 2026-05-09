=================
Flexo MMS Auth Service
=================

This service currently allows Flexo MMS Service clients to authenticate with an ldap server.

Using the GET `/login` endpoint with basic auth will return a JWT bearer token that the client can then use with the rest of Flexo MMS Service endpoints. The username and groups indicated in the token are then used by Flexo MMS layer1 service for authorization. The same namespace and iri must match any policies defined in Flexo MMS layer1.

Example token::

    {
        "aud": "jwt-audience",
        "iss": "https://mms.openmbee.org/",
        "groups": [
            "ldap/group/some.group",
            "ldap/group/some.group2"
        ],
        "exp": 1688671245,
        "username": "ldap/user/someuser"
    }

Example policy with subject in Flexo MMS Layer1 quadstore::

    prefix m-graph: <http://layer1-service/graphs/>
    prefix m-policy: <http://layer1-service/policies/>
    prefix mms: <https://mms.openmbee.org/rdf/ontology/>
    graph m-graph:AccessControl.Policies {
        m-policy:somepolicy a mms:Policy ;
            mms:subject <http://layer1-service/users/ldap/user/someuser> ;
            mms:subject <http://layer1-service/groups/ldap/group/some.group> ;
            mms:role mms-object:Role.AdminRepo ;
            mms:scope <http://layer1-service/orgs/someorg/repos/somerepo> .
    }

Because a user can belong to many groups in ldap, in order to minimize the amount of groups in the token, relevant groups need to be present in the Flexo MMS layer 1 quadstore first::

    prefix mms: <https://mms.openmbee.org/rdf/ontology/>
    prefix m-graph: <http://layer1-service/graphs/>
    prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    graph m-graph:AccessControl.Agents {
        <http://layer1-service/groups/ldap/group/some.group> rdf:type mms:Group ;
	        mms:id "ldap/group/some.group" .
    }

Use environment variables for the options below.

Flexo MMS Config Options
--------------------

  LDAP_GROUP_STORE_URI
    The quadstore sparql endpoint that's also being used by Flexo MMS layer 1 service

    | `Default: http://localhost:8081/bigdata/namespace/kb/sparql`

  LDAP_GROUP_STORE_CONTEXT
    The same context that's configured for Flexo MMS layer 1 service

    | `Default: http://layer1-service/`

  LDAP_USER_NAMESPACE
    The namespace that'll be prepended to the username to create an iri

    | `Default: ldap/user/`

  LDAP_GROUP_NAMESPACE
    The namespace that'll be prepended to group name to create an iri

    | `Default: ldap/group/`


Ldap Connection Configuration Options
--------------------------------------

  LDAP_LOCATION
    The ldap url

    | `Default: ldap://ldap.openmbee.org:636`

  LDAP_BASE
    The ldap base

    | `Default: dc=openmbee,dc=org`

  LDAP_USER_PATTERN
    Ldap user search pattern

    | `Default: uid=%s,ou=users`

  LDAP_GROUP_SEARCH_FILTER
    Ldap filter to groups a user belongs to

    | `Default: (&(objectclass=group)(uniqueMember=%s)(|(%s)))`

  LDAP_GROUP_ATTRIBUTE
    Ldap group attribute

    | `Default: cn`


Service Config Options
-----------------------

  PORT
    Port to run on

    | `Default: 8080`

  JWT_DOMAIN

    | `Default: https://jwt-provider-domain/`

  JWT_AUDIENCE

    | `Default: jwt-audience`

  JWT_REALM

    | `Default: Flexo MMS Microservices`

  JWT_SECRET
    This needs to be the same as what's configured for Flexo MMS Layer1 Service

    | `Default: test1234`
