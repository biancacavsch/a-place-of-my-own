# Acesso ao site via Tailscale

O site roda no Raspberry Pi e é acessível de qualquer lugar via Tailscale (rede privada).

## Endereço Tailscale do Pi

**100.66.151.93**

## Serviços disponíveis via Tailscale

| Serviço | URL | Descrição |
|---|---|---|
| 🌐 Site pessoal | http://100.66.151.93:8080 | Este site (Nginx) |
| 📓 Trilium Notes | http://100.66.151.93:7070 | Anotações hierárquicas pessoais |
| 🛡️ Pi-hole (HTTP) | http://100.66.151.93:8800/admin/ | Painel admin do bloqueador de ads |
| 🔒 Pi-hole (HTTPS) | https://100.66.151.93:8443/admin/ | Painel admin via HTTPS (cert autoassinado) |
| 📡 Port Tracker | http://100.66.151.93:4999 | Monitor de portas abertas |
| 🏠 CasaOS | http://192.168.11.127 | Painel do CasaOS (só LAN) |

Você também pode ver esses links na página `/servicos.html` do site.

## Arquitetura de DNS (Pi-hole + Unbound + Tailscale)

```
Seu device (qualquer rede do mundo)
    ↓
[Tailscale VPN → 100.66.151.93]
    ↓
Pi-hole (filtra, bloqueia ads/rastreadores)
    ↓
Unbound (resolver DNS recursivo, valida DNSSEC)
    ↓
Root servers (internet DNS)
```

### O que isso te dá

- **Bloqueio de ads em qualquer rede**: 4G, WiFi público, hotel
- **Privacidade total**: nenhuma consulta DNS passa por Google/Cloudflare
- **DNSSEC validation**: garante que as respostas DNS não foram falsificadas
- **Performance**: cache local, queries mais rápidas
- **Resiliência**: se Tailscale cair, ainda funciona em casa

### Para ativar essa proteção nos seus devices

1. Acesse https://login.tailscale.com/admin/dns
2. Em **"Nameservers"**, adicione `100.66.151.93`
3. Salve
4. Pronto — todo o tráfego DNS do device passa pelo Pi-hole

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
3. Acesse qualquer um dos links acima no navegador

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

# Testar DNS
dig pi-hole.net @127.0.0.1
dig doubleclick.net @127.0.0.1    # deve retornar 0.0.0.0

# Unbound
sudo systemctl status unbound
dig internetsociety.org @127.0.0.1 -p 5335 +dnssec
```

## Containers no Pi (referência)

```bash
# Ver containers rodando
docker ps

# Ver logs de um container
docker logs -f trilium
docker logs -f pihole

# Reiniciar um container
docker restart trilium
docker restart pihole

# Editar config DNS do Pi-hole
docker exec pihole bash -c 'cat /etc/pihole/setupVars.conf | grep PIHOLE_DNS'
docker exec pihole pihole reloaddns
```

## Se algum serviço não responder

1. **Nginx:** `sudo systemctl status nginx` — reiniciar com `sudo systemctl restart nginx`
2. **Tailscale:** `sudo tailscale status` — reiniciar com `sudo systemctl restart tailscaled`
3. **Container Docker:** `docker restart <nome>` (ex: `docker restart trilium`)
4. **Site fora do ar:** `cd /var/www/a-place-of-my-own && sudo git pull`
5. **DNS quebrado:** `sudo systemctl restart unbound && docker exec pihole pihole reloaddns`

## Sobre domínio público (futuro)

Quando quiser expor o site publicamente (compartilhar com outras pessoas), as opções são:
- **Cloudflare Tunnel** (recomendado) — adiciona HTTPS + DDoS protection
- **DuckDNS + port forward** — 100% grátis, menos seguro
- **Comprar domínio** + configurar DNS

Tudo isso pode coexistir com o Tailscale sem conflito.
