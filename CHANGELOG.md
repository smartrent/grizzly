## Changelog

## v0.2.0

* Fixes
  * Logging with old `ZipGateway` label is now `Grizzly`
  * Fix queued API from `{ZipGateway, :queued_response, ref, response}`
    to `{Grizzly, :queued_response, ref, response}`
  * Fix timeout error when waiting for DTLS server from the
    `zipgateway` side

