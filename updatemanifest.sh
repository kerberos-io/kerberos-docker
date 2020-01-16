docker manifest create kerberos/kerberos kerberos/kerberos:linux-amd64 kerberos/kerberos:linux-armv7 kerberos/kerberos:linux-armv8 --amend
docker manifest annotate kerberos/kerberos kerberos/kerberos:linux-armv7 --os linux --arch arm --variant armv7
docker manifest annotate kerberos/kerberos kerberos/kerberos:linux-armv8 --os linux --arch arm64 --variant armv8
docker manifest inspect kerberos/kerberos
docker manifest push kerberos/kerberos --purge
