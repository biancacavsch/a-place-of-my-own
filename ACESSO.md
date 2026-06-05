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

## Testes de validação (junho 2026)

Suite completa de testes via Tailscale executada em 05/06/2026:

### DNS via Tailscale (100.66.151.93)
- ✅ Domínios normais resolvem (github.com → 4.228.31.150)
- ✅ Ads do Google bloqueados (doubleclick, googleadservices, googlesyndication → 0.0.0.0)
- ✅ Ad networks bloqueados (adnxs, pubmatic, scorecardresearch, moatads → 0.0.0.0)
- ✅ Trackers bloqueados (tiktok, hotjar → 0.0.0.0)
- ✅ Cache DNS funcionando (queries repetidas retornam 3ms)
- ✅ NXDOMAIN correto (domínios inexistentes)

### Containers via Tailscale
- ✅ Site: HTTP 200 (73ms primeira vez)
- ✅ Blog: HTTP 200 (5ms)
- ✅ Trilium: HTTP 302 (login, OK)
- ✅ Pi-hole admin: HTTP 302 (login, OK)

### Rede
- ✅ Latência Tailscale: 3-9ms
- ✅ 0% packet loss

**Status: arquitetura 100% funcional.**

## Testes com listas expandidas (05/06/2026)

Após adicionar mais adlists, segunda suite de testes:

### Bloqueios confirmados
- ✅ **Google Ads (6/6):** doubleclick, googleadservices, googlesyndication, google-analytics, googletagmanager, googleads.g.doubleclick
- ✅ **Meta/Facebook (5/5):** facebook.com, connect.facebook.net, graph.facebook.com, pixel.facebook.com, fbcdn.net
- ✅ **Ad Networks (7/7):** adnxs, pubmatic, scorecardresearch, moatads, criteo, taboola, outbrain
- ✅ **Trackers diversos (7/7):** hotjar, mixpanel, segment.io, amplitude, appsflyer, branch.io, kochava
- ✅ **Trackers adicionais (5/5):** clarity.ms, crazyegg, optimizely, mouseflow, fullstory
- ✅ **Twitter Ads (3/4):** analytics/ads-twitter/syndication bloqueados (twitter.com mantém — necessário)

### Sites legítimos funcionam (sem falsos positivos)
- ✅ github.com, wikipedia.org, cloudflare.com, debian.org
- ✅ youtube.com, googlevideo.com, ytimg.com, gstatic.com
- ✅ instagram.com, whatsapp.com, telegram.org, tiktok.com
- ✅ uol.com.br, terra.com.br, g1.globo.com, folha.uol.com.br

**Status final: 🟢 EXCELENTE — bloqueios amplos sem quebrar sites importantes.**

## Sobre domínio público (futuro)

Quando quiser expor o site publicamente (compartilhar com outras pessoas), as opções são:
- **Cloudflare Tunnel** (recomendado) — adiciona HTTPS + DDoS protection
- **DuckDNS + port forward** — 100% grátis, menos seguro
- **Comprar domínio** + configurar DNS

Tudo isso pode coexistir com o Tailscale sem conflito.
