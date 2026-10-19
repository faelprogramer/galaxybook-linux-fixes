# Flatpak e bibliotecas comuns para Snap

Mesa 26.0.8 com suporte experimental ao dispositivo exato Samsung 767XCL / Intel 8086:9840, compilado no Freedesktop SDK 22.08. O pacote requer GLIBC até 2.34 e GLIBCXX até 3.4.30; não substitui libc, libstdc++ ou LLVM dos aplicativos.

A extensão local padrão `org.freedesktop.Platform.GL.host` é ativada automaticamente. O instalador atende ramos x86_64 22.08–26.08, sem lançador especial do Sober e sem permitir acesso de aplicativos a /opt. Ramos 22.08, 25.08 e 26.08 foram testados; 23.08/24.08 têm instalação preparada, sem teste de runtime nesta máquina.

Preparação para recompilar: instale o SDK oficial `org.freedesktop.Sdk//22.08`, compile primeiro a solução principal para gerar mesa_clc/vtn_bindgen2 e execute `bash flatpak/build.sh`. As dependências Python ficam no cache do usuário. O código e os patches são locais; o arquivo Mesa baixado tem SHA256 conferido.

Instalação com pacote local: `python3 flatpak/install.py install`. Reversão: `python3 flatpak/install.py disable`. Fecha e abre novamente os aplicativos. O instalador recusa uma extensão GL.host preexistente que não seja gerenciada por esta solução.

Validação: EGL/GLES3 com desenho e leitura dos 1024 pixels; GLX direto Intel; Vulkan com envio de comando e conferência da memória produzida pela GPU. Sober voltou a abrir com `flatpak run org.vinegarhq.Sober`, Vulkan Intel e swapchain.

Não garante aplicativos sem permissão de GPU, outras arquiteturas, outros ramos ou uma implementação de gráficos própria. O suporte Lakefield permanece experimental, sem certificação CTS.
