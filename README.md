# EMR Managed Ranger Plugin Installation Guide

## Table of Contents
========================
  * [Limitation](#limitation)
  * [I. 配置Ranger Admin Server](#i-配置ranger-admin-server)
  * [II. 将证书存放到Secrets Manager中](#ii-将证书存放到Secrets-Manager中)
  * [III. 创建RangerPlugin所需的IAM Policy和IAM Role](#iii-创建RangerPlugin所需的IAM-Policy和IAM-Role)
  * [IV. 创建EMR Security Configuration](#iv--创建EMR-Security-Configuration)
  * [V. 启动EMR集群](#v-启动EMR集群)
  * [VI. 验证Ranger策略](#vi-验证Ranger策略)
  * [VII. Kerberos认证](#vii-Kerberos认证)
  * [VIII. 使用Zeppelin Notebook](#viii-使用Zeppelin-Notebook)
  

## Limitation

针对EMR托管的Ranger Plugin，目前有以下限制：
 - 截止到2020.12.11，托管Ranger Plugin为Beta版本，处于Private Preview阶段，目前只支持5.30/5.31 EMR 版本，后续计划会支持6.x版本
 - 第一批将支持Hive，S3和Spark Ranger Plugin，后续计划会支持PrestoSQL Plugin
 - Spark Plugin只支持‘Select’权限授权，后续计划会支持insert，update等权限
 - Ranger Admin Server必须自行管理，且必须启用SSL
 - Ranger Plugin与Ranger Admin通信，必须使用SSL，需要为Plugin配置证书
 - 需要为Ranger Admin和Ranger Plugin配置证书，Ranger Admin和Ranger Plugin需要相互认证
 - 证书必须存放到Secrets Manager中
 - EMR集群上必须启用Kerberos认证
 - Spark Ranger Plugin不支持使用Glue Data Catalog作为Metastore
 - 当Zeppelin启用LDAP认证，并使用Ranger授权时，需要在EMR每个节点上，包括Master和Core，为每个LDAP用户创建系统用户，Kerberos Principal以及HDFS用户。目前可通过手动执行脚本，完成该任务


## I. 配置Ranger Admin Server

1. 在Ranger Admin Server上，创建自签名证书
```
## 创建ranger-admin-keystore.jks，注意CN需要与Ranger admin server的hostname一致
hostname -f
keytool -genkey -keystore ranger-admin-keystore.jks -alias rangeradmin -keyalg RSA -keysize 2048 -validity 3950

########示例#######
[ec2-user@ip-172-31-44-92 ~]$ hostname -f
ip-172-31-44-92.ap-northeast-1.compute.internal
[ec2-user@ip-172-31-44-92 ~]$ keytool -genkey -keystore ranger-admin-keystore.jks -alias rangeradmin -keyalg RSA -keysize 2048 -validity 3950
Enter keystore password:
Re-enter new password:
What is your first and last name?
  [Unknown]:  ip-172-31-44-92.ap-northeast-1.compute.internal
What is the name of your organizational unit?
  [Unknown]:  AWS
What is the name of your organization?
  [Unknown]:  AWS
What is the name of your City or Locality?
  [Unknown]:  Shanghai
What is the name of your State or Province?
  [Unknown]:  Shanghai
What is the two-letter country code for this unit?
  [Unknown]:  CN
Is CN=ip-172-31-44-92.ap-northeast-1.compute.internal, OU=AWS, O=AWS, L=Shanghai, ST=Shanghai, C=CN correct?
  [no]:  yes

###################

keytool -selfcert -alias rangeradmin -keystore ranger-admin-keystore.jks -validity 3950

## 从keystore导出public certificate
keytool -export -alias rangeradmin -keystore ranger-admin-keystore.jks -rfc -file ranger-admin-public-cert.cer 
```

2. 将证书导入Ranger Admin Server
```
## 将证书导入Ranger Admin Server，会生成ranger-admin-truststore.jks
keytool -import -keystore ranger-admin-truststore.jks -file ranger-admin-public-cert.cer -alias rangeradmin

[ec2-user@ip-172-31-44-92 ~]$ ls -l
total 12
-rw-rw-r-- 1 ec2-user ec2-user 2309 Dec  3 08:32 ranger-admin-keystore.jks
-rw-rw-r-- 1 ec2-user ec2-user 1361 Dec  3 08:32 ranger-admin-public-cert.cer
-rw-rw-r-- 1 ec2-user ec2-user 1019 Dec  3 08:32 ranger-admin-truststore.jks

```

3. 为Ranger Admin启用HTTPS

Ranger Admin默认只启用HTTP，端口为6080。但是EMR托管的Ranger Plugin，要求在EMR nodes必须使用SSL与Ranger Admin Server通信。
所以Ranger Admin Server需要启用HTTPS，可以使用自签名生成的Ranger Admin Server证书，作为HTTPS的证书，但是建议使用企业的CA证书。
修改Ranger Admin的配置文件‘ranger-admin-site.xml’，修改HTTPS以及证书相关配置
```
##配置文件位于: Ranger安装目录/conf/
[ec2-user@ip-172-31-44-92 ~]$ ls -l /usr/lib/ranger/ranger-admin/conf/
total 72
-rw-r--r-- 1 ranger ranger    32 Dec  3 07:55 core-site.xml
-rwxr-xr-x 1 root   root      82 Dec  3 07:55 java_home.sh
-rw-r--r-- 1 ranger ranger 11860 Dec  3 08:51 ranger-admin-default-site.xml
-rw-r--r-- 1 root   root   12615 Dec  3 09:13 ranger-admin-default-site.xml.bk
-rwxr-xr-x 1 ranger ranger    47 Dec  3 07:55 ranger-admin-env-hadoopconfdir.sh
-rwxr-xr-x 1 ranger ranger    66 Dec  3 07:55 ranger-admin-env-logdir.sh
-rwxr-xr-x 1 ranger ranger    69 Dec  3 07:55 ranger-admin-env-piddir.sh
-rw-r--r-- 1 ranger ranger  8111 Dec  3 09:19 ranger-admin-site.xml
-rw-r--r-- 1 root   root    7840 Dec  3 09:15 ranger-admin-site.xml.bk
-rw-r--r-- 1 root   root    7277 Dec  3 07:55 security-applicationContext.xml
[ec2-user@ip-172-31-44-92 ~]$


##编辑ranger-admin-site.xml文件，添加或者修改以下配置：

<property>
    <name>ranger.service.https.attrib.ssl.enabled</name>
    <value>true</value>
</property>

<property>
    <name>ranger.https.attrib.keystore.file</name>
    <value><PATH TO KEYSTORE></value>
</property>

<property>
    <name>ranger.service.https.attrib.keystore.file</name>
    <value><PATH TO KEYSTORE></value>
</property>

<property>
    <name>ranger.service.https.attrib.keystore.pass</name>
    <value><KEYSTORE PASSWORD></value>
</property>

<property>
    <name>ranger.service.https.attrib.keystore.keyalias</name>
    <value>rangeradmin</value>
</property>

<property>
    <name>ranger.service.https.attrib.clientAuth</name>
    <value>want</value>
</property>

<property>
    <name>ranger.service.https.port</name>
    <value>6182</value>
</property>


##修改完成后重启ranger-admin服务
sudo /usr/bin/ranger-admin restart

```

4. 为EMR上的Ranger Plugin创建证书，用于与Ranger Admin通信.

注意： 可以为每个Plugin创建一个单独的证书，也可以多个Plugin使用一个证书，本文档中是共用一个证书
```
keytool -genkey -keystore plugin-spark-keystore.jks -alias rangerplugin -keyalg RSA -keysize 2048 -validity 3950

########示例#######
[ec2-user@ip-172-31-44-92 ~]$ keytool -genkey -keystore plugin-spark-keystore.jks -alias rangerplugin -keyalg RSA -keysize 2048 -validity 3950
Enter keystore password:
Re-enter new password:
What is your first and last name?
  [Unknown]:  *.ap-northeast-1.compute.internal
What is the name of your organizational unit?
  [Unknown]:  AWS
What is the name of your organization?
  [Unknown]:  AWS
What is the name of your City or Locality?
  [Unknown]:  Shanghai
What is the name of your State or Province?
  [Unknown]:  Shanghai
What is the two-letter country code for this unit?
  [Unknown]:  CN
Is CN=*.ap-northeast-1.compute.internal, OU=AWS, O=AWS, L=Shanghai, ST=Shanghai, C=CN correct?
  [no]:  yes

#################

keytool -selfcert -alias rangerplugin -keystore plugin-spark-keystore.jks -validity 3950

##导出plugin的Public certificate
keytool -export -alias rangerplugin -keystore plugin-spark-keystore.jks -rfc -file plugin-spark.cer

```

5. 将Ranger Plugin的证书导入到Ranger Admin Server的truststore
```
keytool -importcert -alias rangerplugin -file plugin-spark.cer -keystore ranger-admin-truststore.jks

```

6. 从Ranger Plugin的证书中，导出Private key
```
##生成ranger-plugin-keystore.p12
keytool -importkeystore -srckeystore plugin-spark-keystore.jks -destkeystore ranger-plugin-keystore.p12 -srcalias rangerplugin -srcstoretype jks -deststoretype pkcs12

##导出private key, ranger-plugin-keystore.pem
openssl pkcs12 -in ranger-plugin-keystore.p12 -out ranger-plugin-keystore.pem -nodes

[ec2-user@ip-172-31-44-92 ~]$ ls -l
total 28
-rw-rw-r-- 1 ec2-user ec2-user 1321 Dec  3 08:35 plugin-spark.cer
-rw-rw-r-- 1 ec2-user ec2-user 2282 Dec  3 08:35 plugin-spark-keystore.jks
-rw-rw-r-- 1 ec2-user ec2-user 2309 Dec  3 08:32 ranger-admin-keystore.jks
-rw-rw-r-- 1 ec2-user ec2-user 1361 Dec  3 08:32 ranger-admin-public-cert.cer
-rw-rw-r-- 1 ec2-user ec2-user 1977 Dec  3 08:36 ranger-admin-truststore.jks
-rw-rw-r-- 1 ec2-user ec2-user 2643 Dec  3 08:37 ranger-plugin-keystore.p12
-rw-rw-r-- 1 ec2-user ec2-user 3449 Dec  3 08:38 ranger-plugin-keystore.pem
```

7. Install Spark Service Definition

下载Spark Service Definition的JSON文件，通过Ranger Admin的API安装到Ranger Admin Server中

```
## 下载service definition文件
wget https://s3.amazonaws.com/repo.us-east-1.emr-bda.amazonaws.com/service-definitions/ranger-2.0/ranger-servicedef-amazon-emr-spark.json

## 安装Spark service definition文件，需要替换<RangerAdminPassword>, 和RangerServerIP (172.31.44.92)
curl -u admin:<RangerAdminPassword> -X POST -d @ranger-servicedef-amazon-emr-spark.json \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-k 'https://172.31.44.92:6182/service/public/v2/api/servicedef'
```

8. Install S3 Service Definition

下载S3 Service Definition的JSON文件，通过Ranger Admin的API安装到Ranger Admin Server中

```
## 下载service definition文件
wget https://s3.amazonaws.com/repo.us-east-1.emr-bda.amazonaws.com/service-definitions/ranger-2.0/ranger-servicedef-amazon-emr-s3.json

## 安装S3 service definition文件，需要替换<RangerAdminPassword>, 和RangerServerIP (172.31.44.92)
curl -u admin:1qazxsw2 -X POST -d @ranger-servicedef-amazon-emr-s3.json \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-k 'https://ip-172-31-44-92.ap-northeast-1.compute.internal:6182/service/public/v2/api/servicedef'

```

9. 为 Spark 和 S3 创建Service Repository

首先通过HTTPS登录Ranger Admin Server，验证Spark和S3的Service Definition安装成功

![Ranger Service Definition](./Pictures/Ranger-service-definition.png)

创建 Spark Service Repository，注意：
 - Service Name: 必须是amazonemrspark
 - Common Name for Certifcate: 必须与Ranger Plugin证书的CN一致

![Spark Service Repository](./Pictures/Spark-service-repository.png)

创建 S3 Service Repository，注意：
 - Service Name: 必须是amazonemrs3
 - Common Name for Certifcate: 必须与Ranger Plugin证书的CN一致

![S3 Service Repository](./Pictures/S3-service-repository.png)


## II. 将证书存放到Secrets Manager中

证书文件存放到Secrets Manager，EMR节点可以自动从Secrets Manager中获取证书，并导入到EMR nodes中，用来提供Ranger Plugin与Ranger Admin Server之间的SSL通信。

**注意：**
 - 将 Ranger Admin 的 Public 证书保存到 Secrets Manager
 - 将 Ranger Plugin 的 Private Key 和证书存放到 Secrets Manager
```
## Ranger Admin的 Public Certificate:
[ec2-user@ip-172-31-44-92 ~]$ more ranger-admin-public-cert.cer
-----BEGIN CERTIFICATE-----
MIIDszCCApugAwIBAgIECLT0GzANBgkqhkiG9w0BAQsFADCBiTELMAkGA1UEBhMC
Q04xETAPBgNVBAgTCFNoYW5naGFpMREwDwYDVQQHEwhTaGFuZ2hhaTEMMAoGA1UE
ChMDQVdTMQwwCgYDVQQLEwNBV1MxODA2BgNVBAMTL2lwLTE3Mi0zMS00NC05Mi5h
cC1ub3J0aGVhc3QtMS5jb21wdXRlLmludGVybmFsMB4XDTIwMTIwMzA4MzIyNloX
DTMxMDkyNzA4MzIyNlowgYkxCzAJBgNVBAYTAkNOMREwDwYDVQQIEwhTaGFuZ2hh
aTERMA8GA1UEBxMIU2hhbmdoYWkxDDAKBgNVBAoTA0FXUzEMMAoGA1UECxMDQVdT
MTgwNgYDVQQDEy9pcC0xNzItMzEtNDQtOTIuYXAtbm9ydGhlYXN0LTEuY29tcHV0
ZS5pbnRlcm5hbDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAIos3Qfj
kpWKVlxO2Lh4cokRILHP7rMQzEZj+5B66mDqwby0yQ22kOiz6P0si1SzhtU+6kxf
7vilBoNiBhL+dNPozPRckdEflmi8Pw7rpEMAFCTTA1LMjmOt1V689sRofdfSman6
qYXV3/VCLn7zLUJz4Sy/d0TKynL5efqAD5N62/lpV7FRSIrFo7AT8ZkKW1q7n3hn
I5Of2aVtoZ5AUAmruttWU3WIC9w+SdzarlG1nlcFKaNqe19lpNKEQYw6xQ52IvfO
qYV5FlUK1m7LcD3mxJ0rBHGxmHKH/TvI+Ae/9Zwkgmm8Z9AyXO4F0ce+3gPVKqy5
qRsG6QDhN4tuWYMCAwEAAaMhMB8wHQYDVR0OBBYEFHNzUJP/W+1S6p/WkSgkLoZ3
9XobMA0GCSqGSIb3DQEBCwUAA4IBAQBUrZjjzCEItVLxqYdI9LEemDbaPuDT8svu
QrclM9Vhc2UIKXcK1sK2BLfNMvK765JedQOf59hew5wGMgof4/EY3CfgwbCI1jvR
mQ+WwQiAiRHbVXncZymhY1cmnGXISLqxD8Y73EuVb+Wxiykuu+LeLXVycDzBOqMT
88H4UVXQbC6wuxtTR9ourvYDxtuR4Lj5EaElrDpCHsajSH+2xthClSVKpTE3oAg1
372q8DO58oZR4vaQG6GIKxNNi5m/fECU13RjZVCYsn8acTJv0LEfc1DQQVUCSfJo
Ybl11Tum/zF8UakU5w6wcF7KwjGP91d3MqgN/dSTZ5PDA7BG04Ie
-----END CERTIFICATE-----

## Ranger Plugin Private Key:
[ec2-user@ip-172-31-44-92 ~]$ more ranger-plugin-keystore.pem
Bag Attributes
    friendlyName: rangerplugin
    localKeyID: 54 69 6D 65 20 31 36 30 36 39 38 34 36 36 33 32 31 34
Key Attributes: <No Attributes>
-----BEGIN PRIVATE KEY-----
MIIEwAIBADANBgkqhkiG9w0BAQEFAASCBKowggSmAgEAAoIBAQDcR2Q3XDoUUjbA
Nv76ILJdDalYI35YP7FO2/LcIM8H/lgft053+UR4dlEEmxLpSZuSNhJwP0py69xA
cOGvCGJhSi+YWAUgCmL/VQkkYAVBSqLjRYOj50EmvvX9Iw9TWjmPA6EzAvOqjgPM
B9s6IOzRL6olqnmaRG0YLL+XiOKcVJ1j3QIM7GrqnY3wZPhzpEyJrD+EfK0TTDOj
60BuBQu+RHGD23NAhOVNcIy/aLi4iH4jQl5yX1nE39Ga4SXCKvxUO8X85XA6qYlt
XTYWqH0bCX9KEPEIZrrReOBZXGCq4EhuzGY6Zjbmk0/eAZKOrWogCsfNV0qA8y8d
nr9hD4yjAgMBAAECggEBANXXoJx1thRgM7KqMSGVeFIJnypnWpJFUtXhhITafOGf
suEnTM//ds8S3VgBS3yZ7qMkRwYdCyNBgZI1g4IuO4ODR203ldIjAzQo0zUy2icm
U7cals8ZAxCgNaHG1WvvnQ0PUwB4jyA1uc3qmpJ1wDDbeuwR8PcoElhzqJNtWcC0
Pu5/6QypT+VziuqGj8ssHxQmFQjxDKPVpkKZjGfWZomJSds9dEvgQAzjiiA6PuK0
Q1KzOJbxdr6UZuhIao7g73aZzyP8ZcjS2EP7TJuY3ltw0ZgN01u/5ylD1rzklKId
T99FCOu1CPWLWK52GyZ2oc20bZwF3VTiOYe7SwXYQVECgYEA8VKktvaFPiWawmmg
z1PakVWfClIwV+5hqdRRj/QyREOVtvXj65bA3JaA6+O0khde81+U8T4G5g9L3DNi
Ax/E3zPO8ekNEJNujzTr2ElAc3/tDTwOWBI2KAdqlDUMLv2CVFpwx0vzf+MR9LlS
iJx43ldMI5GPV2DDraNPo6jro9UCgYEA6a0Y4KgYFN2GpPAw5ciTx5RPvXHyHQiD
6GR/HMQTHiKinJE8qwr0HksiCsPAtWeuo9pJ8BSvsk+UNcxBIjwd5uNfFZPDN7Vb
++g6D7i8AXHIRbF3Q9INHs/GC/OpHwUuj8PEKmBFxlmWqCzO/0XWCOXT2Xtyer9s
gR+04/IBQpcCgYEAyQCYF5kwFDqIM+R9QBNNGv6hEJyyjZsNl8I0CV5RvBA7FICs
zd7sVw+45EHudjynJrl3OpT6dAdLnWbi/U0p0uu5ND90VVknnnpq8uTYnRtxnDNo
kyzgFOlQeY/RzRX0x0Ppaea2M9AzdY4i04zZFADMd1fXd+UuN2OugtfBJd0CgYEA
nuC5LG49yVoBJP3GUUV57NWTDdx+YG0cupIxts49rVyhMVCybh0Jc9tjruv/h5eS
LwfJA7oc52CiBZ31nyA+uHBZguMvdR4TB4iSiYPyGA1TvMb3rx4PG6brIc8uas/s
I4VYR/OjHURmYbvtlbTW3L/etVzwrjKexIBZTi6J2ssCgYEA2jlfTq+C1Z1UPcoT
XOI8wnAwpvrYMMQRgQE+ZCf5kVZtTskZKSIVWY2CRa+lKmwwt1x7DJFf//Bns57N
NA0DZ7xN+3iggEVykDoGB5m+XdephPNvzRd3dqwa3wKfNSpAu9ET0PgYaAzgaw3R
4V8AmhPr6RKeSooeHHghHc5bBfg=
-----END PRIVATE KEY-----

```
将Ranger Admin Public 证书放到 Secrets Manager中

![Secrets Manager Admin](./Pictures/SecretsManager-admin.png)

将Ranger Plugin Private Key 放到 Secrets Manager中

![Secrets Manager Plugin](./Pictures/SecretsManager-plugin.png)

**记录两个Secrets的ARN，后续在IAM Policy和EMR Security Configuration中都将使用**

注意： Secrets ARN中Secrets Name后面的字符串（-xxxxxx）为Secrets version，建议去掉version所代表的字符串，允许访问所有version的Secrets

```
Secrets Manager ARN 如下：
arn:aws:secretsmanager:ap-northeast-1:699962710372:secret:RangerAdminSecretsName
arn:aws:secretsmanager:ap-northeast-1:699962710372:secret:RangerPluginSecretsName
```

## III. 创建RangerPlugin所需的IAM Policy和IAM Role

RangerPlugin需要两项IAM配置：
 - Ranger Plugin Data Access Role： 用于给Ranger RecordServer访问S3，如果使用Glue Metastore，还需要授予Glue的权限
 - Add IAM Policy to EMR EC2 Default Role：给EMR EC2 DefaultRole添加RangerPlugin所需的权限，例如Secrets Manager

1. 首先创建RangerPluginDataAccessPolicy，并将Policy添加到RangerPluginDataAccessRole中
在RangerPluginDataAccessRole的Trust relationship中，需要Trust EMR_EC2_DefaultRole 

```
##IAM Policy: RangerPluginDataAccessPolicy

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CloudwatchLogsPermissions",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": [
          "arn:aws:logs:*<REGION>*:*<AWS ACCOUNT ID>*:*<CLOUDWATCH LOG GROUP NAME IN SECURITY CONFIGURATION>*"
      ]
    },
    {
      "Sid": "BucketPermissionsInS3Buckets",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:ListAllMyBuckets",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::bucket1",
        "arn:aws:s3:::bucket2"
        ]
    },
    {
      "Sid": "ObjectPermissionsInS3Objects",
      "Action": [
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": [ 
          "arn:aws:s3:::bucket1/*",
          "arn:aws:s3:::bucket2/*"
        ]
    }
  ]
}

```

2. 默认EMR的节点会使用EMR_EC2_DefaultRole，但是需要为DefaultRole添加RangerPlugin需要的权限，例如访问Secrets Manager，Assume RangerPluginDataAccessRole的权限

首先创建如下IAM Policy，并将该IAM Policy添加到EMR_EC2_DefaultRole中
```
## IAM Policy: Ranger-EMR-EC2-Role-AddPolicy
## 注意SecretsManager Resource中的ARN不要带version信息
   {
      "Sid": "AllowAssumeOfRolesAndTagging",
      "Effect": "Allow",
      "Action": ["sts:TagSession", "sts:AssumeRole"],
      "Resource": [
        "arn:aws:iam::*<AWS ACCOUNT ID>*:role/*<RANGER ENGINE/PLUGIN DATA ACCESS ROLE NAME>*",
        "arn:aws:iam::*<AWS ACCOUNT ID>*:role/*<ROLE FOR OTHER AWS SERVICES>*"
      ]
    },
    {
        "Sid": "AllowSecretsRetrieval",
        "Effect": "Allow",
        "Action": "secretsmanager:GetSecretValue",
        "Resource": [
            "arn:aws:secretsmanager:*<REGION>*:*<AWS ACCOUNT ID>*:secret:*<PLUGIN TLS SECRET NAME>**",
            "arn:aws:secretsmanager:*<REGION>*:*<AWS ACCOUNT ID>*:secret:*<ADMIN RANGER SERVER TLS SECRET NAME>**"
        ]
    },
    {
        "Sid": "CloudwatchLogsPermissions",
        "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
        ],
        "Effect": "Allow",
        "Resource": [
            "arn:aws:logs:*<REGION>*:*<AWS ACCOUNT ID>*:*<CLOUDWATCH LOG GROUP NAME IN SECURITY CONFIGURATION>*"
        ]
    }

```


## IV. 创建EMR Security Configuration

创建EMR Security Configuration，需要指定：
 - Ranger Admin Server hostname/IP
 - Data Access Role ARN
 - RangerAdmin和RangerPlugin在Secrets Manager的ARN
 - PolicyRepositoryName：需要为每个Ranger Plugin指定Ranger Admin上配置的Service Repository Name

**注意：PolicyRepositoryName必须与Ranger Admin Server中的Service Repository Name一致**

```
{
   "EncryptionConfiguration":{
      "EnableInTransitEncryption":false,
      "EnableAtRestEncryption":false
   },
   "AuthenticationConfiguration":{
      "KerberosConfiguration":{
         "Provider":"ClusterDedicatedKdc",
         "ClusterDedicatedKdcConfiguration":{
            "TicketLifetimeInHours":24
         }
      }
   },
   "AuthorizationConfiguration":{
      "RangerConfiguration":{
         "AdminServerURL":"https://*<RANGER ADMIN SERVER IP>*:6182",
         "RoleForRangerPluginsARN":"arn:aws:iam::*<AWS ACCOUNT ID>*:role/*<RANGER PLUGIN DATA ACCESS ROLE NAME>*",
         "RoleForOtherAWSServicesARN":"arn:aws:iam::*<AWS ACCOUNT ID>*:role/*<USER ACCESS ROLE NAME>*",
         "AdminServerSecretARN":"arn:aws:secretsmanager:us-east-1:*<AWS ACCOUNT ID>*:secret:*<SECRET NAME THAT PROVIDES ADMIN SERVERS PUBLIC TLS CERTICATE WITHOUT VERSION>*",
         "RangerPluginConfigurations":[
            {
               "App":"Spark",
               "ClientSecretARN":"arn:aws:secretsmanager:us-east-1:*<AWS ACCOUNT ID>*:secret:*<SECRET NAME THAT PROVIDES SPARK PLUGIN PRIVATE TLS CERTICATE WITHOUT VERSION>*",
               "PolicyRepositoryName":"amazonemrspark"
            },
            {
               "App":"Hive",
               "ClientSecretARN":"arn:aws:secretsmanager:us-east-1:*<AWS ACCOUNT ID>*:secret:*<SECRET NAME THAT PROVIDES HIVE PLUGIN PRIVATE TLS CERTICATE WITHOUT VERSION>*",
               "PolicyRepositoryName":"amazonemrhive"
            },
            {
               "App":"EMRFS-S3",
               "ClientSecretARN":"arn:aws:secretsmanager:us-east-1:*<AWS ACCOUNT ID>*:secret:*<SECRET NAME THAT PROVIDES EMRFS S3 PLUGIN PRIVATE TLS CERTICATE WITHOUT VERSION>*",
               "PolicyRepositoryName":"amazonemrs3"
            }
         ],
         "AuditConfiguration":{
            "Destinations":{
               "AmazonCloudWatchLogs":{
                  "CloudWatchLogGroup":"arn:aws:logs:us-east-1:*<AWS ACCOUNT ID>*:log-group:*<LOG GROUP NAME FOR AUDIT EVENTS>*"
               }
            }
         }
      }
   }
}
```
**通过AWS CLI，从JSON文件创建Security Configuratin**
```
aws emr create-security-configuration --name RangerSpark-SecurityConfiguration --security-configuration file://./RangerSpark-SecurityConfiguration.json
```

## V. 启动EMR集群

可以选择创建EMR集群启动脚本，或者从Console启动EMR集群

如果选择脚本启动，参考脚本如下：create_emr_ranger_cluster.sh
需要指定：
 - Cluster Name 和 版本
 - Cluster Configuration (optional)
 - Security Configuration Name
 - Security Configuration中的Kerberos配置，包括Realm和KdcAdminPassword
 - EMR applications
 - Instance count
 - Bootstrap scripts

```
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
CLUSTER_CONFIG="file://./EMR-ClusterConfiguration.json"

# Keberos Details
KERBEROS_PASSWORD="amazon" # password for Kerberos KDC 
REALM="EC2.INTERNAL" # Kerberos Realm as per Security Config

# Bootstrap scripts 
RPM_REPLACEMENT_SCRIPT=s3://repo.ap-northeast-1.emr-bda.amazonaws.com/replace_rpms.sh 
PUPPET_UPGRADE_SCRIPT=s3://repo.ap-northeast-1.emr-bda.amazonaws.com/update_puppet.sh 
PUPPET_SCRIPTS_REPLACEMENT=s3://repo.ap-northeast-1.emr-bda.amazonaws.com/replace_puppet.sh 
REPLACE_NODE_PROVISIONER=s3://repo.ap-northeast-1.emr-bda.amazonaws.com/replace_node_provisioner.sh
ZEPPELIN_SCRIPT=s3://hxh-tokyo/EMR-Managed-Ranger/zeppelin/zeppelin-bootstrap.sh

# Create the cluster.
aws emr create-cluster --profile $AWS_CREDENTIALS_PROFILE \
--region $REGION \
--name "EMR-Ranger-Test_"$(date +"%Y-%m-%d-%T") \
--release-label $RELEASE_LABEL \
--use-default-roles \
--enable-debugging \
--configurations $CLUSTER_CONFIG \
--security-configuration $SECURITY_CONFIG \
--kerberos-attributes Realm=$REALM,KdcAdminPassword=$KERBEROS_PASSWORD \
--ec2-attributes KeyName=$KEYPAIR,SubnetId=$SUBNET_ID \
--instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=$INSTANCE_TYPE \
InstanceGroupType=CORE,InstanceCount=$CORE_NODES,InstanceType=$INSTANCE_TYPE \
--ebs-root-volume-size 50 \
--applications Name=Spark Name=Livy Name=Hive Name=Hue Name=Hadoop Name=Zeppelin \
--log-uri $LOG_URI \
--additional-info '{"clusterType":"development"}' \
--bootstrap-actions \
Name='Replace RPMs',Path="$RPM_REPLACEMENT_SCRIPT" \
Name='Upgrade Puppet',Path="$PUPPET_UPGRADE_SCRIPT" \
Name='Replace Puppet Scripts Plugin',Path="$PUPPET_SCRIPTS_REPLACEMENT" \
Name='Replace Node Provisioner',Path="$REPLACE_NODE_PROVISIONER" \
Name='Zeppelin script',Path="$ZEPPELIN_SCRIPT"

```
运行create_emr_ranger_cluster.sh，即自动创建EMR集群。


## VI. 验证Ranger策略

1. 登录Ranger Admin，查看EMR上Ranger Plugin的状态

![Ranger Plugin Status](./Pictures/RangerPlugin-status.png)

2. 登录EMR Master节点，执行查询命令，测试Ranger授权情况
例如执行Spark-SQL，提示hadoop用户对hive-metastore中的数据库无任何权限
```
[hadoop@ip-172-31-34-201 ~]$ spark-sql
Exception in thread "main" org.apache.spark.sql.catalyst.analysis.AccessControlException: com.amazonaws.emr.recordserver.remote.AuthorizationException: Permission Denied: User hadoop do not have Any permission on default
	at com.amazonaws.emr.recordserver.auth.AuthorizerImpl.authorize(Authorizer.scala:245)
	at com.amazonaws.emr.recordserver.handler.AuthHandler.channelRead0(AuthHandler.scala:28)
	at io.netty.channel.SimpleChannelInboundHandler.channelRead(SimpleChannelInboundHandler.java:105)
	at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:362)
	at io.netty.channel.AbstractChannelHandlerContext.invokeChannelRead(AbstractChannelHandlerContext.java:348)
	at io.netty.channel.AbstractChannelHandlerContext.fireChannelRead(AbstractChannelHandlerContext.java:340)
	at com.amazonaws.emr.recordserver.handler.UserMapperHandler.channelRead0(UserMapperHandler.scala:60)
```

3. 在Ranger Admin上配置授权策略

在amazonemrspark的Service Repository中，创建一个Policy，给hadoop用户授权所有database，table和column。
![Ranger Spark Policy](./Pictures/RangerSpark-policy.png)

查看Policy同步到对应的Spark Plugin
![Ranger Spark Plugin Sync](./Pictures/SparkPlugin-sync.png)

4. 再次在EMR Master上执行查询命令
再次执行Spark查询，即可正常执行
```
scala> spark.sql("show databases").show
+------------+
|databaseName|
+------------+
|     default|
+------------+


scala>
```


## VII. Kerberos认证

EMR集群会为每个Applicaton创建响应的Kerberos Principal，和keytab

```
##klist 查看当前Default Principal
[hadoop@ip-172-31-34-201 ~]$ klist
Ticket cache: FILE:/tmp/krb5cc_996
Default principal: hadoop/ip-172-31-34-201.ap-northeast-1.compute.internal@EC2.INTERNAL

Valid starting       Expires              Service principal
12/11/2020 07:17:18  12/11/2020 17:17:18  krbtgt/EC2.INTERNAL@EC2.INTERNAL
	renew until 12/12/2020 07:17:18
[hadoop@ip-172-31-34-201 ~]$


##查看Kerberos Principal
[hadoop@ip-172-31-34-201 ~]$ sudo kadmin.local
Authenticating as principal root/admin@EC2.INTERNAL with password.
kadmin.local:  list_principals
HTTP/ip-172-31-33-27.ap-northeast-1.compute.internal@EC2.INTERNAL
HTTP/ip-172-31-34-201.ap-northeast-1.compute.internal@EC2.INTERNAL
HTTP/ip-172-31-34-218.ap-northeast-1.compute.internal@EC2.INTERNAL
K/M@EC2.INTERNAL
emr_record_server/ip-172-31-33-27.ap-northeast-1.compute.internal@EC2.INTERNAL
emr_record_server/ip-172-31-34-201.ap-northeast-1.compute.internal@EC2.INTERNAL
emr_record_server/ip-172-31-34-218.ap-northeast-1.compute.internal@EC2.INTERNAL
hadoop/ip-172-31-33-27.ap-northeast-1.compute.internal@EC2.INTERNAL
hadoop/ip-172-31-34-201.ap-northeast-1.compute.internal@EC2.INTERNAL
hadoop/ip-172-31-34-218.ap-northeast-1.compute.internal@EC2.INTERNAL
hdfs/ip-172-31-33-27.ap-northeast-1.compute.internal@EC2.INTERNAL
hdfs/ip-172-31-34-201.ap-northeast-1.compute.internal@EC2.INTERNAL
hdfs/ip-172-31-34-218.ap-northeast-1.compute.internal@EC2.INTERNAL
hive/ip-172-31-34-201.ap-northeast-1.compute.internal@EC2.INTERNAL
host/ip-172-31-33-27.ap-northeast-1.compute.internal@EC2.INTERNAL
host/ip-172-31-34-201.ap-northeast-1.compute.internal@EC2.INTERNAL
host/ip-172-31-34-218.ap-northeast-1.compute.internal@EC2.INTERNAL
httpfs/ip-172-31-34-201.ap-northeast-1.compute.internal@EC2.INTERNAL
hue/ip-172-31-34-201.ap-northeast-1.compute.internal@EC2.INTERNAL
kadmin/admin@EC2.INTERNAL
kadmin/changepw@EC2.INTERNAL
kadmin/ip-172-31-34-201.ap-northeast-1.compute.internal@EC2.INTERNAL
kiprop/ip-172-31-34-201.ap-northeast-1.compute.internal@EC2.INTERNAL
kms/ip-172-31-34-201.ap-northeast-1.compute.internal@EC2.INTERNAL
krbtgt/EC2.INTERNAL@EC2.INTERNAL
livy/ip-172-31-34-201.ap-northeast-1.compute.internal@EC2.INTERNAL
mapred/ip-172-31-33-27.ap-northeast-1.compute.internal@EC2.INTERNAL
mapred/ip-172-31-34-201.ap-northeast-1.compute.internal@EC2.INTERNAL
mapred/ip-172-31-34-218.ap-northeast-1.compute.internal@EC2.INTERNAL
oozie/ip-172-31-34-201.ap-northeast-1.compute.internal@EC2.INTERNAL
spark/ip-172-31-34-201.ap-northeast-1.compute.internal@EC2.INTERNAL
yarn/ip-172-31-33-27.ap-northeast-1.compute.internal@EC2.INTERNAL
yarn/ip-172-31-34-201.ap-northeast-1.compute.internal@EC2.INTERNAL
yarn/ip-172-31-34-218.ap-northeast-1.compute.internal@EC2.INTERNAL
zeppelin/ip-172-31-34-201.ap-northeast-1.compute.internal@EC2.INTERNAL
kadmin.local:


##使用kinit获取principal凭证，可以使用密码，或者keytab密钥文件
[hadoop@ip-172-31-34-201 ~]$ sudo kinit -kt /etc/spark.keytab spark/ip-172-31-34-201.ap-northeast-1.compute.internal@EC2.INTERNAL

[hadoop@ip-172-31-34-201 ~]$ ls -l /etc/*.keytab
-r-------- 1 emr_record_server emr_record_server  743 Dec 11 06:50 /etc/emr_record_server.keytab
-rw------- 1 emrsecretagent    emrsecretagent       2 Dec 11 06:50 /etc/emrsecretagent.keytab
-r-------- 1 hadoop            hadoop             359 Dec 11 06:50 /etc/hadoop.keytab
-r-------- 1 hdfs              hdfs              1055 Dec 11 06:50 /etc/hdfs.keytab
-r-------- 1 hive              hive               704 Dec 11 06:51 /etc/hive.keytab
-r-------- 1 httpfs            httpfs             710 Dec 11 06:51 /etc/httpfs.keytab
-r-------- 1 hue               hue                701 Dec 11 06:53 /etc/hue.keytab
-r-------- 1 kms               kms                701 Dec 11 06:51 /etc/kms.keytab
-r-------- 1 livy              livy               704 Dec 11 06:53 /etc/livy.keytab
-r-------- 1 mapred            mapred             710 Dec 11 06:51 /etc/mapred.keytab
-r-------- 1 oozie             oozie              707 Dec 11 06:52 /etc/oozie.keytab
-r-------- 1 spark             spark              707 Dec 11 06:53 /etc/spark.keytab
-r-------- 1 yarn              yarn               704 Dec 11 06:51 /etc/yarn.keytab
-r-------- 1 zeppelin          zeppelin           365 Dec 11 06:53 /etc/zeppelin.keytab

```

## VIII. 使用Zeppelin Notebook

在EMR集群启用Kerberos认证后，在/etc/zeppelin/conf/zeppelin-env.sh中，会自动添加Kerberos相关的Principal和keytab信息。

```
export ZEPPELIN_SERVER_KERBEROS_KEYTAB="/etc/zeppelin.keytab"
export ZEPPELIN_SERVER_KERBEROS_PRINCIPAL="zeppelin/ip-172-31-42-250.ap-northeast-1.co
mpute.internal@EC2.INTERNAL"
```

而EMR中的Zeppelin Notebook登录，默认不需要认证，使用匿名用户登录，且默认使用“Zeppelin”用户名去提交Shell或Spark任务。
在Spark启用Ranger授权的情况下，直接在Zeppelin Notebook中提交Spark任务时，会有如下报错，原因是用于Ranger的RecordServer library没有添加到Zeppelin Class path中。
```
java.lang.IllegalArgumentException: Error while instantiating 'com.amazonaws.emr.recordserver.catalog.RecordServerRemoteCatalog':
```

**需要增加以下Bootstrap脚本，配置Zeppelin: zeppelin-bootstrap.sh**
```
#!/bin/bash -ex
 
instanceRole=`cat /mnt/var/lib/info/extraInstanceData.json | grep instanceRole | cut -f2 -d: | cut -f2 -d'"'`
 
if [[ "$instanceRole" == "master" ]]; then
    echo "I am on master. "

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
```

**在启动EMR集群的时候，需要添加以下配置，用于启用Zeppelin User Impersonate**
```
[
   {
      "Classification":"core-site",
      "Properties":{
         "hadoop.proxyuser.zeppelin.hosts":"*",
         "hadoop.proxyuser.zeppelin.groups":"*",
         "hadoop.proxyuser.livy.groups":"*",
         "hadoop.proxyuser.livy.hosts":"*"
      },
      "Configurations":[
      ]
   }, {
      "Classification":"hadoop-kms-site",
      "Properties":{
         "hadoop.proxyuser.zeppelin.hosts":"*",
         "hadoop.proxyuser.zeppelin.groups":"*",
         "hadoop.proxyuser.livy.groups":"*",
         "hadoop.proxyuser.livy.hosts":"*",
         "hadoop.kms.proxyuser.livy.users":"*",
         "hadoop.kms.proxyuser.livy.hosts":"*",
         "hadoop.kms.proxyuser.livy.groups":"*",
         "hadoop.kms.proxyuser.yarn.users":"*",
         "hadoop.kms.proxyuser.yarn.groups":"*",
         "hadoop.kms.proxyuser.yarn.hosts":"*",
         "hadoop.kms.proxyuser.zeppelin.groups":"*",
         "hadoop.kms.proxyuser.zeppelin.hosts":"*",
         "hadoop.kms.proxyuser.zeppelin.users":"*",
         "hadoop.proxyuser.livy.users":"*",
         "hadoop.proxyuser.zeppelin.users":"*"
      },
      "Configurations":[
      ]
   }, {
      "Classification":"livy-conf",
      "Properties":{
         "livy.superusers":"hue,livy",
         "livy.repl.enable-hive-context":"true",
         "livy.impersonation.enabled":"true"
      },
      "Configurations":[
      ]
   }
]
```

### 为Zeppelin启用认证
Zeppelin使用Shiro，可提供UsernamePassword/LDAP/AD的认证方式，只能启用一种认证方式，否则Zeppelin服务会有问题。

首先登录EMR Master，为Zeppelin启用账号密码认证，用于登录修改Zeppelin默认的Interpreter配置。
```
cd /etc/zeppelin/conf/
sudo cp shiro.ini.template shiro.ini

## 首先启用admin账户， 默认密码为password1
sudo sed -i "s|#admin = password1, admin|admin = password1, admin|g" shiro.ini

## 重启zeppelin服务
sudo service zeppelin restart
```

使用admin用户登录Zeppelin，默认密码password1

![Zeppelin admin](./Pictures/Zeppelin-admin.png)

默认所有任务都是通过‘Zeppelin'这个用户提交

![Before impersonate](./Pictures/Before-impersonate.png)

**修改Intepreter配置，启用User Impersonate，并保存配置。启用之后Zeppelin会使用登录的用户去提交Spark任务。**
![Spark interpreter](./Pictures/Spark-interpreter.png)

**重复上一步，为Shell，Livy的Interpreter启用User impersonate。**

### 为Zeppelin启用LDAP认证

登录EMR Master，修改/etc/zeppelin/conf/shiro.ini，注释[user]中的所有账号配置，在[main]中，添加LDAP配置。

```
##/etc/zeppelin/conf/shiro.ini 
[users]
#admin = password1, admin
#user1 = password2, role1, role2
#user2 = password3, role3
#user3 = password4, role2

[main]
ldapRealm = org.apache.zeppelin.realm.LdapGroupRealm
ldapRealm.contextFactory.environment[ldap.searchBase] = dc=ap-northeast-1,dc=compute,dc=internal
ldapRealm.contextFactory.url = ldap://ip-172-31-36-146.ap-northeast-1.compute.internal:389
ldapRealm.userDnTemplate = uid={0},dc=ap-northeast-1,dc=compute,dc=internal
ldapRealm.contextFactory.authenticationMechanism = simple

## 重启Zeppelin服务生效
sudo service zeppelin restart
```

**使用LDAP用户名密码，登录Zeppelin**

例如使用LDAP中的hive用户登录，确认用户，执行Spark查询。

**注意：由于EMR 集群启用了Kerberos认证，所以还需要在EMR集群中，为每个LDAP用户创建EMR用户，对应的Kerberos Principal，以及HDFS目录，LDAP用户登录后，才能执行Spark任务**

因为hive用户在EMR中已经存在Kerberos principal，所以可以使用Spark，但是在Ranger中，没有对hive用户授权，所以不能执行Select

![LDAP no permission](./Pictures/LDAP-nopermission.png)

在Ranger Admin的AMAZON-EMR-SPARK Service Repository中，为hive用户添加Select权限。

![Ranger-add-policy](./Pictures/Ranger-add-policy.png)


再次在Zeppelin中执行Select，验证Spark已从Ranger admin同步授权策略。

![Ranger-zeppelin](./Pictures/Ranger-zeppelin.png)


### 为LDAP用户在EMR所有节点上创建用户，Kerberos principal，HDFS用户以及目录

**需要在所有EMR节点上，包括所有Master node和Core Node，执行add-user-job.sh脚本**

脚本参数需要指定：
 - User password
 - Kerberos Realm
 - Username

```
## 下载添加用户脚本，并执行，例如添加LDAP用户User2到EMR中
aws s3 cp s3://aws-emr-bda-public/ranger-private-beta/v4/scripts/ba/add-user-job.sh .
chmod +x add-user-job.sh
./add-user-job.sh amazon EC2.INTERNAL user2

##脚本执行完成后，自动为指定的LDAP用户，创建用户，用户目录，Kerberos Principal，HDFS用户，以及用户目录
[hadoop@ip-172-31-45-35 ~]$ sudo ls -l /home/user2/
total 4
-r-------- 1 user2 root 206 Dec 15 14:54 user2.keytab
[hadoop@ip-172-31-45-35 ~]$ hadoop fs -ls /user/
Found 11 items
drwxrwxrwx   - hadoop   hadoop          0 2020-12-15 10:17 /user/hadoop
drwxr-xr-x   - mapred   mapred          0 2020-12-15 10:17 /user/history
drwxrwxrwx   - hdfs     hadoop          0 2020-12-15 13:42 /user/hive
drwxrwxrwx   - hue      hue             0 2020-12-15 10:17 /user/hue
drwxrwxrwx   - livy     livy            0 2020-12-15 10:17 /user/livy
drwxrwxrwx   - oozie    oozie           0 2020-12-15 10:19 /user/oozie
drwxrwxrwx   - root     hadoop          0 2020-12-15 10:17 /user/root
drwxrwxrwx   - spark    spark           0 2020-12-15 10:17 /user/spark
drwxr-xr-x   - user1    user1           0 2020-12-15 14:08 /user/user1
drwxr-xr-x   - user2    user2           0 2020-12-15 14:48 /user/user2
drwxrwxrwx   - zeppelin hadoop          0 2020-12-15 12:47 /user/zeppelin
[hadoop@ip-172-31-45-35 ~]$

```

脚本执行完成后，并且已经为LDAP用户在Ranger Admin上添加了权限，即可使用LDAP用户登录Zeppelin，执行Spark任务。


![LDAP-zeppelin](./Pictures/LDAP-zeppelin.png)

**注意：如果add-user-job的脚本在某个node上未执行或执行失败，则会提示User not found错误**

```
main : run as user is user2
main : requested yarn user is user2
User user2 not found
```

**注意：如果通过step提交add-user-job的脚本，则可以在所有节点上创建HDFS用户和目录，但是无法创建操作系统用户和Kerberos Principal**

**另外，提供了一个LDAP-add-user-job.sh的脚本，可以自动从LDAP中获取所有用户，并创建系统用户，Kerberos principal，HDFS用户以及目录，供参考**

