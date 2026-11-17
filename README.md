# Esteira na nuvem — Dom Banana (privado)

Pedidos de **leitura** do Claude para a VPS, sem passar pelo computador da casa (V1.1, desde 17/11/2026).

- `pedidos/NNN-assunto-leitura.sh` — a VPS busca de 1 em 1 minuto e roda **uma vez** cada pedido cujo nome termina em `-leitura.sh`. Nome novo a cada pedido.
- `saidas/<nome>.txt` — a resposta, devolvida pela própria VPS.
- `PARAR` (arquivo na raiz) — enquanto existir, nada roda.

Regras:
- Só leitura. Instalação e qualquer mudança continuam pela esteira do computador, com o OK do Dom.
- Quem roda na VPS é o usuário `esteira` (não é root). Para abrir o sistema: `sudo -n /opt/esteira-nuvem/com-segredos <comando>` (roda como `pms`, com os segredos, que nunca aparecem na saída).
- As saídas não mostram nome, número de documento, telefone, senha ou foto.
