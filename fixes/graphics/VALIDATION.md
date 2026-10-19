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
