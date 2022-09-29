#! /bin/bash

set -e

sudo mkdir -p /etc/apt/keyrings/
curl https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

echo "--------------BEGIN---------------"
sudo apt update
echo "--------------UPDATED---------------"
sudo apt install -y openjdk-11-jdk tomcat9 grafana-agent
echo "--------------INSTALLED---------------"

sudo systemctl stop tomcat9

echo "Download Prometheus Exporter"
sudo curl -v --fail --location https://search.maven.org/remotecontent?filepath=io/prometheus/simpleclient/${TOMCAT_SIMPLECLIENT_VERSION}/simpleclient-${TOMCAT_SIMPLECLIENT_VERSION}.jar --output /var/lib/tomcat9/lib/simpleclient-${TOMCAT_SIMPLECLIENT_VERSION}.jar && \
sudo curl -v --fail --location https://search.maven.org/remotecontent?filepath=io/prometheus/simpleclient_common/${TOMCAT_SIMPLECLIENT_VERSION}/simpleclient_common-${TOMCAT_SIMPLECLIENT_VERSION}.jar --output /var/lib/tomcat9/lib/simpleclient_common-${TOMCAT_SIMPLECLIENT_VERSION}.jar && \
sudo curl -v --fail --location https://search.maven.org/remotecontent?filepath=io/prometheus/simpleclient_hotspot/${TOMCAT_SIMPLECLIENT_VERSION}/simpleclient_hotspot-${TOMCAT_SIMPLECLIENT_VERSION}.jar --output /var/lib/tomcat9/lib/simpleclient_hotspot-${TOMCAT_SIMPLECLIENT_VERSION}.jar && \
sudo curl -v --fail --location https://search.maven.org/remotecontent?filepath=io/prometheus/simpleclient_servlet/${TOMCAT_SIMPLECLIENT_VERSION}/simpleclient_servlet-${TOMCAT_SIMPLECLIENT_VERSION}.jar --output /var/lib/tomcat9/lib/simpleclient_servlet-${TOMCAT_SIMPLECLIENT_VERSION}.jar && \
sudo curl -v --fail --location https://search.maven.org/remotecontent?filepath=io/prometheus/simpleclient_servlet_common/${TOMCAT_SIMPLECLIENT_VERSION}/simpleclient_servlet_common-${TOMCAT_SIMPLECLIENT_VERSION}.jar --output /var/lib/tomcat9/lib/simpleclient_servlet_common-${TOMCAT_SIMPLECLIENT_VERSION}.jar && \
sudo curl -v --fail --location https://search.maven.org/remotecontent?filepath=nl/nlighten/tomcat_exporter_client/${TOMCAT_EXPORTER_VERSION}/tomcat_exporter_client-${TOMCAT_EXPORTER_VERSION}.jar --output /var/lib/tomcat9/lib/tomcat_exporter_client-${TOMCAT_EXPORTER_VERSION}.jar && \
sudo curl -v --fail --location https://search.maven.org/remotecontent?filepath=nl/nlighten/tomcat_exporter_servlet/${TOMCAT_EXPORTER_VERSION}/tomcat_exporter_servlet-${TOMCAT_EXPORTER_VERSION}.war --output /var/lib/tomcat9/webapps/metrics.war

echo "Downloading war from ${STAGED_BINARY}"
rm -rf /var/lib/tomcat9/webapps/ROOT
sudo gsutil cp "${STAGED_BINARY}" /var/lib/tomcat9/webapps/

sudo mkdir /var/lib/tomcat9/webapps/healthz
sudo tee /var/lib/tomcat9/webapps/healthz/index.html > /dev/null << EOF
<h1>I'm Healthy!</h1>
EOF

sudo systemctl start tomcat9

sudo systemctl stop grafana-agent

sudo tee /etc/grafana-agent.yaml > /dev/null << EOF
metrics:
  global:
    scrape_interval: 60s
  configs:
  - name: hosted-prometheus
    scrape_configs:
      - job_name: node
        static_configs:
        - targets: ['localhost:9090']
      - job_name: tomcat
        static_configs:
        - targets: ['localhost:8080']
    remote_write:
      - url: ${GRAFANA_PROM_URL}
        basic_auth:
          username: ${GRAFANA_PROM_USERNAME}
          password: ${GRAFANA_PROM_PASSWORD}
EOF
sudo chmod 777 /etc/grafana-agent.yaml
nohup grafana-agent --config.file /etc/grafana-agent.yaml -server.http.address=127.0.0.1:9090 &