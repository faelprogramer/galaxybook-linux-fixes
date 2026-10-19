# Sober no Samsung Galaxy Book S Lakefield

Complemento da [correção gráfica experimental](../graphics/README.md). Requer a instalação funcional já validada para Samsung 767XCL, GPU 8086:9840 / subsistema 144d:c18b, Linux 7.0.0-38-generic e Mesa privada 26.0.8.

## Problema confirmado

O desktop acelerado não bastava para o Sober: o Flatpak usa outro conjunto de drivers Mesa, sem suporte local ao identificador Lakefield. O aplicativo encerrava com `Sober couldn't find a supported graphics device`. A GPU era acessível dentro do sandbox, mas o driver original não a reconhecia.

Uma prova Vulkan dentro do Flatpak reconheceu a GPU com o ANV corrigido. Para o próprio Sober carregar esse driver corretamente, ele foi integrado como uma **extensão gráfica local do Flatpak**, em vez de depender de bibliotecas fora do runtime.

## Aplicar

Como usuário comum, na máquina com a correção gráfica instalada e ativa:

```bash
python3 fixes/sober/install.py --install
```

Não pede senha de administrador. O instalador confere máquina, kernel, estado do serviço, integridade dos arquivos privados e runtime do Sober. A combinação validada é **Sober 1.8.0, org.gnome.Platform 51, extensão GL 26.08, x86_64**. Outra versão de runtime exige revisão.

Abra **Sober pelo menu de aplicativos**, ou execute:

```bash
~/.local/bin/sober-lakefield
```

Se o aplicativo já estava aberto antes de instalar, feche-o normalmente e reabra. Não é necessário reiniciar o computador. Em links de Roblox, o arquivo de aplicativo local preserva os tipos de URI do lançador original; não se alteram os aplicativos padrão do usuário.

O instalador cria:

- `~/.local/share/flatpak/extension/org.freedesktop.Platform.GL.lakefield/x86_64/26.08/`: ANV corrigido e seu manifesto com caminhos internos do sandbox.
- `~/.local/share/applications/org.vinegarhq.Sober.desktop`: lançador que seleciona `FLATPAK_GL_DRIVERS=lakefield:default` antes de criar o sandbox, mantendo disponíveis os componentes gráficos padrão.
- `~/.local/bin/sober-lakefield`: entrada equivalente para terminal.
- `~/.local/state/galaxybook-sober/`: eventuais backups do lançador anterior e configuração modificada. Não se distribuem esses dados pessoais.

Somente esse lançador do Sober seleciona a extensão. Ele passa `VK_DRIVER_FILES` com o manifesto dentro do runtime e `INTEL_FORCE_PROBE=9840`. Se o modo legado OpenGL estiver ligado, o instalador guarda sua configuração e desativa esse modo para usar Vulkan. Não altera drivers do sistema, não instala extensões globais do tipo `GL.host` e não concede ao aplicativo acesso à pasta `/opt`.

**Executar somente `flatpak run org.vinegarhq.Sober` não equivale ao lançador corrigido**: a seleção da extensão precisa acontecer antes da criação do sandbox. Use o menu ou `sober-lakefield`.

## Validação em 18/10/2026

- Prova Vulkan no sandbox: criação de instância e enumeração de uma GPU Intel 8086:9840 aprovadas.
- O Sober iniciou o renderizador com `Vulkan Device: Intel(R) UHD Graphics (Lakefield experimental)`, driver 26.0.8 e API 1.4.335.
- Criou swapchain 1920×944 com quatro imagens e carregou o pacote de 2991 shaders Vulkan do Roblox.
- O processo gráfico do Sober carregou o ANV da extensão e seu contador i915 mostrou execução real no motor de renderização da GPU.
- O usuário confirmou abertura normal da tela do Roblox.
- O usuário relatou que aparentemente conseguiu jogar uma experiência após a correção. Não houve medição de FPS no jogo; estabilidade prolongada, desempenho mínimo, compatibilidade com toda experiência e conformidade CTS não foram validados.

O aviso de ativação experimental da GPU é esperado. A dependência do kernel específico e os demais limites da correção do host continuam aplicáveis.

## Remover a integração do Sober

```bash
python3 fixes/sober/install.py --disable
```

Feche o Sober antes. O comando remove apenas a extensão local e os lançadores criados, restaura o lançador anterior se havia um e restaura a preferência OpenGL caso ela tenha sido alterada pelo instalador. Não remove dados, login, jogos ou a correção gráfica do desktop. O script de instalação pode ser executado novamente para restaurar a integração.

## Fontes

O binário é copiado da instalação local verificada; não é publicado aqui. Seus fontes e patches estão em [fixes/graphics](../graphics/README.md). O driver mantém suas licenças Mesa; o instalador segue a licença MIT do repositório.

A integração usa o mecanismo de [extensões locais documentado pelo Flatpak](https://docs.flatpak.org/en/latest/extension.html#unmaintained-flatpak-extensions). Consulte também a [documentação oficial de diagnóstico do Sober](https://vinegarhq.org/Sober/Troubleshooting.html). Não houve alteração do executável do Sober, Roblox, autenticação ou proteção do jogo.
