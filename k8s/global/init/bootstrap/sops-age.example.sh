# run something like this command with every bootstrap. It is not
# actually formally declared here as this is the moment private
# keys are uploaded to the server.

# the key must end in .agekey to be detected as such.
# in production, this file will include both the global and site 
# agekeys.

cat age.agekey |
kubectl create secret generic sops-age \
--namespace=flux-system \
--from-file=age.agekey=/dev/stdin
