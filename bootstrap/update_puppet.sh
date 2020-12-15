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

# Setup emr-puppet repository
sudo bash -c "cat > /etc/yum.repos.d/emr-puppet6.repo" <<EOL
[emr_puppet6]
name=emr_puppet6_repo
baseurl=http://awssupportdatasvcs.com/bootstrap-actions/puppet6/5.30.1
priority=3
enabled=1
gpgcheck=0
EOL
 
# Install emr-puppet and dependent packages
sudo yum install -y emr-puppet emr-rubygem-trocla emr-rubygem-bcrypt emr-rubygem-highline emr-rubygem-moneta
sudo yum update -y emr-puppet-modules
sudo mv /etc/puppet/troclarc.yaml /etc/puppetlabs/puppet/
sudo mv /etc/puppet/modules /etc/puppetlabs/

#setup puppet executable
sudo ln -sf /opt/aws/puppet/bin/* /usr/bin/
sudo ln -s /etc/puppetlabs/modules /etc/puppet/