#!/bin/env bash
set +x

cat > ~/.ssh/config <<EOF
Host proxy
  HostName ${BASTION_IP}
  IdentityFile /root/.ssh/${SSH_IDENTITY_FILE}
  User ${SSH_USERNAME}
  ControlPath /tmp/ssh_proxy
  LocalForward 5432 ${DB_HOST}:${DB_PORT}
EOF

DB_HOST=${DB_HOST}
if [ "${SSH_USERNAME}" != "" ]; then
	ssh -4 -o StrictHostKeyChecking=no -i /root/.ssh/${SSH_IDENTITY_FILE} ${SSH_USERNAME}@${BASTION_IP} -L 5432:${DB_HOST}:${DB_PORT} -fNT
	#ssh -4fNT proxy
	DB_HOST="127.0.0.1"
fi

cat /data/${INIT_SCRIPTS_FOLDER}/*.sql | psql -h $DB_HOST -p ${DB_PORT} -d ${DATABASE_NAME} -1 -o /data/postgres_sql.txt
