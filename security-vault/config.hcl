storage "raft" {
  path    = "/vault/data"
  node_id = "node1"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = "true"
}

ui = true
api_addr = "http://vault.security.svc:8200"
cluster_addr = "http://vault.security.svc:8201"
