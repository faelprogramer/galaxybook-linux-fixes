#!/usr/bin/env bash
# Local entry point. Never downloads or executes remote scripts automatically.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
integrate() {
  pkexec /usr/bin/bash "$root/install-integrated.sh" "$(id -un)"
  if systemctl is-active --quiet galaxybook-lakefield-graphics.service && [[ -f $root/package/flatpak-host/manifest.json ]]; then
    python3 "$root/flatpak/install.py" install --payload "$root/package/flatpak-host"
  fi
}
action=${1:-}
if [[ -z $action ]]; then
  printf '%s\n' 'Galaxy Book S — aceleração gráfica experimental' \
    '1) Verificar a aceleração (somente leitura)' \
    '2) Confirmar tela normal após o primeiro reinício' \
    '3) Instalar/restaurar sistema e integrações disponíveis' \
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
    [[ -d /opt/galaxybook-lakefield || -f $root/package/payload/SHA256SUMS ]] || {
      echo 'Compile primeiro ou use o pacote local validado fornecido com este script.'; exit 1;
    }
    integrate ;;
  4|--build)
    /usr/bin/bash "$root/build.sh"
    /usr/bin/bash "$root/flatpak/build.sh"
    if [[ -n ${ANDROID_NDK_HOME:-} ]]; then /usr/bin/bash "$root/waydroid/build.sh"; else echo 'Android: defina ANDROID_NDK_HOME (NDK r30) e execute --build-waydroid.'; fi ;;
  --build-flatpak) /usr/bin/bash "$root/flatpak/build.sh" ;;
  --build-waydroid) /usr/bin/bash "$root/waydroid/build.sh" ;;
  5|--dependencies) pkexec /usr/bin/bash "$root/prepare-dependencies.sh" ;;
  6|--disable)
    python3 "$root/flatpak/install.py" disable
    pkexec /usr/bin/bash "$root/disable-integrated.sh" ;;
  0|--help) echo 'Opções: --verify --confirm --install --build --dependencies --disable' ;;
  *) echo 'Opção inválida.' >&2; exit 2 ;;
esac
