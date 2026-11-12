#!/bin/bash
# Script para configurar el servidor de la oficina (Nodo Oficina)
# Ejecutar con sudo: sudo bash setup_office.sh

if [ "$EUID" -ne 0 ]; then
    echo "Por favor corre este script con sudo"
    exit 1
fi

echo "1. Instalando WireGuard, Python3, Flask y UFW..."
apt-get update -y
apt-get install -y wireguard python3 python3-pip python3-flask ufw

echo "2. Generando llaves de WireGuard para la oficina..."
mkdir -p /etc/wireguard
chmod 700 /etc/wireguard

if [ ! -f /etc/wireguard/privatekey ]; then
    wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
fi

PRIV_KEY=$(cat /etc/wireguard/privatekey)
PUB_KEY=$(cat /etc/wireguard/publickey)

# Cambiar estos dos datos por la IP publica y llave publica de nuestro VPS (Nodo Escudo)
SHIELD_IP="PONER_IP_PUBLICA_DEL_VPS"
SHIELD_PUB_KEY="PONER_LLAVE_PUBLICA_DEL_ESCUDO"

cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = 10.0.0.2/24
PrivateKey = $PRIV_KEY

[Peer]
PublicKey = $SHIELD_PUB_KEY
Endpoint = $SHIELD_IP:51820
AllowedIPs = 10.0.0.1/32
# Mantiene vivo el tunel detras del router NAT sin abrir puertos
PersistentKeepalive = 25
EOF

chmod 600 /etc/wireguard/wg0.conf

echo "3. Configurando el firewall local para proteger el puerto 8000..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# Solo dejamos entrar al puerto 8000 si viene desde la IP del tunel (10.0.0.1)
ufw allow from 10.0.0.1 to any port 8000 proto tcp
# Bloqueamos cualquier otro intento de entrar al puerto 8000
ufw deny 8000/tcp
ufw --force enable

echo "-------------------------------------------------------"
echo "Configuracion del Nodo Oficina lista!"
echo "Tu llave publica de la oficina es: $PUB_KEY"
echo "1. Edita /etc/wireguard/wg0.conf con la IP y llave del Nodo Escudo."
echo "2. Activa el tunel con: sudo systemctl enable --now wg-quick@wg0"
echo "3. Inicia la app web con: python3 office_app.py"
echo "-------------------------------------------------------"
