# Z/IP Gateway files

The `zipgateway` binary uses a handful of files for local device DTLS
communication for example `ZIPR.key_1024.pem`. These are provided from Silicon
labs free download of the [zipgateway source](https://www.silabs.com/products/development-tools/software/z-wave/controller-sdk/z-ip-gateway-sdk)
are only used for local Grizzly to zipgateway communication and not exposed for any
network traffic outside of the device that is running Grizzly and `zipgateway`.