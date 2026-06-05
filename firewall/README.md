# Firewall — nftables (Pi + PC local)

Configuração didática de firewall usando `nftables` (substituto moderno do `iptables`),
com **templates versionáveis** + **`.env` local** para nunca expor IPs reais no Git.

## Estrutura

```
firewall/
├── env.example          # Modelo de configuração (COMMITÁVEL)
├── .env                 # Configuração real (LOCAL, gitignored)
├── template-pi.conf     # Regras para o Raspberry Pi (COMMITÁVEL)
├── template-pc.conf     # Regras para desktop (COMMITÁVEL)
├── apply.sh             # Aplica template no host atual
├── abrir-porta.sh       # Helper interativo para abrir portas
├── sincronizar.sh       # Detecta containers Docker sem regra
└── README.md            # Este arquivo
```

## Conceitos de nftables (rápido)

- **Tabela** (`table inet filter`): agrupamento de chains
- **Chain** (`chain input`): onde as regras ficam
- **Hook** (`hook input priority 0`): ponto onde o kernel invoca a chain
- **Policy** (`policy drop`): regra padrão se nenhuma casar — **default deny**
- **State** (`ct state established,related accept`): conexões iniciadas por você podem voltar
- **Match** (`ip saddr ..., tcp dport ..., udp dport ...`): condições para a regra casar

### Por que `default deny`?

Se você só libera o que precisa, **tudo o mais é bloqueado automaticamente**.
É mais seguro que liberar tudo e bloquear depois (whitelist de exceções vira
blacklist de buracos).

### Estados de conexão

- `established`: pacote é RESPOSTA de uma conexão que VOCÊ abriu
- `related`: novo pacote relacionado (ex: FTP data, ICMP erro)
- `new`: pacote inicia uma conexão nova
- `invalid`: pacote malformado ou suspeito

Regra `ct state established,related accept` no topo libera a VOLTA de tudo que
você iniciou. Sem ela, **nada funciona** (navegação, downloads, etc).

## Uso

### 1. Configurar

Copie o modelo e edite com seus IPs:

```bash
cp env.example .env
nano .env
```

Exemplo de `.env`:
```
LAN_NETWORK=192.168.11.0/24
TAILSCALE_NETWORK=100.64.0.0/10
DOCKER_GATEWAY=172.17.0.1
PIHOLE_DOCKER_IP=172.17.0.4
```

### 2. Aplicar

No **Pi** (Raspberry Pi):
```bash
cd ~/firewall
sudo ./apply.sh pi
```

No **PC local** (debian):
```bash
cd ~/firewall
sudo ./apply.sh pc
```

O script:
1. Lê `.env`
2. Substitui `$VAR` no template
3. Valida sintaxe (`nft -c -f`)
4. Aplica (`nft -f`)

### 3. Validar

```bash
sudo nft list ruleset                     # ver todas as regras
sudo nft list chain inet filter input    # só a chain input
sudo nft list ruleset -a                  # com handles (para deletar)
```

### 4. KILL SWITCH (emergência)

Se travar tudo e perder acesso:

```bash
sudo nft flush ruleset
```

**ATENÇÃO**: isso apaga TUDO, incluindo chains do Docker. Após rodar, faça:
```bash
sudo systemctl restart docker   # recria as chains do Docker
```

## Scripts auxiliares

### `abrir-porta.sh`

Abre uma porta **temporariamente** (RUNTIME, some no reboot).
Pergunta porta, protocolo e origem.

```bash
sudo ./abrir-porta.sh
# Porta: 9000
# Protocolo: 1 (TCP)
# Origem: 3 (Tailscale)
# Confirma: s
```

Para tornar permanente: edite `template-*.conf` e re-rode `apply.sh`.

### `sincronizar.sh`

Detecta containers Docker rodando, extrai portas publicadas, e compara com
o firewall atual. **Sugere** regras faltando (não aplica sozinho).

```bash
./sincronizar.sh
```

Útil para auditar se algum container novo está sem regra.

## Tabela de portas

