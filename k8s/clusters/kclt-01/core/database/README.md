# About the placement of CNPG/Database

The installation of CloudnativePG's CRDs must be done within the
HelmRelease due to CNPG CRDs only being available as a subchart. As
such, the entirety of the HelmRelease has been moved to 📁 core to
prevent a race condition where certain services attempt to create
a CNPG cluster before the CRDs have been installed. Moving CNPG into
📁 core guarantees it will be able to setup CRDs before any apps try
to use them.

Note that this is not a particularly clean hack, and is dependant on
a couple lucky circumstances:

1. no other 📁 core services require a CNPG postgres database.
2. The CNPG HelmRelease not does not depend on any other 📁 core 
   services (e.g. rook-ceph or cert-manager) 
     - this is valid as Postgres cluster which *do* use 📁 core
       services such as rook-ceph for persistence are created with
       instances of the CRDs, i.e. done within 📁 apps

Please see #42 for more information.
