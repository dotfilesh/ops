# What's going on here?

This explains the weird hack going on here to setup a database for
authentik.

## The Database

Using CNPG, it is optimal to do a 1-to-1 database to 'cluster'
pairing. [Having a single monolith cluster is
discouraged](https://cloudnative-pg.io/documentation/1.16/faq/#database-management)
or [outright
impossible](https://github.com/cloudnative-pg/cloudnative-pg/discussions/497).
As such, each database is given its own cluster.

## Backups

I am using Ceph's S3 rigamaroll, which I initiate
using an `ObjectBucketClaim`. The OBC generates a new bucket
with a unique name, stored in a configmap; and a corresponding user
with total privileges over that bucket, stored in a secret.

For example, if I created an OBC with the name of
`cloudnative-pg-backup`, the configmap would have two fields:

```yaml
# ConfigMap: cloudnative-pg-backup
BUCKET_HOST: rook-ceph-rgw-ceph-bucket.rook-ceph.svc
BUCKET_NAME: cloudnative-pg-backup-80c45d3a-edf5-4caf-b6aa-90bce5bd4e56
---
# Secret: cloudnative-pg-backup
AWS_ACCESS_KEY_ID: AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY 
```

The API for a CNPG `Cluster` backs up WAL files via barman to an S3 
object store. There are two/four big fields to talk about.
- `s3Credentials.accessKeyId` and `s3Credentials.secretAccessKey` are
  meant to consume secrets, as such they can be hooked up directly to
  the secrets created by the OBC.

- `destinationPath` and `endpointURL` are expecting strings which are
  HTTP and S3 URIs to a valid bucket. However, as the bucket gets
  a random UUID stapled onto the end and the endpoint is dependent on
  the namespace of the rook installation[^1], these need to be
  injected.

[^1]: The `endpointURL` should be able to be set to a proper address
    on the internet to facilitate cross-site communication. But that
    is an issue tertiary to what is happening here.

To solve this, I create a Flux `Kustomization` which adds
a unique `postBuild.substituteFrom` to inject the data from the OBC's
configmap into it. This *fluxtomize* is scoped to only be used by each
cluster instance.
