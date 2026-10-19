# Galaxy Book S Intel Lakefield: aceleração gráfica experimental

Validada neste **Samsung 767XCL / NP767XCM-K02BR**, GPU **8086:9840**, subsistema **144d:c18b**, Ubuntu 26.04.1, GNOME 50.1 em Wayland, kernel **7.0.0-38-generic** e Mesa **26.0.8**, em 18/10/2026. Após reinício, o desktop GNOME submeteu trabalho ao motor de renderização Intel e o OpenGL informou `Accelerated: yes`. O usuário confirmou melhora na fluidez. Consulte [VALIDATION.md](VALIDATION.md).

Esta é uma implementação local experimental, não suporte oficial da Intel/Mesa. Não generalize para outros Galaxy Books, GPUs, kernels ou distribuições.

## Diagnóstico e solução

O kernel original não reconhecia esta GPU como dispositivo i915 e a Mesa original não incluía seu identificador. O painel funcionava via simpledrm, mas o desktop usava llvmpipe, renderizando pela CPU.

A solução combina dois patches publicados aqui:

- i915: habilita apenas renderização no dispositivo exato; preserva o framebuffer do firmware e reserva sua faixa no GGTT para evitar que alocações da GPU sobrescrevam a imagem. Desativa recursos não validados, incluindo gerenciamento de energia específico da GPU e OA/perf.
- Mesa: identifica Lakefield, habilita Iris e ANV mediante opt-in e permite que Iris compartilhe buffers lineares com simpledrm. A GPU renderiza; o caminho de apresentação preserva o painel configurado pelo firmware. Há cópia pelo processador na apresentação final; isto não equivale a controle nativo completo do painel pelo i915.

As bibliotecas ficam em `/opt/galaxybook-lakefield/mesa`; o módulo fica fora da árvore padrão do kernel. Não se substituem as bibliotecas da distribuição, o i915 original, initramfs ou GRUB. O serviço verifica modelo, IDs PCI, versão do kernel e um teste real de shader/compartilhamento de framebuffer antes de liberar as variáveis de ambiente para a conta selecionada. Os dispositivos i915 ficam fora do assento gráfico padrão; o simpledrm continua controlando o painel.

O serviço usa `systemd-run --no-block` para iniciar o monitor de confirmação: esperar um monitor de dez minutos dentro de um serviço de inicialização com prazo de 65 segundos causava timeout e foi corrigido antes da validação final.

## Uso na máquina já corrigida

```bash
bash fixes/graphics/graphics.sh --verify
```

O script sem argumentos apresenta um menu. Verificar não altera configurações. `--install` restaura uma instalação local íntegra que tenha sido desativada; não recarrega o driver nem encerra a sessão atual. Se já estiver ativa, informa isso e não faz alterações.

O pacote deixado localmente na Área de Trabalho contém os binários compilados e verificados nesta máquina. **Os binários não estão no GitHub**: o repositório contém fontes, patches, instalação, verificação e reversão. Copie a pasta inteira do pacote local, não somente seu lançador.

## Compilação e instalação a partir deste repositório

Necessários o hardware exato acima, Secure Boot desativado, kernel validado, espaço para os fontes/objetos e acesso aos pacotes Ubuntu das versões indicadas. Não desative Secure Boot por conta do script: assinaturas e outras políticas não foram implementadas.

```bash
bash fixes/graphics/graphics.sh --dependencies
bash fixes/graphics/graphics.sh --build
bash fixes/graphics/graphics.sh --install
```

Dependências e instalação pedem autenticação administrativa. A compilação roda como usuário comum, usa dois processos por padrão (`JOBS=1` a `4`) e não reinicia o computador. O builder baixa a Mesa do arquivo oficial e confere SHA-256; usa o código-fonte Ubuntu `7.0.0-38.38`. Se essa versão não estiver mais disponível no repositório Ubuntu, interrompa: outra versão precisa ser revisada e recompilada, não substituída silenciosamente. Uma compilação parcial anterior pode exigir novo `XDG_CACHE_HOME`.

Depois da instalação, salve o trabalho, reinicie normalmente e entre na conta escolhida. **Em até dez minutos após o arranque**, execute:

```bash
bash fixes/graphics/graphics.sh --confirm
```

Isso verifica o renderizador e o uso da GPU pelo GNOME e pede confirmação explícita de imagem normal. Sem confirmação, o primeiro arranque desativa esta configuração e reinicia para os gráficos originais por software. O prazo começa antes do login; não deixe a máquina esperando na tela de login durante esse teste. Na máquina validada, a confirmação já foi feita e essa reversão inicial foi cancelada.

## Reversão

```bash
bash fixes/graphics/graphics.sh --disable
```

Depois reinicie. O script desativa a inicialização, remove as regras e variáveis privadas, e conserva `/opt/galaxybook-lakefield` para histórico/restauração. Não descarrega um módulo usado pelo desktop. Se a interface não abrir, use um terminal de recuperação para executar `sudo bash /opt/galaxybook-lakefield/uninstall.sh` e reinicie. Um kernel diferente também mantém o caminho gráfico original, pois o módulo é vinculado à versão validada.

## Limites conhecidos

- **Atualizações de kernel:** o módulo só foi compilado e validado para `7.0.0-38-generic`. Outro kernel volta aos gráficos originais por software. Não há DKMS e o script não bloqueia atualizações.
- Não foram validados suspensão/retomada, monitor externo, brilho, autonomia, estabilidade prolongada, vídeo acelerado ou toda a suíte de conformidade gráfica. O driver Vulkan anuncia conformidade `0.0.0.0`, pois não passou CTS; abrir uma API 1.4 não constitui certificação.
- O aviso `Forcing probe of unsupported ... Lakefield experimental` é esperado e preservado para identificar esta ativação experimental. `glxgears` e FPS isoladamente não comprovam o uso da GPU; `--verify` verifica o renderizador e o trabalho do compositor.
- **Sober/Flatpak:** funcionamento do Roblox não foi validado. O sandbox usa sua própria Mesa; corrigir a Mesa do host não garante suporte ao dispositivo dentro do Flatpak. O Flatpak testado removeu a variável privada `VK_DRIVER_FILES`, portanto o caminho `/opt` do host não foi imposto ao sandbox. A correção do desktop é independente do Sober.

## Fontes e licenças

- Linux: pacote fonte Ubuntu `linux-source-7.0.0`, versão `7.0.0-38.38`, e cabeçalhos correspondentes. As modificações do i915 seguem a licença GPL-2.0 aplicável ao kernel; consulte os avisos dos arquivos originais.
- Mesa: [arquivo oficial 26.0.8](https://archive.mesa3d.org/mesa-26.0.8.tar.xz), SHA-256 `caf1c0061a68e88dfa74967a7e780c0e85d65b6c4e334cd69095a5dc54ad78bc`. As alterações preservam as licenças dos arquivos originais Mesa, predominantemente MIT; consulte `docs/license.rst` do tarball.
- Scripts e teste local: licença MIT deste repositório. O pacote compilado local contém componentes Linux/Mesa, sujeitos às respectivas licenças; os patches e a versão exata dos fontes estão documentados aqui. Nenhum dump de BIOS, credencial ou log de conta é distribuído.
