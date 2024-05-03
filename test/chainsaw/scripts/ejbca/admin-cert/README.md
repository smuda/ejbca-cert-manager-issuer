# Admin-cert

This directory holds a pre-generated certificate request which was generated
using the following command:

```shell
openssl req \
  -new \
  -nodes \
  -newkey rsa:2048 \
  -keyout admin.key \
  -sha256 \
  -out admin.csr \
  -config openssl.conf 
```

This CSR is later used for creating an administrator certificate for test.
