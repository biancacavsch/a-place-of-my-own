# Acesso ao site via Tailscale

O site roda no Raspberry Pi (rede local em `http://192.168.11.127:8080`) e também é acessível de qualquer lugar via Tailscale.

## URL de acesso via Tailscale

**http://100.66.151.93:8080**

Funciona em qualquer rede do mundo, desde que o device esteja logado no Tailscale com a mesma conta.

## O que é o Tailscale

Tailscale cria uma **rede privada (mesh VPN)** entre seus dispositivos usando WireGuard. É grátis para uso pessoal (até 100 devices, 1 usuário).

Vantagens:
- Sem precisar abrir portas no roteador
- Sem expor o IP público
- Sem configurar DDNS
- HTTPS não obrigatório (já que é rede privada)
- Funciona mesmo se o IP do Pi mudar

## Como acessar de outros devices

1. Instale o app Tailscale:
   - **iOS:** https://apps.apple.com/app/tailscale/id1470499037
   - **Android:** https://play.google.com/store/apps/details?id=com.tailscale.ipn
   - **Mac/Windows/Linux:** https://tailscale.com/download
2. Faça login com a **mesma conta** que usou no Pi
3. Acesse `http://100.66.151.93:8080` no navegador

## Comandos úteis no Pi

```bash
# Status
sudo tailscale status

# Ver IP Tailscale
sudo tailscale ip -4

# Pingar outro device da rede
sudo tailscale ping nome-do-device

# Reiniciar
sudo systemctl restart tailscaled

# Deslogar
sudo tailscale logout
```

## Se o site não responder via Tailscale

1. Verifique se o Nginx está rodando: `sudo systemctl status nginx`
2. Verifique se o Tailscale está logado: `sudo tailscale status`
3. Verifique conectividade: `sudo tailscale ping` em outro device
4. Reinicie o Tailscale: `sudo systemctl restart tailscaled`

## Sobre domínio público (futuro)

Quando quiser expor o site publicamente (compartilhar com outras pessoas), as opções são:
- **Cloudflare Tunnel** (recomendado) — adiciona HTTPS + DDoS protection
- **DuckDNS + port forward** — 100% grátis, menos seguro
- **Comprar domínio** + configurar DNS

Tudo isso pode coexistir com o Tailscale sem conflito.
