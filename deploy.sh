#!/bin/bash
# Script de deploy: faz commit, push no GitHub e atualiza o Raspberry Pi
# Uso: ./deploy.sh "descrição das mudanças"

if [ -z "$1" ]; then
  echo "ERRO: Escreva uma mensagem de commit entre aspas."
  echo "Exemplo: ./deploy.sh \"Mudei a cor do header\""
  exit 1
fi

set -e  # para o script se qualquer comando falhar

echo "📦 Enviando para o GitHub..."
git add -A
git commit -m "$1"
git push

echo "🚀 Atualizando o Raspberry Pi..."
ssh bianca@192.168.11.127 "cd /var/www/a-place-of-my-own && sudo git pull"

echo "✅ Deploy concluído!"
echo "   http://192.168.11.127:8080"