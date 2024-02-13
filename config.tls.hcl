ui = true

cluster_name = "demo-ca"
max_lease_ttl = "768h"
default_lease_ttl = "768h"

disable_clustering = "False"
cluster_addr = "http://127.0.0.1:8201"
api_addr = "http://0.0.0.0:8200"

listener "tcp" {
  address = "0.0.0.0:8200"
  cluster_address = "127.0.0.1:8201"
  tls_cert_file = "/opt/vault/tls/d00vault0001.crt"
  tls_key_file = "/opt/vault/tls/d00vault0001.key"
  tls_client_ca_file="/opt/vault/tls/DemoCA_Root_CA_v1.crt"
  tls_min_version  = "tls12"
  tls_prefer_server_cipher_suites = ""
  tls_disable_client_certs = "true"
  tls_disable = "false"
  telemetry {
    unauthenticated_metrics_access = "true"
  }
}

storage "raft" {
  path = "/opt/vault/data"
  node_id = "d00vault0001"
}


telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
}
