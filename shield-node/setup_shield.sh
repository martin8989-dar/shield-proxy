#!/bin/bash
# Script para configurar el servidor publico (Nodo Escudo)
# Ejecutar con sudo: sudo bash setup_shield.sh

if [ "$EUID" -ne 0 ]; then
    echo "Por favor corre este script con sudo"
    exit 1
fi

echo "1. Instalando wireguard, nginx y ufw..."
apt-get update -y
apt-get install -y wireguard nginx ufw curl

echo "2. Activando el reenvio de paquetes IP en el sistema..."
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward=1

echo "3. Creando las llaves de WireGuard..."
mkdir -p /etc/wireguard
chmod 700 /etc/wireguard

if [ ! -f /etc/wireguard/privatekey ]; then
    wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
fi

PRIV_KEY=$(cat /etc/wireguard/privatekey)
PUB_KEY=$(cat /etc/wireguard/publickey)
# Reemplazar este valor cuando tengamos la llave publica del servidor de la oficina
OFFICE_PUB_KEY="PEGAR_AQUI_LLAVE_PUBLICA_DE_LA_OFICINA"

cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = $PRIV_KEY

[Peer]
# Servidor de la oficina (10.0.0.2)
PublicKey = $OFFICE_PUB_KEY
AllowedIPs = 10.0.0.2/32
EOF

chmod 600 /etc/wireguard/wg0.conf

echo "4. Copiando la pagina de error 503 y la configuracion de Nginx..."
mkdir -p /var/www/html/errors
cp ./errors/503.html /var/www/html/errors/503.html

cp ./nginx_shield.conf /etc/nginx/sites-available/shield.conf
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/shield.conf /etc/nginx/sites-enabled/shield.conf

nginx -t
systemctl enable nginx
systemctl restart nginx

echo "5. Configurando el firewall UFW (solo puertos 80, 443 y 51820/udp)..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 51820/udp
# Dejo el puerto 22 abierto por si entramos por SSH al VPS
ufw allow 22/tcp
ufw --force enable

echo "-------------------------------------------------------"
echo "Configuracion del Nodo Escudo terminada!"
echo "Tu llave publica del escudo es: $PUB_KEY"
echo "Recuerda poner la llave publica de la oficina en /etc/wireguard/wg0.conf"
echo "y luego levantar el tunel con: sudo systemctl enable --now wg-quick@wg0"
echo "-------------------------------------------------------"
