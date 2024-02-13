ui = true
cluster_name = "demo-ca"
max_lease_ttl = "768h"
default_lease_ttl = "768h"
cluster_addr = "http://127.0.0.1:8201"
api_addr = "http://0.0.0.0:8080"

listener "tcp" {
  address = "0.0.0.0:8080"
  tls_disable = "true"
  telemetry {
      unauthenticated_metrics_access = "true"
  }
}

storage "raft" {
  path = "/opt/vault/data"
  node_id = "d00vault0001"
}


telemetry {
  prometheus_retention_time = "60s"
  disable_hostname = true
}


