#export ENABLE_POSTPROCESSORS=1
export BASE_NAME=cb
export STACK_TYPE=CDH
export IMAGE_NAME="cb-sseth-image-`date +%y%m%d%H%M`"
export STACK_VERSION=7.2.1
export STACK_BASEURL=http://cloudera-build-us-west-1.vpc.cloudera.com/s3/build/4358108/cdh/7.x/parcels/
export STACK_REPOID=CDH-7.2.1
export STACK_REPOSITORY_VERSION=CDH-7.2.1-1.cdh7.2.1.p0.4358108
export PARCELS_NAME=CDH-7.2.1-1.cdh7.2.1.p0.4358108-el7.parcel
export PARCELS_ROOT=/opt/cloudera/parcels
export STACK_BUILD_NUMBER=4358108

export CLUSTERMANAGER_VERSION=7.2.1
export CLUSTERMANAGER_BASEURL=http://cloudera-build-us-west-1.vpc.cloudera.com/s3/build/4227375/cm7/7.2.1/redhat7/yum/
export CLUSTERMANAGER_GPGKEY=http://cloudera-build-us-west-1.vpc.cloudera.com/s3/build/4227375/cm7/7.2.1/redhat7/yum/RPM-GPG-KEY-cloudera
export CM_BUILD_NUMBER=4227375
export CFM_BUILD_NUMBER=2.0.3.0-13
export PROFILER_BUILD_NUMBER=2.0.3.0-72
export SPARK3_BUILD_NUMBER=2.99.7110.0-18
export CSA_BUILD_NUMBER=1.2.1.0-31

export VPC_ID=vpc-0966cbdb18b658ecd
export SUBNET_ID=subnet-095203f3a2844d64c

echo "================================================================="
echo "   Make sure to set the AWS ACCESS KEY env variables"
echo "================================================================="
#exit 1
export AWS_SECRET_ACCESS_KEY=
export AWS_ACCESS_KEY_ID=
