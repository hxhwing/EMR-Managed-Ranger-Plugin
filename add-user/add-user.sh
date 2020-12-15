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


PASSWORD=$1 # "amazon"
shift
REALM=$1 # "EC2.INTERNAL"
shift
USERNAME=$1
shift

KDC="/usr/bin/kadmin"

echo "creating user $USERNAME"
echo "password is $PASSWORD"
echo "realm is $REALM"

true_function() {
  return 0
}

while true_function
do
  res=$(sudo -u hadoop /usr/bin/hadoop fs -ls /user/ )
  echo "response is $res"
  if [ -z "$res" ];
  then
    echo "truststore creds is not popluated. sleeping for 5sec";
    sleep 5;
  else
    echo "truststore creds is populated"
    break
  fi
done


sudo useradd $USERNAME
hadoop fs -mkdir /user/$USERNAME
hadoop fs -chown $USERNAME /user/$USERNAME
hadoop fs -chgrp $USERNAME /user/$USERNAME


sudo /usr/bin/kadmin -w $PASSWORD -p kadmin/admin -q "add_principal -randkey $USERNAME@$REALM"
sudo /usr/bin/kadmin -w $PASSWORD -p kadmin/admin -q "ktadd -k /home/$USERNAME/$USERNAME.keytab -norandkey $USERNAME@$REALM"
sudo chown $USERNAME /home/$USERNAME/$USERNAME.keytab
sudo chmod 400 /home/$USERNAME/$USERNAME.keytab
sudo -u $USERNAME mkdir /home/$USERNAME/.ssh/

sudo -u $USERNAME kinit -l 365d -k -t /home/$USERNAME/$USERNAME.keytab $USERNAME@$REALM
