#!/bin/bash
# ============================================================
# ABRIR-PORTA.SH - Abre uma porta no firewall temporariamente
# ============================================================
# Uso: sudo ./abrir-porta.sh
# Interativo: pergunta porta, protocolo e origem
# Adiciona regra no chain input da tabela inet filter
# AVISO: regra é RUNTIME (some no reboot). Para tornar
# permanente, adicione ao template-$HOSTNAME.conf e re-aplique
# ============================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "ERRO: precisa de root. Use: sudo $0"
    exit 1
fi

echo "============================================"
echo "  ABERTURA DE PORTA - nftables"
echo "============================================"
echo ""

# Perguntar porta
read -p "Porta (ex: 7070): " PORTA
if ! [[ "$PORTA" =~ ^[0-9]+$ ]] || [ "$PORTA" -lt 1 ] || [ "$PORTA" -gt 65535 ]; then
    echo "ERRO: porta inválida"
    exit 1
fi

# Perguntar protocolo
echo "Protocolo:"
echo "  1) TCP"
echo "  2) UDP"
echo "  3) Ambos (TCP+UDP)"
read -p "Escolha [1-3]: " PROTO_CHOICE

# Perguntar origem
echo "Origem do tráfego:"
echo "  1) Qualquer um (internet)"
echo "  2) LAN local (192.168.11.0/24)"
echo "  3) Tailscale (100.64.0.0/10)"
echo "  4) Rede específica (digitar CIDR)"
read -p "Escolha [1-4]: " ORIGEM
case $ORIGEM in
    1) MATCH_ORIGEM="" ;;
    2) MATCH_ORIGEM="ip saddr 192.168.11.0/24" ;;
    3) MATCH_ORIGEM="ip saddr 100.64.0.0/10" ;;
    4) read -p "CIDR (ex: 10.0.0.0/8): " SADDR_NET; MATCH_ORIGEM="ip saddr $SADDR_NET" ;;
    *) echo "ERRO: opção inválida"; exit 1 ;;
esac

DATA=$(date +%Y-%m-%d)

aplicar() {
    local proto=$1
    local comment=$2
    if [ -z "$MATCH_ORIGEM" ]; then
        sudo nft "add rule inet filter input ${proto} dport $PORTA accept comment \"$comment\""
    else
        sudo nft "add rule inet filter input $MATCH_ORIGEM ${proto} dport $PORTA accept comment \"$comment\""
    fi
}

case $PROTO_CHOICE in
    1)
        COMMENT="Porta $PORTA tcp aberta manualmente em $DATA"
        MOSTRAR="sudo nft \"add rule inet filter input ${MATCH_ORIGEM:+${MATCH_ORIGEM} }tcp dport $PORTA accept comment \\\"$COMMENT\\\"\""
        ;;
    2)
        COMMENT="Porta $PORTA udp aberta manualmente em $DATA"
        MOSTRAR="sudo nft \"add rule inet filter input ${MATCH_ORIGEM:+${MATCH_ORIGEM} }udp dport $PORTA accept comment \\\"$COMMENT\\\"\""
        ;;
    3)
        COMMENT="Porta $PORTA tcp+udp aberta manualmente em $DATA"
        MOSTRAR="sudo nft \"add rule inet filter input ${MATCH_ORIGEM:+${MATCH_ORIGEM} }th dport $PORTA accept comment \\\"$COMMENT\\\"\" (gera 2 regras)"
        ;;
    *) echo "ERRO: opção inválida"; exit 1 ;;
esac

echo ""
echo "============================================"
echo "Comando(s) que será(ão) executado(s):"
echo "  $MOSTRAR"
echo "============================================"
read -p "Aplicar? [s/N]: " CONFIRMA
if [[ ! "$CONFIRMA" =~ ^[sSyY]$ ]]; then
    echo "Cancelado"
    exit 0
fi

case $PROTO_CHOICE in
    1) aplicar tcp "$COMMENT" ;;
    2) aplicar udp "$COMMENT" ;;
    3)
        COMMENT_TCP="Porta $PORTA tcp aberta manualmente em $DATA"
        COMMENT_UDP="Porta $PORTA udp aberta manualmente em $DATA"
        aplicar tcp "$COMMENT_TCP"
        aplicar udp "$COMMENT_UDP"
        ;;
esac

echo ""
echo "✓ Regra adicionada!"
echo ""
echo "Regras novas (porta $PORTA):"
nft list chain inet filter input | grep -E "dport $PORTA" || echo "(nada encontrado - erro?)"
echo ""
echo "AVISO: essa regra e RUNTIME."
echo "Para torna-la permanente, adicione ao template-*.conf"
echo "na secao correspondente e rode: sudo ./apply.sh [pi|pc]"
