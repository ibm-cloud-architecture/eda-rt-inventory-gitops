# Deploy on Existing CP4I cluster

This environment is when you want to deploy this solution on an existing IBM Cloud Pak for Integration demo environment, where Operators and Operandes are in the same namespace, which should be `cp4i`.

In this case we assume the following commands will show the prerequisites are ready:

```sh
oc project cp4i
oc get operators 
```