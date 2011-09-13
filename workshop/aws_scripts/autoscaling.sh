!/bin/bash
#
# add your private key and cert
# add geoserver_ami
# add loadbalancer name

geoserver_ami=
loadbalancer=

as-create-launch-config asfoss4g --image-id $geoserver_ami \
    --instance-type t1.micro \
    --group default \
    -K ~/ec2/pk.pem \
    -C ~/ec2/cert.pem

as-create-auto-scaling-group foss4ggroup \
    --launch-configuration asfoss4g \
    --availability-zones us-east-1a \
    --min-size 3 \
    --max-size 10 \
    --load-balancers $loacbalancer \
    -K ~/ec2/pk.pem \
    -C ~/ec2/cert.pem

SCALE_UP_POLICY=`as-put-scaling-policy ScaleUpPolicy --name "scale-up" --auto-scaling-group foss4ggroup --adjustment 1 --type ChangeInCapacity --cooldown 300 -K ~/ec2/pk.pem -C ~/ec2/cert.pem`

SCALE_DOWN_POLICY=`as-put-scaling-policy ScaleDownPolicy --name "scale-down" --auto-scaling-group foss4ggroup --adjustment=-1 --type ChangeInCapacity --cooldown 300 -K ~/ec2/pk.pem -C ~/ec2/cert.pem`

mon-put-metric-alarm HighCPUAlarm \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 1 \
    --metric-name CPUUtilization \
    --namespace "AWS/EC2" \
    --period 600 \
    --statistic Average \
    --threshold 60 \
    --alarm-actions $SCALE_UP_POLICY \
    --dimensions "AutoScalingGroupName=foss4ggroup" \
    -K ~/ec2/pk.pem \
    -C ~/ec2/cert.pem

mon-put-metric-alarm LowCPUAlarm \
    --comparison-operator LessThanThreshold \
    --evaluation-periods 1 \
    --metric-name CPUUtilization \
    --namespace "AWS/EC2" \
    --period 600 \
    --statistic Average \
    --threshold 10 \
    --alarm-actions $SCALE_DOWN_POLICY \
    --dimensions "AutoScalingGroupName=foss4ggroup" \
    -K ~/ec2/pk.pem \
    -C ~/ec2/cert.pem