#!/usr/bin/env bash -ex
# Amazon EMR #
# Copyright 2020, Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# Licensed under the Amazon Software License (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at #
# http://aws.amazon.com/asl/ #
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.

# Script variables
RANGER_ADMIN_IP="172.31.35.44" # e.g. 172.31.53.93 ip address for ranger admin server accessible from EMR Cluster

# Keberos Details
KERBEROS_PASSWORD="amazon" # password for Kerberos KDC 
REALM="EC2.INTERNAL" # Kerberos Realm as per Security Config

# Truststore/Keystore Information
# KEYSTORE_PASSWORD="<keystore password>" # The password for your keystore 
# TRUSTSTORE_PASSWORD="<truststore password>" # The password for the truststore 
# PLUGIN_KEYSTORE_TRUSTSTORE="s3://<BUCKET>/<PATH>/ssl-config/" # the prefix/directory where the truststore and keystore are stored in S3. Eg: s3://mybucket/ranger/ssl-stores/

# Role information 
EC2_INSTANCE_PROFILE_ROLE="arn:aws:iam::<AWS_ACCOUNT_ID>:role/NameOfArn" 
EMR_SERVICE_ROLE="arn:aws:iam::<AWS_ACCOUNT_ID>:role/NameOfArn"
DATA_ACCESS_ROLE_ARN="arn:aws:iam::699962710372:role/RangerPluginDataAccessRole" 
USER_ROLE_ARN="arn:aws:iam::699962710372:role/RangerPluginDataAccessRole"

# Cluster and EMR Service Parameters
LOG_URI="s3://hxh-tokyo/RangerSparkLogs/" # Log location for your EMR clsuter. 
CORE_NODES="2" # Number of core nodes for the cluster. 
AWS_CREDENTIALS_PROFILE="default"
RELEASE_LABEL=emr-5.31.0
KEYPAIR="tokyo-ec2"
REGION="ap-northeast-1"
SUBNET_ID="subnet-0fb74847"
INSTANCE_TYPE="m5.xlarge" #Instance Type
SECURITY_CONFIG="RangerSpark-SecurityConfiguration" #Security config name from EMR

# Hardcoded variables, please do not change. 
RPM_REPLACEMENT_SCRIPT=s3://repo.ap-northeast-1.emr-bda.amazonaws.com/replace_rpms.sh 
PUPPET_UPGRADE_SCRIPT=s3://repo.ap-northeast-1.emr-bda.amazonaws.com/update_puppet.sh 
PUPPET_SCRIPTS_REPLACEMENT=s3://repo.ap-northeast-1.emr-bda.amazonaws.com/replace_puppet.sh 
REPLACE_NODE_PROVISIONER=s3://repo.ap-northeast-1.emr-bda.amazonaws.com/replace_node_provisioner.sh

# Generating EMR Configuration JSON. Enter any extra configurations that you may need, such as Hue configuration to integrate with LDAP.
# cat <<EOT > ./emr_ranger_configs.json
# [
# ] EOT

# Create the cluster.
aws emr create-cluster --profile $AWS_CREDENTIALS_PROFILE \
--region $REGION \
--name "EMR-Ranger-Test_"$(date +"%Y-%m-%d-%T") \
--release-label $RELEASE_LABEL \
--use-default-roles \
--enable-debugging \
--security-configuration $SECURITY_CONFIG \
--kerberos-attributes Realm=$REALM,KdcAdminPassword=$KERBEROS_PASSWORD \
--ec2-attributes KeyName=$KEYPAIR,SubnetId=$SUBNET_ID \
--instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=$INSTANCE_TYPE \
InstanceGroupType=CORE,InstanceCount=$CORE_NODES,InstanceType=$INSTANCE_TYPE \
--applications Name=Spark Name=Livy Name=Hive Name=Hue Name=Hadoop Name=Zeppelin \
--log-uri $LOG_URI \
--additional-info '{"clusterType":"development"}' \
--bootstrap-actions \
Name='Replace RPMs',Path="$RPM_REPLACEMENT_SCRIPT" \
Name='Upgrade Puppet',Path="$PUPPET_UPGRADE_SCRIPT" \
Name='Replace Puppet Scripts Plugin',Path="$PUPPET_SCRIPTS_REPLACEMENT" \
Name='Replace Node Provisioner',Path="$REPLACE_NODE_PROVISIONER"