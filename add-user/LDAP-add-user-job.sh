#!/bin/bash -ex
 
# Amazon EMR
# 
# Copyright 2020, Amazon.com, Inc. or its affiliates. All Rights Reserved.
# 
# Licensed under the Amazon Software License (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
# 
#   http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.
 
PASSWORD=$1 # "amazon"
shift
REALM=$1 # "EC2.INTERNAL"
shift
USERIDS=$@
shift
 
if [[ $USERIDS == 'ldap' ]]; then
    sudo yum install -y openldap-clients
    set +x
    USERIDS=`ldapsearch -x -D "cn=rangeradmin,dc=ap-northeast-1,dc=compute,dc=internal" -w 1qazxsw2 -H ldap://ip-172-31-36-146.ap-northeast-1.compute.internal  -b "dc=ap-northeast-1,dc=compute,dc=internal" "(objectClass=inetOrgPerson)" | grep uid: | cut -f2 -d ":" | xargs echo`
    set -x
fi
 
echo "creating users $USERIDS"
echo "realm is $REALM"
 
cat << END > /tmp/add-users.sh
#!/bin/bash -x
 
# Amazon EMR
#
# Copyright 2020, Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#   http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.
 
 
PASSWORD=\$1 # "amazon"
shift
REALM=\$1 # "EC2.INTERNAL"
shift
USERNAMES=\$@
shift
 
KDC="/usr/bin/kadmin"
 
echo "THIS SCRIPT IS FOR DEBUGGING PURPOSES ONLY. THIS SCRIPT CONTAINS PASSWORDS/ETC AND SHOULD NOT BE USED FOR PRODUCTION WORKLOADS"
echo "creating users \$USERNAMES"
echo "realm is \$REALM"
 
true_function() {
  return 0
}
 
while true_function
do
  res=\$(sudo -u hadoop /usr/bin/hadoop fs -ls /user/ )
  echo "response is \$res"
  if [ -z "\$res" ];
  then
    echo "truststore creds is not popluated. sleeping for 5sec";
    sleep 5;
  else
    echo "truststore creds is populated"
    break
  fi
done
 
for USERNAME in \$USERNAMES; do
    sudo useradd \$USERNAME
 
    hadoop fs -mkdir /user/\$USERNAME
    hadoop fs -chown \$USERNAME /user/\$USERNAME
    hadoop fs -chgrp \$USERNAME /user/\$USERNAME
    hadoop fs -chmod 700 /user/\$USERNAME
 
    set +x
    sudo /usr/bin/kadmin -w \$PASSWORD -p kadmin/admin -q "add_principal -randkey \$USERNAME@\$REALM"
    sudo /usr/bin/kadmin -w \$PASSWORD -p kadmin/admin -q "ktadd -k /home/\$USERNAME/\$USERNAME.keytab -norandkey \$USERNAME@\$REALM"
    set -x
 
    sudo chown \$USERNAME /home/\$USERNAME/\$USERNAME.keytab
    sudo chmod 400 /home/\$USERNAME/\$USERNAME.keytab
    sudo -u \$USERNAME mkdir /home/\$USERNAME/.ssh/
    sudo -u \$USERNAME sh -c 'echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCTvahrWYGiq4pMo7U3JDob/qJpTnzGiQzKzc29wiCdAdgA7ZmNXwIFGeVgkJ/txmRldHMGeY7t9EvwBpskwMs32VkoQ/zKxpgyhOKsARW3I7x/5xX4LlmhTfxbgbFaQc7fL0NAqww/++hy+aB7r7DHtx1W9ZJnkCFQew+VJcNlCjYSSkvGxgKryaX854whUAlMXmkD1+z9WCVjDgX4BKZpisITw05x+gjWplYvzsHDcftygjtTs7EpuqhOd7SvcBWVL6DtAPw7Pw0t5VjlqaqLCxxJjnSVsjz1PP7PtHxhjAF7Dnh8D8TjT3iHqpR0CZSpDBPLT2gV1reUG8E4dmH7" >> /home/\$USERNAME/.ssh/authorized_keys'
 
    sudo -u \$USERNAME kinit -l 365d -k -t /home/\$USERNAME/\$USERNAME.keytab \$USERNAME@\$REALM
done
 
END
chmod +x /tmp/add-users.sh
 
echo "starting background job for user creation as hadoop"
set +x
sudo -u hadoop /tmp/add-users.sh "$PASSWORD" "$REALM" "$USERIDS" &>> /tmp/add-users-out.log  &