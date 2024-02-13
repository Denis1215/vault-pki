https://gist.github.com/palimarium/3a0c7a1026f0789f7ce1d7f2689665f9
https://www.ibm.com/docs/zh/cloud-paks/foundational-services/3.23?topic=cmcm-using-vault-issue-certificates
https://medium.com/hashicorp-engineering/certificates-issuing-and-renewal-with-vault-and-consul-template-18e766228dac
https://developer.hashicorp.com/vault/tutorials/app-integration/application-integration
https://developer.hashicorp.com/vault/tutorials/secrets-management/pki-engine

https://developer.hashicorp.com/vault/docs/agent-and-proxy/agent/template
https://github.com/hashicorp/consul-template/issues/1597


```shell
vault operator init --key-shares=6 --key-threshold=3
vault operator unseal

  
```

```shell
certstrap --depot-path root init \
     --organization "DemoCA" \
     --organizational-unit "IT" \
     --country "RU" \
     --curve P-256 \
     --expires "10 years" \
     --province "Moscow" \
     --locality "Moscow" \
     --common-name "DemoCA Root CA v1"

super_secret_phrase
```

```shell
certstrap --depot-path root request-cert \
    --curve P-256 \
    --organization "DemoCA" \
    --country "RU" \
    --locality "Moscow" \
    --common-name "d00vault0001" \
    --organizational-unit "IT" \
    --ip 172.16.201.201 \
    --domain d00vault0001,d00vault0001.k11s.cloud.vsk.local
```

```shell
certstrap --depot-path root sign \
  d00vault0001 \
  --CA DemoCA_Root_CA_v1 \
  --expires "1 year"

cp root/DemoCA_Root_CA_v1.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust

```

```shell
vault secrets enable -path=pki_int pki
vault secrets tune -max-lease-ttl=43800h pki_int
```

```shell
vault write pki_int/config/urls \
    issuing_certificates="https://d00vault0001.k11s.cloud.vsk.local:8200/v1/pki_int/ca" \
    crl_distribution_points="https://d00vault0001.k11s.cloud.vsk.local:8200/v1/pki_int/crl"
```

```shell
vault write -format=json \
    pki_int/intermediate/generate/internal \
    organization="DemoCA" \
    common_name="DemoCA Intermediate CA v1" \
    key_type=ec \
    key_bits=256 \
    > pki_int_v1.1.csr.json
cat pki_int_v1.1.csr.json | jq -r '.data.csr' > pki_int_v1.1.csr
openssl req -text -noout -verify -in pki_int_v1.1.csr
```

```shell
certstrap --depot-path root sign \
    --CA DemoCA_Root_CA_v1 \
    --intermediate \
    --csr pki_int_v1.1.csr \
    --expires "5 years" \
    --path-length 1 \
    --cert pki_int_v1.1.crt \
    "DemoCA Intermediate CA v1"
openssl x509 -in pki_int_v1.1.crt -text -noout
```

```shell
vault write -format=json \
    pki_int/intermediate/set-signed \
    certificate=@pki_int_v1.1.crt \
    > pki_int_v1.1.set-signed.json
cat pki_int_v1.1.set-signed.json
```

```shell
vault secrets enable -path=pki_iss pki
vault secrets tune -max-lease-ttl=8760h pki_iss
```

```shell
vault write pki_iss/config/urls \
    issuing_certificates="https://d00vault0001.k11s.cloud.vsk.local:8200/v1/pki_iss/ca" \
    crl_distribution_points="https://d00vault0001.k11s.cloud.vsk.local:8200/v1/pki_iss/crl"
```

```shell
vault write -format=json \
    pki_iss/intermediate/generate/internal \
    organization="DemoCA" \
    common_name="DemoCA Issuing CA v1" \
    key_type=ec \
    key_bits=256 \
    > pki_iss_v1.1.1.csr.json
    
cat pki_iss_v1.1.1.csr.json | jq -r '.data.csr' > pki_iss_v1.1.1.csr
openssl req -text -noout -verify -in pki_iss_v1.1.1.csr
```

```shell
vault write -format=json \
    pki_int/root/sign-intermediate \
    organization="DemoCA" \
    csr=@pki_iss_v1.1.1.csr \
    ttl=8760h \
    format=pem \
    > pki_iss_v1.1.1.crt.json
cat pki_iss_v1.1.1.crt.json | jq -r '.data.certificate' > pki_iss_v1.1.1.crt
openssl x509 -in pki_iss_v1.1.1.crt -text -noout

cat pki_iss_v1.1.1.crt pki_int_v1.1.crt > pki_iss_v1.1.1.chain.crt

```

```shell
vault write -format=json \
    pki_iss/intermediate/set-signed \
    certificate=@pki_iss_v1.1.1.chain.crt \
    > pki_iss_v1.1.1.set-signed.json
cat pki_iss_v1.1.1.set-signed.json
```


```shell
vault write pki_iss/roles/demo \
    organization="DemoCa" \
    allowed_domains="democa.tech" \
    allow_subdomains=true \
    allow_wildcard_certificates=false \
    key_type=ec \
    key_bits=256 \
    generate_lease=true \
    max_ttl=2160h
```

```shell
vault write -format=json \
    pki_iss/issue/demo \
    common_name="mail.democa.tech" \
    > pki_iss_v1.1.1.mail.crt.json
cat pki_iss_v1.1.1.mail.crt.json
cat pki_iss_v1.1.1.mail.crt.json | jq -r .data.certificate \
    | openssl x509 -text -noout
```

```shell
cat pki_iss_v1.1.1.mail.crt.json | jq -r '.data.private_key' \
> pki_iss_v1.1.1.mail.key
```

```shell
cat pki_iss_v1.1.1.mail.crt.json | jq -r '.data.ca_chain' \
> pki_iss_v1.1.1.mail.chain.pem
```

