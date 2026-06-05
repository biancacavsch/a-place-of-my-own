#!/bin/bash
# ============================================================
# APPLY.SH - Aplica o firewall no host
# ============================================================
# Uso: sudo ./apply.sh [pi|pc]
# Carrega .env, substitui vars no template, aplica com nft
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
TIPO="${1:-pi}"
TEMPLATE="$SCRIPT_DIR/template-$TIPO.conf"
OUTPUT="/tmp/nftables-$$.conf"

# Cores
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
NC='\033[0m'

# Verificar root
if [ "$EUID" -ne 0 ]; then
    echo -e "${VERMELHO}ERRO: precisa de root. Use: sudo $0 $TIPO${NC}"
    exit 1
fi

# Verificar .env
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${VERMELHO}ERRO: $ENV_FILE não existe.${NC}"
    echo -e "${AMARELO}Copie o modelo: cp env.example .env e edite com seus IPs.${NC}"
    exit 1
fi

# Verificar template
if [ ! -f "$TEMPLATE" ]; then
    echo -e "${VERMELHO}ERRO: template $TEMPLATE não existe.${NC}"
    exit 1
fi

# Carregar variáveis do .env
# Filtrar linhas comentadas e vazias
export $(grep -v '^#' "$ENV_FILE" | grep -v '^$' | xargs)

echo -e "${AMARELO}→ Substituindo variáveis no template...${NC}"
# envsubst substitui $VAR pelos valores exportados
envsubst < "$TEMPLATE" > "$OUTPUT"

echo -e "${AMARELO}→ Validando sintaxe...${NC}"
if ! nft -c -f "$OUTPUT" 2>&1; then
    echo -e "${VERMELHO}ERRO: sintaxe inválida!${NC}"
    echo "Arquivo gerado: $OUTPUT"
    exit 1
fi

echo -e "${AMARELO}→ Aplicando regras...${NC}"
nft -f "$OUTPUT"

echo -e "${VERDE}✓ Firewall aplicado com sucesso!${NC}"
echo ""
echo "Regras ativas (primeiras 20):"
nft list ruleset | head -20
echo "..."
echo ""
echo -e "${AMARELO}Comandos úteis:${NC}"
echo "  Ver todas:   sudo nft list ruleset"
echo "  Reset total: sudo nft flush ruleset"
echo "  Estatísticas: sudo nft list ruleset -a"
rm -f "$OUTPUT"
