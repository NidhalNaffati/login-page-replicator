# Grafana (immutable/provisioned) for Cloud Run
# - Datasources and dashboards are provisioned from files copied into the image.
# - No persistent storage: treat UI changes as ephemeral; export JSON back to repo.

FROM grafana/grafana-oss:11.5.1

# Note:
# Google Cloud Monitoring is supported via Grafana's built-in datasource in recent Grafana versions.
# We keep this image fully self-contained by relying on the bundled datasource.

# Provisioning (datasources + dashboard providers)
COPY provisioning/ /etc/grafana/provisioning/

# Dashboards JSON
COPY dashboards/ /var/lib/grafana/dashboards/

# Cloud Run listens on $PORT; grafana uses GF_SERVER_HTTP_PORT
ENV GF_SERVER_HTTP_PORT=3000 \
    GF_PATHS_PROVISIONING=/etc/grafana/provisioning \
    GF_USERS_ALLOW_SIGN_UP=false \
    GF_ANALYTICS_REPORTING_ENABLED=false \
    GF_ANALYTICS_CHECK_FOR_UPDATES=false \
    GF_SECURITY_DISABLE_GRAVATAR=true

EXPOSE 3000
