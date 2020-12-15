#!/bin/bash -ex
 
instanceRole=`cat /mnt/var/lib/info/extraInstanceData.json | grep instanceRole | cut -f2 -d: | cut -f2 -d'"'`
 
if [[ "$instanceRole" == "master" ]]; then
    echo "I am on master. "
    #sudo yum install -y zeppelin
 
    #sudo aws s3 cp s3://hxh-tokyo/EMR-Managed-Ranger/zeppelin/shiro.ini /etc/zeppelin/conf/shiro.ini
    sudo aws s3 cp s3://hxh-tokyo/EMR-Managed-Ranger/zeppelin/90-zeppelin-user /etc/sudoers.d/
 
    sudo sh -c "echo 'ZEPPELIN_IMPERSONATE_USER=\`echo \${ZEPPELIN_IMPERSONATE_USER} | cut -d "@" -f1\`' >>  /var/aws/emr/bigtop-deploy/puppet/modules/zeppelin/templates/zeppelin-env.sh"
    sudo sh -c 'echo "export ZEPPELIN_IMPERSONATE_CMD='\''sudo -H -u \$'{ZEPPELIN_IMPERSONATE_USER}' bash -c'\''" >> /var/aws/emr/bigtop-deploy/puppet/modules/zeppelin/templates/zeppelin-env.sh'
 
    #Disable Public Notebooks by default
    sudo sh -c "echo 'export ZEPPELIN_NOTEBOOK_PUBLIC=\"false\"' >> /var/aws/emr/bigtop-deploy/puppet/modules/zeppelin/templates/zeppelin-env.sh"
 
    #Add Recordserver libs to the classpath.
    sudo sh -c "echo 'export CLASSPATH=\"\$CLASSPATH:/usr/share/aws/emr/record-server/lib/aws-emr-record-server-connector-common.jar:/usr/share/aws/emr/record-server/lib/aws-emr-record-server-spark-connector.jar:/usr/share/aws/emr/record-server/lib/aws-emr-record-server-client.jar:/usr/share/aws/emr/record-server/lib/aws-emr-record-server-common.jar:/usr/share/aws/emr/record-server/lib/jars/secret-agent-interface.jar\"' >> /var/aws/emr/bigtop-deploy/puppet/modules/zeppelin/templates/zeppelin-env.sh"
 
else
    echo "Im on slave. Not doing anything."
fi