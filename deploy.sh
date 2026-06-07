#!/bin/bash
# Script de deploy: faz commit, push no GitHub e atualiza o Raspberry Pi
# Uso: ./deploy.sh "descrição das mudanças"
#
# Conecta via Tailscale (100.66.151.93), então funciona de qualquer rede
# (casa, café, trabalho, viagem).
#
# Se o Pi usa Tailscale SSH, na primeira conexão o terminal vai mostrar
# uma URL tipo https://login.tailscale.com/a/l... - abra no navegador
# para aprovar. Depois fica aprovado por um tempo.

if [ -z "$1" ]; then
  echo "ERRO: Escreva uma mensagem de commit entre aspas."
  echo "Exemplo: ./deploy.sh \"Mudei a cor do header\""
  exit 1
fi

set -e  # para o script se qualquer comando falhar

echo "📦 Enviando para o GitHub..."
git add -A
git commit -m "$1" || echo "(nada para commitar)"
git push

echo "🚀 Atualizando o Raspberry Pi..."

# Tailscale IP (funciona de qualquer rede: casa, café, viagem, etc)
PI_TAILSCALE="bianca@100.66.151.93"

# Tenta Tailscale primeiro
echo "→ Tentando Tailscale (100.66.151.93)..."
if ssh -o ConnectTimeout=10 "$PI_TAILSCALE" "cd /var/www/a-place-of-my-own && sudo git pull" 2>&1; then
    echo ""
    echo "✅ Deploy concluído!"
    echo "   http://100.66.151.93:8080 (Tailscale)"
    echo "   http://192.168.11.127:8080 (LAN, só em casa)"
    exit 0
fi

# Se falhou, pode ser Tailscale SSH pedindo aprovação
echo ""
echo "⚠️  SSH via Tailscale pediu aprovação?"
echo "   Se apareceu uma URL https://login.tailscale.com/a/... abra no navegador"
echo "   e aprove. Depois rode este script de novo."
echo ""
echo "   (Para conexão automática sem aprovação, desabilite Tailscale SSH"
echo "    no admin: https://login.tailscale.com/admin/machines)"
echo ""
read -p "Já aprovou no navegador? Tentar de novo? [s/N] " TENTAR
if [[ "$TENTAR" =~ ^[sSyY]$ ]]; then
    ssh "$PI_TAILSCALE" "cd /var/www/a-place-of-my-own && sudo git pull" && \
        echo "✅ Deploy concluído!" && exit 0
fi

# Fallback: LAN (só funciona se você está em casa)
echo "→ Tentando LAN (192.168.11.127)..."
if ssh -o ConnectTimeout=5 bianca@192.168.11.127 "cd /var/www/a-place-of-my-own && sudo git pull"; then
    echo "✅ Deploy concluído (via LAN)!"
    exit 0
fi

echo "❌ Não consegui alcançar o Pi."
echo "   - Tailscale: verifique 'tailscale status' e aprovação no browser"
echo "   - LAN: você está em casa?"
exit 1
