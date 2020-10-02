#!/bin/env bash
set +x

#aws help

cat > ~/.ssh/config <<EOF
Host proxy
  HostName ${BASTION_NAME}
  IdentityFile /root/.ssh/${SSH_IDENTITY_FILE}
  User ${SSH_USERNAME}
  ControlPath /tmp/ssh_proxy
  LocalForward ${DB_PORT} ${DB_HOST}:5432
  StrictHostKeyChecking no
  ProxyCommand sh -c "aws ssm start-session --target \$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --filters 'Name=tag:Name,Values=%h' 'Name=instance-state-name,Values=running' --output text --profile ${AWS_PROFILE} --region ${AWS_REGION}) --document-name AWS-StartSSHSession --parameters 'portNumber=%p' --profile ${AWS_PROFILE} --region ${AWS_REGION}"
EOF

DB_HOST=${DB_HOST}
if [ "${SSH_USERNAME}" != "" ]; then
	#ssh -4fNT -o StrictHostKeyChecking=no -i /root/.ssh/$_{SSH_IDENTITY_FILE} $_{SSH_USERNAME}@$_{BASTION_IP} -L 5432:$_{DB_HOST}:$_{DB_PORT}
	ssh -4fNT proxy
	DB_HOST="127.0.0.1"
fi

cat /data/${INIT_SCRIPTS_FOLDER}/*.sql | psql -h $DB_HOST -p ${DB_PORT} -d ${DATABASE_NAME} -1 -o /data/postgres_sql.txt
