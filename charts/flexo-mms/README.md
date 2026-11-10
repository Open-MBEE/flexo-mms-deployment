# flexo-mms

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.3.1](https://img.shields.io/badge/AppVersion-v0.3.1-informational?style=flat-square)

Flexo MMS (Model Management System) microservices - layer1, LDAP auth, SSO auth and artifact store - with an optional in-cluster dev stack (Fuseki, MinIO, OpenLDAP).

**Homepage:** <https://www.openmbee.org/>

## Quick start

Self-contained development stack (Fuseki, MinIO, OpenLDAP with users `user01`/`password1`, `user02`/`password2`) in the current namespace:

```bash
helm install flexo charts/flexo-mms --set devStack.enabled=true
helm test flexo
```

Production-style install against your own backends:

```yaml
# my-values.yaml
jwt:
  existingSecret: flexo-jwt          # key JWT_SECRET
quadStore:
  queryUrl: https://quadstore.example.org/repositories/flexo
  updateUrl: https://quadstore.example.org/repositories/flexo/statements
  graphStoreProtocolUrl: https://quadstore.example.org/repositories/flexo/rdf-graphs/service
s3:
  region: us-west-2
  bucket: flexo-artifacts
  existingSecret: flexo-s3           # keys AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY (omit to use IRSA)
ldap:
  location: ldaps://ldap.example.org:636
  base: dc=example,dc=org
ingress:
  enabled: true
  className: nginx
  hosts: [flexo.example.org]
  tls:
    - secretName: flexo-tls
      hosts: [flexo.example.org]
```

```bash
helm install flexo charts/flexo-mms -f my-values.yaml
```

Load a bootstrap policy graph (see `files/cluster.trig`, with `http://layer1-service/` replaced by your `layer1.rootContext`) into the quad store, or no user will be authorized.

## Components

| Value prefix | Image | Default | Ingress path |
|---|---|---|---|
| `layer1` | `openmbee/flexo-mms-layer1-service` | enabled | `/` |
| `auth` | `openmbee/flexo-mms-auth-service` (LDAP basic-auth → JWT) | enabled | `/login` |
| `sso` | `openmbee/flexo-mms-sso-auth-service` (OIDC → JWT) | disabled | `sso.contextPath` (`/sso`) |
| `store` | `openmbee/flexo-mms-store-service` (S3 artifacts) | enabled | — (internal) |
| `devStack.fuseki` / `devStack.minio` / `devStack.openldap` | `atomgraph/fuseki`, `bitnamilegacy/minio`, `bitnamilegacy/openldap` | disabled | — |

Every component accepts `enabled`, `image.*`, `replicaCount`, `resources`, `podAnnotations`, `podLabels`, `nodeSelector`, `tolerations`, `affinity`, `extraEnv`, `extraEnvFrom`, `extraVolumes`, `extraVolumeMounts`, `service.{type,port}`, `startupProbe`/`livenessProbe`/`readinessProbe`, `podDisruptionBudget` and `autoscaling`, plus per-component `podSecurityContext`/`containerSecurityContext` overrides that are merged over the chart-wide defaults.

## Secrets

Sensitive values never land in a ConfigMap. Each has an inline value for development and an `existingSecret` (+ key) override for real deployments:

| Secret | Inline value | Existing secret |
|---|---|---|
| JWT signing secret | `jwt.secret` | `jwt.existingSecret` / `jwt.existingSecretKey` |
| S3 credentials | `s3.accessKeyId`, `s3.secretAccessKey` | `s3.existingSecret` / `s3.existingSecretAccessKeyIdKey`, `s3.existingSecretSecretAccessKeyKey` |
| OIDC client secret | `sso.oidc.clientSecret` | `sso.oidc.existingSecret` / `sso.oidc.existingSecretKey` |
| SSO datasource password | `sso.datasource.password` | `sso.datasource.existingSecret` / `sso.datasource.existingSecretKey` |
| Docker Hub pull secret | `imagePullSecret.{username,password}` | `global.imagePullSecrets` |

When `jwt.secret` is empty and the dev stack is off, the chart generates a random secret on first install and keeps it across upgrades (`lookup`).

## Security defaults

Pods run as uid/gid 10001 with `runAsNonRoot`, `allowPrivilegeEscalation: false`, all capabilities dropped, `seccompProfile: RuntimeDefault`, `readOnlyRootFilesystem: true` (with an `emptyDir` on `/tmp`) and no automounted service-account token. Known exceptions, set in `values.yaml`:

- `devStack.openldap`: the Bitnami image initialises `/opt/bitnami/openldap` at start-up and runs as uid 1001, so it keeps a writable root filesystem.
- `devStack.fuseki`: the image runs as its own `fuseki` user and writes to `/fuseki/databases` and `/fuseki/logs`, which are mounted volumes.

## Requirements

Kubernetes: `>=1.25.0-0`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| auth.affinity | object | `{}` |  |
| auth.autoscaling.enabled | bool | `false` |  |
| auth.autoscaling.maxReplicas | int | `3` |  |
| auth.autoscaling.minReplicas | int | `1` |  |
| auth.autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| auth.autoscaling.targetMemoryUtilizationPercentage | string | `""` |  |
| auth.containerSecurityContext | object | `{}` |  |
| auth.enabled | bool | `true` | Deploy the LDAP auth service (`GET /login` with basic auth returns a JWT). |
| auth.extraEnv | list | `[]` |  |
| auth.extraEnvFrom | list | `[]` |  |
| auth.extraVolumeMounts | list | `[]` |  |
| auth.extraVolumes | list | `[]` |  |
| auth.image.pullPolicy | string | `"IfNotPresent"` |  |
| auth.image.repository | string | `"openmbee/flexo-mms-auth-service"` |  |
| auth.image.tag | string | `"v0.1.1"` |  |
| auth.javaOptions | string | `""` |  |
| auth.livenessProbe.enabled | bool | `true` |  |
| auth.livenessProbe.failureThreshold | int | `3` |  |
| auth.livenessProbe.httpGet.path | string | `"/"` |  |
| auth.livenessProbe.httpGet.port | string | `"http"` |  |
| auth.livenessProbe.periodSeconds | int | `20` |  |
| auth.nodeSelector | object | `{}` |  |
| auth.podAnnotations | object | `{}` |  |
| auth.podDisruptionBudget.enabled | bool | `false` |  |
| auth.podDisruptionBudget.maxUnavailable | string | `""` |  |
| auth.podDisruptionBudget.minAvailable | int | `1` |  |
| auth.podLabels | object | `{}` |  |
| auth.podSecurityContext | object | `{}` |  |
| auth.priorityClassName | string | `""` |  |
| auth.readinessProbe.enabled | bool | `true` |  |
| auth.readinessProbe.failureThreshold | int | `3` |  |
| auth.readinessProbe.httpGet.path | string | `"/"` |  |
| auth.readinessProbe.httpGet.port | string | `"http"` |  |
| auth.readinessProbe.periodSeconds | int | `10` |  |
| auth.replicaCount | int | `1` |  |
| auth.resources.limits.cpu | string | `"1"` |  |
| auth.resources.limits.memory | string | `"768Mi"` |  |
| auth.resources.requests.cpu | string | `"100m"` |  |
| auth.resources.requests.memory | string | `"256Mi"` |  |
| auth.service.annotations | object | `{}` |  |
| auth.service.port | int | `8080` |  |
| auth.service.type | string | `"ClusterIP"` |  |
| auth.startupProbe.enabled | bool | `true` |  |
| auth.startupProbe.failureThreshold | int | `36` |  |
| auth.startupProbe.httpGet.path | string | `"/"` |  |
| auth.startupProbe.httpGet.port | string | `"http"` |  |
| auth.startupProbe.periodSeconds | int | `5` |  |
| auth.strategy.rollingUpdate.maxSurge | int | `1` |  |
| auth.strategy.rollingUpdate.maxUnavailable | int | `0` |  |
| auth.strategy.type | string | `"RollingUpdate"` |  |
| auth.terminationGracePeriodSeconds | int | `30` |  |
| auth.tolerations | list | `[]` |  |
| auth.topologySpreadConstraints | list | `[]` |  |
| commonAnnotations | object | `{}` | Annotations added to every resource. |
| commonLabels | object | `{}` | Labels added to every resource. |
| containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true}` | Container-level security context applied to every container (merged under each component's `containerSecurityContext`). |
| devStack.bootstrap.affinity | object | `{}` |  |
| devStack.bootstrap.backoffLimit | int | `3` | Job backoff limit. |
| devStack.bootstrap.enabled | bool | `true` | Run a post-install/post-upgrade Job that loads the bootstrap policy graph (`files/cluster.trig`, rewritten to `layer1.rootContext`) into Fuseki. |
| devStack.bootstrap.image.pullPolicy | string | `"IfNotPresent"` |  |
| devStack.bootstrap.image.repository | string | `"curlimages/curl"` |  |
| devStack.bootstrap.image.tag | string | `"8.14.1"` |  |
| devStack.bootstrap.nodeSelector | object | `{}` |  |
| devStack.bootstrap.podAnnotations | object | `{}` |  |
| devStack.bootstrap.podLabels | object | `{}` |  |
| devStack.bootstrap.resources.limits.cpu | string | `"200m"` |  |
| devStack.bootstrap.resources.limits.memory | string | `"128Mi"` |  |
| devStack.bootstrap.resources.requests.cpu | string | `"10m"` |  |
| devStack.bootstrap.resources.requests.memory | string | `"32Mi"` |  |
| devStack.bootstrap.timeoutSeconds | int | `300` | Seconds the Job waits for Fuseki before giving up. |
| devStack.bootstrap.tolerations | list | `[]` |  |
| devStack.enabled | bool | `false` | Deploy an in-cluster Fuseki, MinIO and OpenLDAP and wire the services to them. For development and evaluation only. |
| devStack.fuseki.affinity | object | `{}` |  |
| devStack.fuseki.containerSecurityContext | object | `{}` |  |
| devStack.fuseki.dataset | string | `"ds"` | Dataset name; endpoints become `/<dataset>/sparql`, `/<dataset>/update`, `/<dataset>/data`. |
| devStack.fuseki.extraEnv | list | `[]` |  |
| devStack.fuseki.image.pullPolicy | string | `"IfNotPresent"` |  |
| devStack.fuseki.image.repository | string | `"atomgraph/fuseki"` |  |
| devStack.fuseki.image.tag | string | `"4.6"` |  |
| devStack.fuseki.javaOptions | string | `"-Xmx1024m -Xms512m"` | `JAVA_OPTIONS` for the Fuseki JVM (the compose reference uses `-Xmx8192m -Xms8192m`). |
| devStack.fuseki.nodeSelector | object | `{}` |  |
| devStack.fuseki.persistence.accessModes | list | `["ReadWriteOnce"]` | PVC access modes. |
| devStack.fuseki.persistence.enabled | bool | `false` | Persist the TDB2 database on a PersistentVolumeClaim; when false the quad store lives on an emptyDir and the bootstrap graph is reloaded by the Job on every install/upgrade. |
| devStack.fuseki.persistence.existingClaim | string | `""` | Reuse an existing PVC instead of creating one. |
| devStack.fuseki.persistence.size | string | `"8Gi"` | PVC size. |
| devStack.fuseki.persistence.storageClass | string | `""` | StorageClass (empty uses the cluster default). |
| devStack.fuseki.podAnnotations | object | `{}` |  |
| devStack.fuseki.podLabels | object | `{}` |  |
| devStack.fuseki.podSecurityContext | object | `{}` |  |
| devStack.fuseki.resources.limits.cpu | string | `"2"` |  |
| devStack.fuseki.resources.limits.memory | string | `"1536Mi"` |  |
| devStack.fuseki.resources.requests.cpu | string | `"250m"` |  |
| devStack.fuseki.resources.requests.memory | string | `"768Mi"` |  |
| devStack.fuseki.service.port | int | `3030` |  |
| devStack.fuseki.service.type | string | `"ClusterIP"` |  |
| devStack.fuseki.tolerations | list | `[]` |  |
| devStack.minio.affinity | object | `{}` |  |
| devStack.minio.containerSecurityContext | object | `{}` |  |
| devStack.minio.defaultBuckets | string | `"load"` | Buckets created at startup (comma separated); should include `s3.bucket`. |
| devStack.minio.existingSecret | string | `""` | Existing Secret with `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD` instead of the values above. |
| devStack.minio.extraEnv | list | `[]` |  |
| devStack.minio.image.pullPolicy | string | `"IfNotPresent"` |  |
| devStack.minio.image.repository | string | `"bitnamilegacy/minio"` |  |
| devStack.minio.image.tag | string | `"2025.7.23-debian-12-r5"` |  |
| devStack.minio.nodeSelector | object | `{}` |  |
| devStack.minio.persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| devStack.minio.persistence.enabled | bool | `false` |  |
| devStack.minio.persistence.existingClaim | string | `""` |  |
| devStack.minio.persistence.size | string | `"8Gi"` |  |
| devStack.minio.persistence.storageClass | string | `""` |  |
| devStack.minio.podAnnotations | object | `{}` |  |
| devStack.minio.podLabels | object | `{}` |  |
| devStack.minio.podSecurityContext | object | `{"fsGroup":1001,"runAsGroup":1001,"runAsUser":1001}` | Bitnami images run as uid 1001. |
| devStack.minio.resources.limits.cpu | string | `"1"` |  |
| devStack.minio.resources.limits.memory | string | `"512Mi"` |  |
| devStack.minio.resources.requests.cpu | string | `"100m"` |  |
| devStack.minio.resources.requests.memory | string | `"256Mi"` |  |
| devStack.minio.rootPassword | string | `"admintest"` | Root password; stored in a Secret. |
| devStack.minio.rootUser | string | `"admintest"` | Root user; also used as the store service's access key when `s3.accessKeyId` is empty. |
| devStack.minio.service.port | int | `9000` |  |
| devStack.minio.service.type | string | `"ClusterIP"` |  |
| devStack.minio.tolerations | list | `[]` |  |
| devStack.openldap.adminPassword | string | `"adminpassword"` | Admin password; stored in a Secret. |
| devStack.openldap.adminUsername | string | `"admin"` | Admin username (`LDAP_ADMIN_USERNAME`). |
| devStack.openldap.affinity | object | `{}` |  |
| devStack.openldap.containerSecurityContext | object | `{"readOnlyRootFilesystem":false}` | The Bitnami OpenLDAP entrypoint rewrites files under `/opt/bitnami/openldap`, so it cannot run read-only. |
| devStack.openldap.existingSecret | string | `""` | Existing Secret with `LDAP_ADMIN_PASSWORD` and `LDAP_PASSWORDS` instead of the values above. |
| devStack.openldap.extraEnv | list | `[]` |  |
| devStack.openldap.group | string | `"group01"` | Group all users are added to (`LDAP_GROUP`). |
| devStack.openldap.image.pullPolicy | string | `"IfNotPresent"` |  |
| devStack.openldap.image.repository | string | `"bitnamilegacy/openldap"` |  |
| devStack.openldap.image.tag | string | `"2.6.4"` |  |
| devStack.openldap.nodeSelector | object | `{}` |  |
| devStack.openldap.passwords | list | `["password1","password2"]` | Passwords for `users`, same order; stored in a Secret. |
| devStack.openldap.persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| devStack.openldap.persistence.enabled | bool | `false` |  |
| devStack.openldap.persistence.existingClaim | string | `""` |  |
| devStack.openldap.persistence.size | string | `"1Gi"` |  |
| devStack.openldap.persistence.storageClass | string | `""` |  |
| devStack.openldap.podAnnotations | object | `{}` |  |
| devStack.openldap.podLabels | object | `{}` |  |
| devStack.openldap.podSecurityContext.fsGroup | int | `1001` |  |
| devStack.openldap.podSecurityContext.runAsGroup | int | `1001` |  |
| devStack.openldap.podSecurityContext.runAsUser | int | `1001` |  |
| devStack.openldap.resources.limits.cpu | string | `"500m"` |  |
| devStack.openldap.resources.limits.memory | string | `"256Mi"` |  |
| devStack.openldap.resources.requests.cpu | string | `"50m"` |  |
| devStack.openldap.resources.requests.memory | string | `"128Mi"` |  |
| devStack.openldap.root | string | `"dc=example,dc=org"` | Directory root (`LDAP_ROOT`); also the default `ldap.base`. |
| devStack.openldap.service.port | int | `1389` |  |
| devStack.openldap.service.type | string | `"ClusterIP"` |  |
| devStack.openldap.tolerations | list | `[]` |  |
| devStack.openldap.userDc | string | `"users"` | OU the users live in (`LDAP_USER_DC`). |
| devStack.openldap.users | list | `["user01","user02"]` | Users created at startup (`LDAP_USERS`). |
| fullnameOverride | string | `""` | Override the fully qualified release name used in resource names. |
| global.imagePullSecrets | list | `[]` | Image pull secrets applied to every pod (names of existing Secrets). |
| imagePullSecret.create | bool | `false` | Create a `kubernetes.io/dockerconfigjson` Secret from the credentials below and attach it to every pod. |
| imagePullSecret.email | string | `""` | Registry e-mail (optional). |
| imagePullSecret.name | string | `""` | Name of the created Secret (defaults to `<fullname>-dockerhub`). |
| imagePullSecret.password | string | `""` | Registry password or access token. |
| imagePullSecret.registry | string | `"https://index.docker.io/v1/"` | Registry server the credentials belong to. |
| imagePullSecret.username | string | `""` | Registry username. |
| ingress.annotations | object | `{"nginx.ingress.kubernetes.io/proxy-body-size":"256m","nginx.ingress.kubernetes.io/proxy-connect-timeout":"600","nginx.ingress.kubernetes.io/proxy-next-upstream-timeout":"600","nginx.ingress.kubernetes.io/proxy-read-timeout":"3600","nginx.ingress.kubernetes.io/proxy-send-timeout":"3600"}` | Ingress annotations (defaults carry the ingress-nginx body-size/timeouts used by the reference deployment). |
| ingress.className | string | `""` | IngressClass name. |
| ingress.enabled | bool | `false` | Create an Ingress routing `/` to layer1, `/login` to auth and `<sso.contextPath>` to sso (each only when enabled). |
| ingress.extraPaths | list | `[]` | Additional paths appended to every host (`path`, `pathType`, `backend`). |
| ingress.hosts | list | `["flexo-mms.example.org"]` | Hostnames served by the Ingress. |
| ingress.pathType | string | `"Prefix"` | `pathType` for the generated paths. |
| ingress.tls | list | `[]` | TLS configuration (`hosts`, `secretName`). |
| jwt.audience | string | `"flexo-mms-audience"` | JWT audience (`JWT_AUDIENCE`). |
| jwt.domain | string | `"http://flexo-mms-services"` | JWT issuer (`JWT_DOMAIN`) shared by all services. |
| jwt.existingSecret | string | `""` | Name of an existing Secret holding the JWT secret instead of `jwt.secret`. |
| jwt.existingSecretKey | string | `"JWT_SECRET"` | Key inside `jwt.existingSecret`. |
| jwt.jwksUrl | string | `""` | JWKS endpoint for RS256 verification on layer1 (`JWT_JWKS_URL`). Defaults to the in-chart SSO service's JWKS when `sso.enabled=true`. |
| jwt.realm | string | `"flexo-mms"` | JWT realm (`JWT_REALM`). |
| jwt.secret | string | `""` | HMAC signing secret (`JWT_SECRET`); stored in a Secret. When empty, the dev stack uses the docker-compose value and a production install generates a random secret that is kept across upgrades. |
| layer1.affinity | object | `{}` | Affinity. |
| layer1.autoscaling.enabled | bool | `false` | Create a HorizontalPodAutoscaler. |
| layer1.autoscaling.maxReplicas | int | `5` |  |
| layer1.autoscaling.minReplicas | int | `1` |  |
| layer1.autoscaling.targetCPUUtilizationPercentage | int | `80` | Target average CPU utilization (empty disables the metric). |
| layer1.autoscaling.targetMemoryUtilizationPercentage | string | `""` | Target average memory utilization (empty disables the metric). |
| layer1.config.artifactUseStore | bool | `true` | Store large artifacts in the store service instead of the quad store (`FLEXO_MMS_ARTIFACT_USE_STORE`). |
| layer1.config.atomicCommit | string | `""` | `FLEXO_MMS_ATOMIC_COMMIT`: `auto`, `always` or `never` (empty keeps the service default). |
| layer1.config.glomarResponse | bool | `true` | Answer 404 instead of 403 for unauthorized resources (`FLEXO_MMS_GLOMAR_RESPONSE`). |
| layer1.config.gzipLiteralsLargerThanKib | string | `""` | `FLEXO_MMS_GZIP_LITERALS_LARGER_THAN_KIB` (empty keeps the service default). |
| layer1.config.maximumLiteralSizeKib | string | `""` | `FLEXO_MMS_MAXIMUM_LITERAL_SIZE_KIB` (empty keeps the service default). |
| layer1.config.mutexTtlSeconds | string | `""` | `FLEXO_MMS_MUTEX_TTL_SECONDS` (empty keeps the service default). |
| layer1.config.sparqlRequestTimeout | string | `""` | `FLEXO_MMS_SPARQL_REQUEST_TIMEOUT` in seconds (empty keeps the service default). |
| layer1.containerSecurityContext | object | `{}` | Container security context overrides for this component. |
| layer1.enabled | bool | `true` | Deploy the layer1 (model/API) service. |
| layer1.extraEnv | list | `[]` | Extra environment variables. |
| layer1.extraEnvFrom | list | `[]` | Extra `envFrom` sources (ConfigMaps/Secrets). |
| layer1.extraVolumeMounts | list | `[]` | Extra volume mounts. |
| layer1.extraVolumes | list | `[]` | Extra volumes. |
| layer1.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. |
| layer1.image.repository | string | `"openmbee/flexo-mms-layer1-service"` | Image repository. |
| layer1.image.tag | string | `"v0.3.1"` | Image tag. |
| layer1.javaOptions | string | `""` | `JAVA_OPTS` for the JVM (heap defaults to 25% of the memory limit when unset). |
| layer1.livenessProbe | object | `{"enabled":true,"failureThreshold":3,"periodSeconds":20,"tcpSocket":{"port":"http"}}` | Liveness probe. |
| layer1.nodeSelector | object | `{}` | Node selector. |
| layer1.podAnnotations | object | `{}` | Pod annotations. |
| layer1.podDisruptionBudget.enabled | bool | `false` | Create a PodDisruptionBudget. |
| layer1.podDisruptionBudget.maxUnavailable | string | `""` | `maxUnavailable`. |
| layer1.podDisruptionBudget.minAvailable | int | `1` | `minAvailable` (mutually exclusive with `maxUnavailable`). |
| layer1.podLabels | object | `{}` | Pod labels. |
| layer1.podSecurityContext | object | `{}` | Pod security context overrides for this component. |
| layer1.priorityClassName | string | `""` | Priority class name. |
| layer1.readinessProbe | object | `{"enabled":true,"failureThreshold":3,"periodSeconds":10,"tcpSocket":{"port":"http"}}` | Readiness probe. |
| layer1.replicaCount | int | `1` | Number of replicas (ignored when `autoscaling.enabled=true`). |
| layer1.resources | object | `{"limits":{"cpu":"2","memory":"2Gi"},"requests":{"cpu":"250m","memory":"512Mi"}}` | Container resources. |
| layer1.rootContext | string | `"http://layer1-service"` | Root IRI of this Flexo MMS cluster (`FLEXO_MMS_ROOT_CONTEXT`); all org/repo/user IRIs are minted under it and the dev-stack bootstrap graph is rewritten to it. Set it to the public URL in production. |
| layer1.service.annotations | object | `{}` | Service annotations. |
| layer1.service.port | int | `8080` | Service port. |
| layer1.service.type | string | `"ClusterIP"` | Service type. |
| layer1.serviceId | string | `""` | Instance id used in commit metadata (`FLEXO_MMS_SERVICE_ID`); defaults to `<fullname>-layer1`. |
| layer1.startupProbe | object | `{"enabled":true,"failureThreshold":36,"periodSeconds":5,"tcpSocket":{"port":"http"}}` | Startup probe (TCP; layer1 has no unauthenticated HTTP endpoint). |
| layer1.storeServiceUrl | string | `""` | Store-service URL (`FLEXO_MMS_STORE_SERVICE_URL`); defaults to the in-chart store service when `store.enabled=true`. |
| layer1.strategy | object | `{"rollingUpdate":{"maxSurge":1,"maxUnavailable":0},"type":"RollingUpdate"}` | Deployment update strategy. |
| layer1.terminationGracePeriodSeconds | int | `30` | Termination grace period in seconds. |
| layer1.tolerations | list | `[]` | Tolerations. |
| layer1.topologySpreadConstraints | list | `[]` | Topology spread constraints. |
| ldap.base | string | `""` | LDAP base DN (`LDAP_BASE`). Defaults to `devStack.openldap.root` when `devStack.enabled=true`. |
| ldap.groupAttribute | string | `"cn"` | Group naming attribute (`LDAP_GROUP_ATTRIBUTE`). |
| ldap.groupNamespace | string | `"ldap/group/"` | Prefix for group ids in Flexo MMS (`LDAP_GROUP_NAMESPACE`). |
| ldap.groupSearchFilter | string | `"(&(objectclass=group)(member=%s)(|(%s)))"` | Group search filter (`LDAP_GROUP_SEARCH_FILTER`). |
| ldap.groupStoreContext | string | `""` | Root context the auth service uses for group IRIs (`LDAP_GROUP_STORE_CONTEXT`). Defaults to `<layer1.rootContext>/`. |
| ldap.groupStoreUri | string | `""` | SPARQL endpoint the auth service reads groups from (`LDAP_GROUP_STORE_URI`). Defaults to `quadStore.queryUrl`. |
| ldap.location | string | `""` | LDAP URL (`LDAP_LOCATION`). Defaults to the in-chart OpenLDAP when `devStack.enabled=true`. |
| ldap.userNamespace | string | `"ldap/user/"` | Prefix for user ids in Flexo MMS (`LDAP_USER_NAMESPACE`). |
| ldap.userPattern | string | `"cn=%s,ou=users"` | User DN pattern relative to the base (`LDAP_USER_PATTERN`). |
| logback.existingConfigMap | string | `""` | Use an existing ConfigMap for the fragment instead of `logback.fragment`. |
| logback.existingConfigMapKey | string | `"logback.xml"` | Key inside `logback.existingConfigMap`. |
| logback.fragment | string | `"<included>\n  <!-- additional appenders / logger levels, e.g. a SyslogAppender for Graylog -->\n</included>\n"` | Logback `<included>` fragment mounted at `/mnt/config/logback/loggers-include.xml` in layer1, auth and store. |
| nameOverride | string | `""` | Override the chart name used in resource names. |
| podSecurityContext | object | `{"fsGroup":10001,"runAsGroup":10001,"runAsNonRoot":true,"runAsUser":10001,"seccompProfile":{"type":"RuntimeDefault"}}` | Pod-level security context applied to every pod (merged under each component's `podSecurityContext`). |
| quadStore.graphStoreProtocolUrl | string | `""` | Graph Store Protocol endpoint (`FLEXO_MMS_GRAPH_STORE_PROTOCOL_URL`). |
| quadStore.masterQueryUrl | string | `""` | Optional master/primary query endpoint for read-after-write consistency (`FLEXO_MMS_MASTER_QUERY_URL`). |
| quadStore.queryUrl | string | `""` | SPARQL query endpoint (`FLEXO_MMS_QUERY_URL`). Defaults to the in-chart Fuseki when `devStack.enabled=true`. |
| quadStore.updateUrl | string | `""` | SPARQL update endpoint (`FLEXO_MMS_UPDATE_URL`). |
| s3.accessKeyId | string | `""` | Access key id; stored in a Secret. Defaults to the dev-stack MinIO root user when `devStack.enabled=true`. Leave both keys empty to use the AWS default credential chain (IRSA, instance profile). |
| s3.bucket | string | `"load"` | Bucket used by the store service (`S3_BUCKET`). |
| s3.endpoint | string | `""` | S3 endpoint (`S3_ENDPOINT`). Defaults to the in-chart MinIO when `devStack.enabled=true`; leave empty for AWS S3. |
| s3.existingSecret | string | `""` | Existing Secret holding the S3 credentials instead of `s3.accessKeyId`/`s3.secretAccessKey`. |
| s3.existingSecretKeys | object | `{"accessKeyId":"AWS_ACCESS_KEY_ID","secretAccessKey":"AWS_SECRET_ACCESS_KEY"}` | Keys inside `s3.existingSecret`. |
| s3.region | string | `"us-east-1"` | S3 region (`S3_REGION`). |
| s3.secretAccessKey | string | `""` | Secret access key; stored in a Secret. |
| serviceAccount.annotations | object | `{}` | Annotations for the ServiceAccount (e.g. IRSA / Workload Identity). |
| serviceAccount.automountServiceAccountToken | bool | `false` | Mount the service-account token into pods. None of the services talk to the Kubernetes API. |
| serviceAccount.create | bool | `true` | Create a ServiceAccount shared by all Flexo MMS pods. |
| serviceAccount.name | string | `""` | Name of the ServiceAccount (defaults to the release fullname; `default` when `create=false` and empty). |
| sso.affinity | object | `{}` |  |
| sso.autoscaling.enabled | bool | `false` |  |
| sso.autoscaling.maxReplicas | int | `3` |  |
| sso.autoscaling.minReplicas | int | `1` |  |
| sso.autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| sso.autoscaling.targetMemoryUtilizationPercentage | string | `""` |  |
| sso.containerSecurityContext | object | `{}` |  |
| sso.contextPath | string | `"/sso"` | Servlet context path (`SERVER_SERVLET_CONTEXT_PATH`); also used for the Ingress path and probes. |
| sso.datasource.existingSecret | string | `""` | Existing Secret holding the datasource password instead of `sso.datasource.password`. |
| sso.datasource.existingSecretKey | string | `"SPRING_DATASOURCE_PASSWORD"` | Key inside `sso.datasource.existingSecret`. |
| sso.datasource.password | string | `""` | Datasource password; stored in a Secret. |
| sso.datasource.url | string | `"jdbc:sqlite:/tmp/sso-database.db"` | JDBC URL (`SPRING_DATASOURCE_URL`). The SQLite default lives on an emptyDir and is lost on restart; point it at PostgreSQL for production. |
| sso.datasource.username | string | `""` | Datasource username. |
| sso.enabled | bool | `false` | Deploy the OIDC SSO auth service (Spring Boot) under `/sso`. |
| sso.extraEnv | list | `[]` |  |
| sso.extraEnvFrom | list | `[]` |  |
| sso.extraVolumeMounts | list | `[]` |  |
| sso.extraVolumes | list | `[]` |  |
| sso.groupClaimsField | string | `"groups"` | Token claim listing the user's groups (`FLEXO_SSO_AUTH_SERVICE_SSO_GROUP_CLAIMS_FIELD`). |
| sso.image.pullPolicy | string | `"IfNotPresent"` |  |
| sso.image.repository | string | `"openmbee/flexo-mms-sso-auth-service"` |  |
| sso.image.tag | string | `"beta-1"` |  |
| sso.javaOptions | string | `""` | `JAVA_TOOL_OPTIONS` for the JVM. |
| sso.livenessProbe.enabled | bool | `true` |  |
| sso.livenessProbe.failureThreshold | int | `3` |  |
| sso.livenessProbe.httpGet.path | string | `"/sso/actuator/health"` |  |
| sso.livenessProbe.httpGet.port | string | `"http"` |  |
| sso.livenessProbe.periodSeconds | int | `20` |  |
| sso.nodeSelector | object | `{}` |  |
| sso.oidc.authorizationGrantType | string | `"authorization_code"` | Authorization grant type. |
| sso.oidc.clientId | string | `""` | OIDC client id (`SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_OIDC_CLIENT_ID`). |
| sso.oidc.clientName | string | `"Flexo MMS SSO"` | Display name of the OIDC client registration. |
| sso.oidc.clientSecret | string | `""` | OIDC client secret; stored in a Secret. |
| sso.oidc.existingSecret | string | `""` | Existing Secret holding the client secret instead of `sso.oidc.clientSecret`. |
| sso.oidc.existingSecretKey | string | `"SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_OIDC_CLIENT_SECRET"` | Key inside `sso.oidc.existingSecret`. |
| sso.oidc.issuerUri | string | `""` | OIDC issuer URI (`SPRING_SECURITY_OAUTH2_CLIENT_PROVIDER_OIDC_ISSUER_URI`). Required when `sso.enabled=true`. |
| sso.oidc.redirectUri | string | `""` | Redirect URI registered with the IdP. Defaults to `https://<first ingress host><contextPath>/login/oauth2/code/oidc` when the Ingress is enabled. |
| sso.oidc.resourceServerIssuerUri | string | `""` | Issuer URI for resource-server JWT validation (`SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI`); defaults to `sso.oidc.issuerUri`. |
| sso.oidc.scope | string | `"openid,profile,email"` | Requested scopes. |
| sso.podAnnotations | object | `{}` |  |
| sso.podDisruptionBudget.enabled | bool | `false` |  |
| sso.podDisruptionBudget.maxUnavailable | string | `""` |  |
| sso.podDisruptionBudget.minAvailable | int | `1` |  |
| sso.podLabels | object | `{}` |  |
| sso.podSecurityContext | object | `{}` |  |
| sso.priorityClassName | string | `""` |  |
| sso.readinessProbe.enabled | bool | `true` |  |
| sso.readinessProbe.failureThreshold | int | `3` |  |
| sso.readinessProbe.httpGet.path | string | `"/sso/actuator/health"` |  |
| sso.readinessProbe.httpGet.port | string | `"http"` |  |
| sso.readinessProbe.periodSeconds | int | `10` |  |
| sso.replicaCount | int | `1` |  |
| sso.resources.limits.cpu | string | `"1"` |  |
| sso.resources.limits.memory | string | `"1Gi"` |  |
| sso.resources.requests.cpu | string | `"100m"` |  |
| sso.resources.requests.memory | string | `"384Mi"` |  |
| sso.service.annotations | object | `{}` |  |
| sso.service.port | int | `8080` |  |
| sso.service.type | string | `"ClusterIP"` |  |
| sso.startupProbe.enabled | bool | `true` |  |
| sso.startupProbe.failureThreshold | int | `60` |  |
| sso.startupProbe.httpGet.path | string | `"/sso/actuator/health"` |  |
| sso.startupProbe.httpGet.port | string | `"http"` |  |
| sso.startupProbe.periodSeconds | int | `5` |  |
| sso.strategy.rollingUpdate.maxSurge | int | `1` |  |
| sso.strategy.rollingUpdate.maxUnavailable | int | `0` |  |
| sso.strategy.type | string | `"RollingUpdate"` |  |
| sso.terminationGracePeriodSeconds | int | `30` |  |
| sso.tolerations | list | `[]` |  |
| sso.topologySpreadConstraints | list | `[]` |  |
| sso.userIdField | string | `"sid"` | ID-token claim used as the Flexo MMS user id (`FLEXO_SSO_AUTH_SERVICE_SSO_USER_ID_FIELD`). |
| store.affinity | object | `{}` |  |
| store.autoscaling.enabled | bool | `false` |  |
| store.autoscaling.maxReplicas | int | `3` |  |
| store.autoscaling.minReplicas | int | `1` |  |
| store.autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| store.autoscaling.targetMemoryUtilizationPercentage | string | `""` |  |
| store.containerSecurityContext | object | `{}` |  |
| store.enabled | bool | `true` | Deploy the artifact store service (S3 backed). |
| store.extraEnv | list | `[]` |  |
| store.extraEnvFrom | list | `[]` |  |
| store.extraVolumeMounts | list | `[]` |  |
| store.extraVolumes | list | `[]` |  |
| store.image.pullPolicy | string | `"IfNotPresent"` |  |
| store.image.repository | string | `"openmbee/flexo-mms-store-service"` |  |
| store.image.tag | string | `"v0.2.0"` |  |
| store.javaOptions | string | `""` |  |
| store.livenessProbe.enabled | bool | `true` |  |
| store.livenessProbe.failureThreshold | int | `3` |  |
| store.livenessProbe.periodSeconds | int | `20` |  |
| store.livenessProbe.tcpSocket.port | string | `"http"` |  |
| store.nodeSelector | object | `{}` |  |
| store.podAnnotations | object | `{}` |  |
| store.podDisruptionBudget.enabled | bool | `false` |  |
| store.podDisruptionBudget.maxUnavailable | string | `""` |  |
| store.podDisruptionBudget.minAvailable | int | `1` |  |
| store.podLabels | object | `{}` |  |
| store.podSecurityContext | object | `{}` |  |
| store.priorityClassName | string | `""` |  |
| store.readinessProbe.enabled | bool | `true` |  |
| store.readinessProbe.failureThreshold | int | `3` |  |
| store.readinessProbe.periodSeconds | int | `10` |  |
| store.readinessProbe.tcpSocket.port | string | `"http"` |  |
| store.replicaCount | int | `1` |  |
| store.resources.limits.cpu | string | `"1"` |  |
| store.resources.limits.memory | string | `"1Gi"` |  |
| store.resources.requests.cpu | string | `"100m"` |  |
| store.resources.requests.memory | string | `"256Mi"` |  |
| store.service.annotations | object | `{}` |  |
| store.service.port | int | `8080` |  |
| store.service.type | string | `"ClusterIP"` |  |
| store.startupProbe.enabled | bool | `true` |  |
| store.startupProbe.failureThreshold | int | `36` |  |
| store.startupProbe.periodSeconds | int | `5` |  |
| store.startupProbe.tcpSocket.port | string | `"http"` |  |
| store.strategy.rollingUpdate.maxSurge | int | `1` |  |
| store.strategy.rollingUpdate.maxUnavailable | int | `0` |  |
| store.strategy.type | string | `"RollingUpdate"` |  |
| store.terminationGracePeriodSeconds | int | `30` |  |
| store.tolerations | list | `[]` |  |
| store.topologySpreadConstraints | list | `[]` |  |
| tests.enabled | bool | `true` | Render the `helm test` Pod, which logs in through the auth service and lists orgs on layer1. |
| tests.image.pullPolicy | string | `"IfNotPresent"` |  |
| tests.image.repository | string | `"curlimages/curl"` |  |
| tests.image.tag | string | `"8.14.1"` |  |
| tests.password | string | `""` | Password for the test login. |
| tests.resources.limits.cpu | string | `"200m"` |  |
| tests.resources.limits.memory | string | `"128Mi"` |  |
| tests.resources.requests.cpu | string | `"10m"` |  |
| tests.resources.requests.memory | string | `"32Mi"` |  |
| tests.username | string | `""` | Username for the test login; defaults to the first dev-stack user when `devStack.enabled=true`. The test is skipped when no credentials are available. |
| timezone | string | `"UTC"` | `TZ` for every container. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
