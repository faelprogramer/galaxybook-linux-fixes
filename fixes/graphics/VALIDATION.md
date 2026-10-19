# Validação local — 18/10/2026

Hardware: Samsung 767XCL, Intel i5-L16G7, GPU 8086:9840 / subsistema 144d:c18b.
Sistema: Ubuntu 26.04.1, Linux 7.0.0-38-generic, GNOME 50.1 / Wayland; Mesa privada 26.0.8.

## Antes

- Nenhum driver ligado à função PCI da GPU; somente simpledrm para a imagem do firmware.
- OpenGL e Vulkan por llvmpipe; efeitos do desktop lentos.
- Kernel e Mesa originais sem descritor da GPU 9840.

## Testes que passaram

- Execução real de um batch i915 RCS com escrita e leitura de marcador na memória.
- Compilação e execução de shader GLES 3 com comparação exata dos 1024 pixels renderizados.
- Importação de um buffer linear 1920×1080 renderizado pela GPU em framebuffer simpledrm, sem trocar a imagem durante o pré-teste.
- GNOME com a Mesa privada; contador i915 do motor de renderização do processo do compositor com trabalho efetivamente executado. O usuário confirmou imagem utilizável e melhora clara das animações.
- Wayland: validação de geometria com VBO, textura linear e iluminação Phong com glmark2.
- X11/GLX: `direct rendering: Yes`, `Accelerated: yes`, renderizador Intel Lakefield, OpenGL core/compatibilidade 4.6 e GLES 3.2.
- Vulkan: dispositivo integrado Intel 8086:9840, API 1.4.335; vkcube renderizou 120 quadros e encerrou com sucesso. Conformidade explicitamente 0.0.0.0, sem certificação CTS.
- **Persistência:** após reinício às 22:34 de 18/10/2026 (America/Sao_Paulo), serviço ativo e habilitado, teste de shader/importação aprovado no arranque, Mesa privada no GNOME e mais de 24 segundos de trabalho acumulado do motor de renderização do compositor na verificação final. OpenGL padrão da sessão reportou `Accelerated: yes` e Intel Lakefield. Usuário também executou glxinfo/glxgears e confirmou funcionamento aparente.
- Confirmação do arranque registrada; marcador pendente removido e temporizador de reversão inicial cancelado.

## Tentativas descartadas / limites

Controle nativo do painel DSI não produziu imagem utilizável e não integra esta solução. Um primeiro serviço de inicialização esperava o monitor de confirmação e atingia timeout; a versão publicada inicia esse monitor sem bloquear. Testes de aplicações feitos antes de reiniciar o compositor ainda podiam cair em llvmpipe; os resultados finais acima são da sessão posterior ao reinício.

Não se afirma suporte upstream, certificação de toda a API, estabilidade prolongada, suspensão/retomada, vídeo acelerado ou compatibilidade com toda experiência Roblox. A integração separada do [Sober](../sober/README.md) foi depois validada com abertura normal e relato do usuário de que conseguiu jogar. Não há alegação de suporte a outra combinação de máquina/kernel. Não se publicam logs brutos com identificadores pessoais ou de sessões.


## Integração adicional, noite de 18 para 19/10/2026

- Linux compartilhado: Mesa 26.0.8, GLIBC máxima 2.34, GLIBCXX máxima 3.4.30, sem LLVM externo.
- Flatpak: SDK22.08, GNOME50/25.08 e GNOME51/26.08 passaram shader GLES3/1024 pixels, GLX direto Intel e envio Vulkan com conferência do resultado 0x4c4b4632.
- Sober: novo processo com lançamento padrão, Vulkan Intel 8086:9840, API1.4.335, swapchain1920x944.
- Snap Firefox/core24 e Remmina/core22: os três testes gráficos passaram dentro de cada confinamento; Remmina requer o manifesto comum através de VK_ICD_FILENAMES.
- Android13/API33 x86_64: teste isolado EGL/GLES3 passou; SurfaceFlinger identifica Intel Iris OpenGL ES3.2 após sobreposição e reinício.
- Avatar World1.226: versão x86_64 instalada, processo carrega driver Iris; usuário relatou tela preta. Não validado como jogável.
- Nova sessão do Ubuntu ainda necessária para limpar variáveis antigas nos processos do menu; não alegar teste posterior ao login enquanto não realizado.

Não houve certificação CTS, teste de todas as aplicações Snap nem validação de versões futuras.

Diagnóstico adicional do Avatar World: falhas repetidas SIGSEGV em libc strlen, chamada por libpairipcore.so do aplicativo, com aproximadamente um segundo de vida do processo. A pilha registrada não contém Iris/ANV/EGL; a causa interna da biblioteca do jogo não foi determinada. O jogo foi encerrado para interromper o ciclo; instalação e dados preservados. Usuário confirmou que o Waydroid em si ficou mais rápido. A aceleração da interface foi validada, a execução desse jogo não.


## Contas múltiplas e VA-API, 19/10/2026

- Extensão GL.host global instalada; ambiente e permissão de renderização estendidos às contas locais normais, com concessão no boot e no início dos novos gerenciadores de usuário.
- Segunda conta local: teste nativo GLES3 com1024 pixels corretos e teste do mesmo shader dentro do sandbox Sober; Vulkan Intel executou comando e conferiu memória0x4c4b4632. Teste sem sessão gráfica produziu aviso do portal de documentos/FUSE, mas os testes gráficos passaram; abertura real da interface deve ser confirmada após novo login.
- Configuração efetiva de user@.service passou systemd-analyze verify. A lógica de contas futuras foi instalada; não se criou conta fictícia nem se alegou teste visual em todas as contas.
- Waydroid de outra conta ainda ativo foi identificado; a sessão antiga foi encerrada sem apagar seus dados. Lançador informa a limitação de uma sessão Android ativa.
- VA-API: reprodução de falha também diretamente no render node, além de Wayland. Ausência dos plugins Intel confirmada; máscara do módulo limita motores a RCS0/BCS0. Não há alegação de vídeo acelerado.
