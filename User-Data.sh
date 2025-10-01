#!/bin/bash
exec > /var/log/wordpress.log 2>&1

# Atualiza pacotes
yum update -y

# Instala Docker
yum install -y docker
systemctl enable docker
systemctl start docker
usermod -a -G docker ec2-user
echo "Docker instalado"

# Instala docker-compose (binário oficial)
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
echo "Docker Compose instalado"

yum install -y libxcrypt-compat
echo "Biblioteca libxcrypt-compat instalada (libcrypt.so.1)"

# Instala cliente NFS
yum install -y nfs-utils
echo "NFS instalado"

# Espera alguns segundos para o Docker iniciar
sleep 20

# Configuração do EFS
EFS_ID="fs-0d40b105f5979829c"
MOUNT_POINT="/mnt/efs"
EFS_DNS="${EFS_ID}.efs.us-east-1.amazonaws.com"

mkdir -p $MOUNT_POINT
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $EFS_DNS:/ $MOUNT_POINT
echo "$EFS_DNS:/ $MOUNT_POINT nfs4 defaults,_netdev 0 0" | sudo tee -a /etc/fstab

# Prepara diretório do projeto
mkdir -p /opt/wordpress
cd /opt/wordpress

# Cria arquivo docker-compose.yml
cat > docker-compose.yml <<EOF
version: '3.8'

services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress-container
    restart: always
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: wordpress-db.cmngc02qqcr4.us-east-1.rds.amazonaws.com
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: admin
      WORDPRESS_DB_PASSWORD: 02teste07
    volumes:
      - $MOUNT_POINT:/var/www/html/wp-content/uploads
EOF

# Sobe os containers
docker-compose up -d