| Porta | Serviço            | Onde             | Origem            |
|-------|--------------------|------------------|-------------------|
| 22    | SSH                | Pi + PC          | LAN + Tailscale   |
| 53    | Pi-hole DNS        | Pi               | LAN + Tailscale   |
| 80    | Nginx (futuro)     | Pi               | Todos             |
| 123   | NTP                | Pi (container)   | Docker interno    |
| 7070  | Trilium Notes      | Pi (container)   | Tailscale         |
| 41641 | Tailscale daemon   | Pi + PC          | Todos             |
| 4999  | Port Tracker       | Pi (container)   | Tailscale         |
| 5335  | Unbound (DNS root) | Pi (host)        | Localhost         |
| 8080  | Site pessoal       | Pi               | Todos             |
| 8085  | Nginx secundário   | Pi (container)   | Tailscale         |
| 8443  | Pi-hole admin HTTPS| Pi (container)   | Tailscale         |
| 8800  | Pi-hole admin HTTP | Pi (container)   | Tailscale         |

## Personalizar

### Adicionar novo container

1. Descubra a porta publicada:
   ```bash
   docker ps --format '{{.Names}}\t{{.Ports}}'
   ```
2. Adicione ao `template-pi.conf` na seção **CONTAINERS VIA TAILSCALE**:
   ```
   ip saddr $TAILSCALE_NETWORK tcp dport <PORTA> accept comment "<Serviço>"
   ```
3. Re-aplique:
   ```bash
   sudo ./apply.sh pi
   ```

### Abrir porta temporária

```bash
sudo ./abrir-porta.sh
```

### Liberar uma porta para a internet (NÃO recomendado)

Edite o template, remova o `ip saddr ...` na frente da regra da porta.
**Pense bem**: significa que scanners do mundo todo vão bater na porta.

## fail2ban (proteção SSH)

Já configurado para banir 10 min após 5 tentativas falhas.

```bash
sudo fail2ban-client status sshd    # ver status
sudo fail2ban-client set sshd unbanip <IP>  # desbanir
```

Configuração em `/etc/fail2ban/jail.local`.

## Troubleshooting

**Não consigo acessar X**

1. Verifique se a porta está na chain input:
   ```bash
   sudo nft list chain inet filter input | grep dport
   ```
2. Se estiver, o problema é do serviço, não do firewall
3. Se não estiver, adicione via `abrir-porta.sh` ou edite o template

**Pi reiniciou e perdeu regras**

O firewall é RUNTIME por padrão. Para persistir:

```bash
sudo apt install nftables   # se não tiver
sudo systemctl enable nftables
sudo cp template-pi.conf /etc/nftables.conf
sudo systemctl restart nftables
```

(Isso é o próximo passo a automatizar — por enquanto, basta re-rodar
`sudo ./apply.sh pi` após cada reboot.)

**Travou o SSH**

Você tem 2 caminhos:
1. Acesso físico ao Pi (teclado + monitor) → `sudo nft flush ruleset`
2. Acesso via Tailscale (que usa UDP 41641, sempre aberto) → SSH por aí

**Docker parou de funcionar após `nft flush ruleset`**

Docker usa chains próprias (`DOCKER`, `DOCKER-FORWARD`, etc) que o `flush` apaga.
Recrie reiniciando o serviço:
```bash
sudo systemctl restart docker
```

## Por que `nftables` e não `ufw`?

- `nftables` é o sucessor moderno (kernel 3.13+)
- Sintaxe mais clara e expressiva
- Suporta sets, maps, concatenação (mais rápido que muitas regras)
- `ufw` é wrapper de `iptables-nft` por baixo, então é menos transparente
- Didático: ver o que cada regra faz, sem camada extra de abstração

## Segurança

- `.env` está no `.gitignore` — IPs reais NUNCA vão pro Git
- Templates são genéricos (placeholders `$VAR`) — versionáveis sem medo
- `default deny` policy: tudo fechado por padrão
- `fail2ban` protege SSH contra brute force
- Tailscale: rede privada sem expor portas à internet
