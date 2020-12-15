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

bucket=s3://repo.us-east-1.emr-bda.amazonaws.com/rpms
local_repo=/var/aws/emr/packages/bigtop

exclude_pkgs="emrfs ranger-emr-record-server-plugin ranger-hive-plugin emr-secret-agent emr-record-server hive spark ranger-s3-plugin"

local_dir=$local_repo/ranger-emr-record-server-plugin/noarch
sudo mkdir -p $local_dir
sudo aws s3 cp $bucket/ranger-emr-record-server-plugin/noarch/ranger-emr-record-server-plugin-2.0.0-1.amzn2.noarch.rpm $local_dir/

local_dir=$local_repo/ranger-hive-plugin/noarch
sudo mkdir -p $local_dir
sudo aws s3 cp $bucket/ranger-hive-plugin/noarch/ranger-hive-plugin-2.0.0-1.amzn2.noarch.rpm $local_dir/

local_dir=$local_repo/ranger-s3-plugin/noarch
sudo mkdir -p $local_dir
sudo aws s3 cp $bucket/ranger-s3-plugin/noarch/ranger-s3-plugin-0.1.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/

local_dir=$local_repo/emr-secret-agent/noarch
sudo mkdir -p $local_dir
sudo aws s3 cp $bucket/emr-secret-agent/noarch/emr-secret-agent-1.7.0-SNAPSHOT.noarch.rpm $local_dir/

local_dir=$local_repo/emr-record-server/noarch
sudo mkdir -p $local_dir
sudo aws s3 cp $bucket/emr-record-server/noarch/emr-record-server-1.8.0.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/

local_dir=$local_repo/emrfs/noarch
sudo mkdir -p $local_dir
sudo aws s3 cp $bucket/emrfs/noarch/emrfs-2.44.0.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/

local_dir=$local_repo/hive/noarch
sudo mkdir -p $local_dir
sudo aws s3 cp $bucket/hive/hive-hcatalog-server-2.3.7.amzn.2.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/hive/hive-jdbc-2.3.7.amzn.2.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/hive/hive-webhcat-server-2.3.7.amzn.2.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/hive/hive-webhcat-2.3.7.amzn.2.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/hive/hive-2.3.7.amzn.2.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/hive/hive-hbase-2.3.7.amzn.2.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/hive/hive-hcatalog-2.3.7.amzn.2.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/hive/hive-server2-2.3.7.amzn.2.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/hive/hive-metastore-2.3.7.amzn.2.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/

local_dir=$local_repo/spark/noarch
sudo mkdir -p $local_dir
sudo aws s3 cp $bucket/spark/noarch/hadoop-hdfs-journalnode-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-libhdfs-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-yarn-resourcemanager-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-hdfs-secondarynamenode-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-debuginfo-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-mapreduce-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-hdfs-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/zookeeper-debuginfo-3.4.14-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-hdfs-namenode-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hbase-1.4.13-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/zookeeper-rest-3.4.14-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hbase-rest-1.4.13-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-doc-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-hdfs-fuse-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hbase-regionserver-1.4.13-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hbase-master-1.4.13-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hbase-thrift-1.4.13-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-libhdfs-devel-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/spark-datanucleus-2.4.6.amzn.1.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-yarn-nodemanager-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hbase-doc-1.4.13-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-httpfs-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-client-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hbase-thrift2-1.4.13-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-kms-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-conf-pseudo-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-mapreduce-historyserver-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/spark-history-server-2.4.6.amzn.1.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/spark-master-2.4.6.amzn.1.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-hdfs-datanode-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-yarn-timelineserver-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/zookeeper-native-3.4.14-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-hdfs-zkfc-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/spark-external-2.4.6.amzn.1.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/spark-worker-2.4.6.amzn.1.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/spark-python-2.4.6.amzn.1.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/zookeeper-server-3.4.14-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-yarn-proxyserver-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/spark-yarn-shuffle-2.4.6.amzn.1.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/tez-0.9.2-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/spark-R-2.4.6.amzn.1.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/hadoop-yarn-2.10.0.amzn.1.SNAPSHOT-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/spark-core-2.4.6.amzn.1.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/emrfs-2.44.0.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/spark-kubernetes-2.4.6.amzn.1.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/zookeeper-3.4.14-1.amzn2.x86_64.rpm $local_dir/
sudo aws s3 cp $bucket/spark/noarch/spark-thriftserver-2.4.6.amzn.1.SNAPSHOT-1.amzn2.noarch.rpm $local_dir/

repo=""
flag=true
# For pre emr-5.10.0 clusters
if [ -e "/etc/yum.repos.d/Bigtop.repo" ]
then
  flag=false
# For emr-5.10.0+ clusters
elif [ -e "/etc/yum.repos.d/emr-apps.repo" ]
then
  repo="/etc/yum.repos.d/emr-apps.repo"
# For BYOA clusters
elif [ -e "/etc/yum.repos.d/emr-bigtop.repo" ]
then
  repo="/etc/yum.repos.d/emr-bigtop.repo"
fi

if [ "$flag" = true ]
then
  sudo bash -c "cat >> $repo" <<EOL
exclude =$exclude_pkgs
EOL
fi

sudo yum install -y createrepo
sudo createrepo --update --workers 8 -o $local_repo $local_repo
sudo yum clean all
sleep 200

if [ "$flag" = true ]
then
  sudo bash -c "cat > /etc/yum.repos.d/bigtop_test.repo" <<EOL
[bigtop_test]
name=bigtop_test_repo
baseurl=file:///var/aws/emr/packages/bigtop
enabled=1
gpgcheck=0
priority=4
EOL
fi