#!/bin/bash

declare -a cleanupARR
declare -a cleanupLBARR
declare -a dbInstanceARR

aws ec2 describe-instances --filter Name=instance-state-code,Values=16 --output table | grep InstanceId | sed "s/|//g" | tr -d ' ' | sed "s/InstanceId//g"

mapfile -t cleanupARR < <(aws ec2 describe-instances --filter Name=instance-state-code,Values=16 --output table | grep InstanceId | sed "s/|//g" | tr -d ' ' | sed "s/InstanceId//g")

echo "the output is ${cleanupARR[@]}"

aws ec2 terminate-instances --instance-ids ${cleanupARR[@]} 

aws ec2 wait instance-terminated --instance-ids ${cleanupARR[@]}


echo "Cleaning up existing Load Balancers"
mapfile -t cleanupLBARR < <(aws elb describe-load-balancers --output json | grep LoadBalancerName | sed "s/[\"\:\, ]//g" | sed "s/LoadBalancerName//g")

echo "The LBs are ${cleanupLBARR[@]}"
LAUNCHCONF=(`aws autoscaling describe-launch-configurations --output json | grep LaunchConfigurationName | sed "s/[\"\:\, ]//g" | sed "s/LaunchConfigurationName//g"`)

SCALENAME=(`aws autoscaling describe-auto-scaling-groups --output json | grep AutoScalingGroupName | sed "s/[\"\:\, ]//g" | sed "s/AutoScalingGroupName//g"`)

echo "The asgs are: " ${SCALENAME[@]}
echo "the number is: " ${#SCALENAME[@]}

LENGTH=${#cleanupLBARR[@]}
echo "ARRAY LENGTH IS $LENGTH"
for (( i=0; i<${LENGTH}; i++)); 
  do
  aws elb delete-load-balancer --load-balancer-name ${cleanupLBARR[i]} --output text
	echo "detaching load balancer from autoscaling"
  aws autoscaling detach-load-balancers --load-balancer-names ${cleanupLBARR[i]} --auto-scaling-group-name ${SCALENAME[@]}
  sleep 1
done

LAUNCHCONF=(`aws autoscaling describe-launch-configurations --output json | grep LaunchConfigurationName | sed "s/[\"\:\, ]//g" | sed "s/LaunchConfigurationName//g"`)

SCALENAME=(`aws autoscaling describe-auto-scaling-groups --output json | grep AutoScalingGroupName | sed "s/[\"\:\, ]//g" | sed "s/AutoScalingGroupName//g"`)

echo "The asgs are: " ${SCALENAME[@]}
echo "the number of asgs is: " ${#SCALENAME[@]}

if [ ${#SCALENAME[@]} -gt 0 ]
  then
  echo "delete scale group"
  aws autoscaling update-auto-scaling-group --auto-scaling-group-name $SCALENAME --max-size 0 --min-size 0
  aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $SCALENAME
  aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $SCALENAME --force-delete
  aws autoscaling delete-launch-configuration --launch-configuration-name $LAUNCHCONF
  aws cloudwatch delete-alarms --alarm-name  IncreaseInst DecreaseInst
  aws cloudwatch delete-alarms --alarm-name  IncreaseInstSNS DecreaseInstSNS
fi

mapfile -t dbInstanceARR < <(aws rds describe-db-instances --output json | grep "\"DBInstanceIdentifier" | sed "s/[\"\:\, ]//g" | sed "s/DBInstanceIdentifier//g" )

if [ ${#dbInstanceARR[@]} -gt 0 ]
   then
   echo "Deleting existing RDS database-instances"
   LENGTH=${#dbInstanceARR[@]}  

   for (( i=0; i<${LENGTH}; i++));
      do 
      aws rds delete-db-instance --db-instance-identifier ${dbInstanceARR[i]} --skip-final-snapshot --output text
      aws rds wait db-instance-deleted --db-instance-identifier ${dbInstanceARR[i]} --output text
      sleep 1
   done
fi
#delete db subnet group

aws rds delete-db-subnet-group --db-subnet-group-name dbsgnameSN


echo "All done"


