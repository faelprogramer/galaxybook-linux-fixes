#!/usr/bin/env bash
# Local entry point. Never downloads or executes remote scripts automatically.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
action=${1:-}
if [[ -z $action ]]; then
  printf '%s\n' 'Galaxy Book S — aceleração gráfica experimental' \
    '1) Verificar a aceleração (somente leitura)' \
    '2) Confirmar tela normal após o primeiro reinício' \
    '3) Instalar/restaurar o pacote local (próximo reinício)' \
    '4) Compilar a partir dos fontes' \
    '5) Preparar dependências de compilação' \
    '6) Desativar a correção (requer reinício posterior)' '0) Sair'
  read -r -p 'Opção: ' action
fi
case "$action" in
  1|--verify) /usr/bin/bash "$root/verify.sh" ;;
  2|--confirm)
    /usr/bin/bash "$root/verify.sh"
    [[ -f /var/lib/galaxybook-lakefield/pending-first-boot ]] || { echo 'Não há confirmação pendente.'; exit 0; }
    read -r -p 'A imagem está normal e utilizável? Digite SIM para confirmar: ' answer
    [[ $answer == SIM ]] || exit 1
    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/galaxybook-lakefield"
    # Monitor uses the standard home cache, independent of XDG_CACHE_HOME.
    mkdir -p "$HOME/.cache/galaxybook-lakefield"
    cat /proc/sys/kernel/random/boot_id > "$HOME/.cache/galaxybook-lakefield/confirmed-boot"
    for ((i=0;i<10;i++)); do
      [[ -f /var/lib/galaxybook-lakefield/pending-first-boot ]] || { echo 'Tela confirmada; reversão automática cancelada.'; exit 0; }
      sleep 1
    done
    echo 'Confirmação gravada; confira o serviço de proteção.'; exit 1 ;;
  3|--install)
    if [[ -d /opt/galaxybook-lakefield ]]; then
      pkexec /usr/bin/bash "$root/restore.sh"; exit $?
    fi
    [[ -f $root/package/install.sh && -f $root/package/payload/SHA256SUMS ]] || {
      echo 'Compile primeiro ou use o pacote local validado fornecido com este script.'; exit 1;
    }
    pkexec /usr/bin/bash "$root/package/install.sh" "$(id -un)" ;;
  4|--build) /usr/bin/bash "$root/build.sh" ;;
  5|--dependencies) pkexec /usr/bin/bash "$root/prepare-dependencies.sh" ;;
  6|--disable) pkexec /usr/bin/bash "$root/uninstall.sh" ;;
  0|--help) echo 'Opções: --verify --confirm --install --build --dependencies --disable' ;;
  *) echo 'Opção inválida.' >&2; exit 2 ;;
esac
