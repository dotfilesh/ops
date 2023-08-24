# What's going on here?

Using CNPG, it is optimal to do a 1-to-1 database to 'cluster'
pairing. [Having a single monolith cluster is
discouraged](https://cloudnative-pg.io/documentation/1.16/faq/#database-management)
or [outright
impossible](https://github.com/cloudnative-pg/cloudnative-pg/discussions/497).