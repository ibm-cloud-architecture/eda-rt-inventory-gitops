# Deploy the RT inventory locally

This is an example of running thee solution using Minikube or docker compose.

## With Docker desktop and docker compose

If you have Docker Desktop license you can use the docker compose in this folder.

* be sure to have allocated enough docker resource: `4 CPUs, 9 GB RAM, Swap: 1 GB`
* If using Cloud Object Storage as a sink for the store.inventory modify the `../kconnect/kafka-cos-sink-standalone.properties` file with your COS credentials, something like

```
cos.api.key=X3Yde....sQZ3
cos.bucket.location=us-east
cos.bucket.name=eda-demo
cos.bucket.resiliency=regional
cos.service.crn="crn:v1:b.....l:a/ecdc......32a6c8e4::"
```

* Run the complete solution with:

```sh
docker-compose up -d
```