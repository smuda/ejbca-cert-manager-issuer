# EJBCA scripts

## start-and-prepare.sh

This script will:

- spin up a EJBCA in namespace ejbca with the service ejbca
- issue an admin certificate from the CSR in admin-cert/admin.csr

After port-forwarding to svc/ejbca 8443:8443, here are
some URLs to take note of:

https://localhost:8444/ejbca/adminweb/
https://localhost:8444/ejbca/ra/enrollwithusername.xhtml
