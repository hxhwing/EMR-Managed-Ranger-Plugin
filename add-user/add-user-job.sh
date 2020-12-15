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
USERNAME=$1
shift

aws s3 cp s3://aws-emr-bda-public/ranger-private-beta/v4/scripts/ba/add-user.sh /tmp/add-user.sh

chmod +x /tmp/add-user.sh

echo "starting background job for user creation as hadoop"

sudo -u hadoop /tmp/add-user.sh "$PASSWORD" "$REALM" "$USERNAME" &>> /tmp/add-user-out-${USERNAME}.log  &
