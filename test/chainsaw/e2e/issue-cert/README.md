# Chainsaw test issue-cert

This test will create a minimal setup with 

## Step 01

This installs the ejbca as a container with a service.

## Step 10

Step 10 is the first actual test step.

This step is created with:

```shell
helm template ejbca-cert-manager-issuer \
  deploy/charts/ejbca-cert-manager-issuer \
  > test/chainsaw/e2e/issue-cert/00-install.yaml 
```
