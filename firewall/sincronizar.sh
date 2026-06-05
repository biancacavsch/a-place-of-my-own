#!/bin/bash
# ============================================================
# SINCRONIZAR.SH - Detecta containers Docker e sugere regras
# ============================================================
# Uso: ./sincronizar.sh
# Lê containers rodando, extrai portas publicadas, compara com
# o firewall atual e sugere regras que estão faltando.
# NÃO aplica sozinho - você decide.
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "  SINCRONIZAÇÃO: Docker ↔ Firewall"
echo "============================================"
echo ""

# Verificar docker
if ! command -v docker &> /dev/null; then
    echo "ERRO: docker não encontrado"
    exit 1
fi

# Ler containers e suas portas publicadas
echo "→ Containers rodando:"
echo "---"
DOCKER_PORTS=$(docker ps --format '{{.Names}}\t{{.Ports}}' 2>/dev/null || echo "")
if [ -z "$DOCKER_PORTS" ]; then
    echo "(nenhum container rodando ou sem permissão)"
    exit 1
fi
echo "$DOCKER_PORTS" | column -t -s $'\t'
echo "---"
echo ""

# Extrair portas publicadas (formato: 0.0.0.0:7070->8080/tcp → 7070)
echo "→ Portas publicadas (externas):"
PORTAS_DOCKER=$(echo "$DOCKER_PORTS" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+' | cut -d: -f2 | sort -un)
if [ -z "$PORTAS_DOCKER" ]; then
    PORTAS_DOCKER=$(echo "$DOCKER_PORTS" | grep -oE ':[0-9]+->' | tr -d ':' | tr -d '>' | sort -un)
fi
echo "$PORTAS_DOCKER"
echo ""

# Ler regras do firewall atual (nft pode exigir sudo)
NFT_BIN="nft"
if ! command -v nft &> /dev/null; then
    if command -v sudo &> /dev/null && sudo -n nft list tables &>/dev/null 2>&1; then
        NFT_BIN="sudo nft"
    else
        echo "→ Portas já liberadas no firewall:"
        echo "(nft não disponível - só listou Docker)"
        echo ""
        echo "============================================"
        exit 0
    fi
fi

echo "→ Portas já liberadas no firewall (inet filter, chain input):"
NFT_PORTS=$($NFT_BIN list chain inet filter input 2>/dev/null | grep -oE 'dport \{[0-9, ]+\}|dport [0-9]+' | grep -oE '[0-9]+' | sort -un || echo "")
if [ -n "$NFT_PORTS" ]; then
    echo "$NFT_PORTS"
else
    echo "(nenhuma ou firewall vazio)"
fi
echo ""

# Comparar e sugerir
echo "→ ANÁLISE:"
FALTANDO=""
for PORTA in $PORTAS_DOCKER; do
    if ! echo "$NFT_PORTS" | grep -qE "^$PORTA$"; then
        FALTANDO="$FALTANDO $PORTA"
    fi
done

if [ -z "$FALTANDO" ]; then
    echo "✓ Tudo sincronizado! Nenhuma porta Docker está sem regra no firewall."
else
    echo "⚠️  Portas Docker SEM regra no firewall:$FALTANDO"
    echo ""
    echo "Para cada uma, você pode usar o abrir-porta.sh OU adicionar manualmente:"
    for PORTA in $FALTANDO; do
        echo ""
        echo "  Porta $PORTA:"
        echo "    sudo nft add rule inet filter input tcp dport $PORTA accept comment \"Docker container\""
    done
    echo ""
    echo "Ou rode interativamente: sudo ./abrir-porta.sh"
fi
echo ""
echo "============================================"
