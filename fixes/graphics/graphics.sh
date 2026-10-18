#!/usr/bin/env bash
# Mitigation only: this does not enable the Lakefield GPU.
set -euo pipefail
schema=org.gnome.desktop.interface
key=enable-animations
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/galaxybook-linux-fixes/graphics"
backup="$state_dir/animations.gvariant"
usage() {
  cat <<'HELP'
Uso (na sessão gráfica, SEM sudo):
  ./graphics.sh --diagnosticar     Consultas somente de leitura (padrão).
  ./graphics.sh --aplicar          Desativa animações GNOME; salva valor anterior.
  ./graphics.sh --restaurar        Restaura o valor anterior das animações.
  ./graphics.sh --sober-software   Abre Sober pela CPU, apenas nesta execução.
A GPU NÃO é habilitada. Execução de jogos pelo Sober permanece não validada.
HELP
}
user_session() {
  [[ $EUID -ne 0 ]] || { echo 'Execute como usuário da sessão, sem sudo.' >&2; exit 1; }
  [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]] || { echo 'Sessão D-Bus ausente.' >&2; exit 1; }
}
hardware_guard() {
  [[ $(cat /sys/class/dmi/id/sys_vendor) == 'SAMSUNG ELECTRONICS CO., LTD.' &&
     $(cat /sys/class/dmi/id/product_name) == '767XCL' ]] || {
    echo 'Modelo não validado; nenhuma alteração aplicada.' >&2; exit 1;
  }
  local dev found=false
  for dev in /sys/bus/pci/devices/*; do
    if [[ $(cat "$dev/vendor") == 0x8086 && $(cat "$dev/device") == 0x9840 ]]; then
      found=true; break
    fi
  done
  [[ $found == true ]] || { echo 'GPU 8086:9840 não encontrada.' >&2; exit 1; }
}
diagnose() {
  printf 'Kernel: '; uname -r
  printf 'Modelo: '; cat /sys/class/dmi/id/product_name
  printf 'Sessão: %s\n' "${XDG_SESSION_TYPE:-desconhecida}"
  command -v lspci >/dev/null && lspci -nnk -d 8086:9840
  local dev aliases
  for dev in /sys/bus/pci/devices/*; do
    if [[ $(cat "$dev/vendor") == 0x8086 && $(cat "$dev/device") == 0x9840 ]]; then
      if [[ -L $dev/driver ]]; then readlink -f "$dev/driver"; else echo 'GPU sem driver associado.'; fi
      if command -v modprobe >/dev/null; then
        if aliases=$(modprobe -R "$(cat "$dev/modalias")" 2>/dev/null); then
          printf 'Módulos candidatos: %s\n' "$aliases"
        else echo 'Nenhum módulo candidato para o ID PCI neste kernel.'; fi
      fi
    fi
  done
  ls -l /dev/dri 2>/dev/null || true
  command -v gsettings >/dev/null && gsettings get "$schema" "$key" || true
  if command -v glxinfo >/dev/null; then glxinfo -B || true;
  else echo 'glxinfo ausente; nenhuma ferramenta será instalada automaticamente.'; fi
  if command -v vulkaninfo >/dev/null; then vulkaninfo --summary || true;
  else echo 'vulkaninfo ausente; ausência da ferramenta não prova ausência de Vulkan.'; fi
  if command -v flatpak >/dev/null; then
    flatpak info org.vinegarhq.Sober || true
    flatpak info --show-permissions org.vinegarhq.Sober || true
  fi
  echo 'Diagnóstico concluído. Nenhuma mudança de configuração solicitada.'
}
[[ $# -le 1 ]] || { usage; exit 2; }
case ${1:---diagnosticar} in
  --diagnosticar) diagnose ;;
  --aplicar)
    user_session; hardware_guard
    [[ $(gsettings writable "$schema" "$key") == true ]] || { echo 'Configuração bloqueada.' >&2; exit 1; }
    umask 077
    mkdir -p "$state_dir"
    if [[ ! -e $backup ]]; then
      # Preserve an explicit value versus the absence of a user override.
      prior=$(dconf read /org/gnome/desktop/interface/enable-animations)
      case $prior in true|false|'') ;; *) echo 'Valor anterior inesperado.' >&2; exit 1;; esac
      (set -o noclobber; printf '%s\n' "${prior:-unset}" > "$backup")
    fi
    gsettings set "$schema" "$key" false
    [[ $(gsettings get "$schema" "$key") == false ]]
    echo 'Animações desativadas. Mitigação aplicada; aceleração da GPU continua pendente.'
    ;;
  --restaurar)
    user_session
    [[ -f $backup && ! -L $backup ]] || { echo 'Backup ausente ou inválido.' >&2; exit 1; }
    prior=$(cat "$backup")
    case $prior in
      true|false) gsettings set "$schema" "$key" "$prior" ;;
      unset) gsettings reset "$schema" "$key" ;;
      *) echo 'Backup inválido; nenhuma mudança.' >&2; exit 1 ;;
    esac
    rm -- "$backup"
    echo 'Configuração anterior das animações restaurada.'
    ;;
  --sober-software)
    user_session; hardware_guard
    echo 'Teste pela CPU. Pode ser lento; jogos e aceleração da GPU não estão validados.' >&2
    exec flatpak run --env=LIBGL_ALWAYS_SOFTWARE=1 --env=GALLIUM_DRIVER=llvmpipe \
      --env=MESA_LOADER_DRIVER_OVERRIDE=swrast org.vinegarhq.Sober
    ;;
  --help|-h) usage ;;
  *) usage; exit 2 ;;
esac
