# Flatpak e bibliotecas comuns para Snap

Mesa 26.0.8 com suporte experimental ao dispositivo exato Samsung 767XCL / Intel 8086:9840, compilado no Freedesktop SDK 22.08. O pacote requer GLIBC até 2.34 e GLIBCXX até 3.4.30; não substitui libc, libstdc++ ou LLVM dos aplicativos.

A extensão local padrão `org.freedesktop.Platform.GL.host` é ativada automaticamente. O instalador atende ramos x86_64 22.08–26.08, sem lançador especial do Sober e sem permitir acesso de aplicativos a /opt. Ramos 22.08, 25.08 e 26.08 foram testados; 23.08/24.08 têm instalação preparada, sem teste de runtime nesta máquina.

Preparação para recompilar: instale o SDK oficial `org.freedesktop.Sdk//22.08`, compile primeiro a solução principal para gerar mesa_clc/vtn_bindgen2 e execute `bash flatpak/build.sh`. As dependências Python ficam no cache do usuário. O código e os patches são locais; o arquivo Mesa baixado tem SHA256 conferido.

Instalação padrão para todas as contas: `graphics.sh --install` (ou `pkexec python3 flatpak/install-system.py install` com o pacote local). Reversão global: `pkexec python3 flatpak/install-system.py disable`. O instalador antigo por usuário continua disponível apenas por compatibilidade. Fecha e abre novamente os aplicativos. O instalador recusa uma extensão GL.host preexistente que não seja gerenciada por esta solução.

Validação: EGL/GLES3 com desenho e leitura dos 1024 pixels; GLX direto Intel; Vulkan com envio de comando e conferência da memória produzida pela GPU. Sober voltou a abrir com `flatpak run org.vinegarhq.Sober`, Vulkan Intel e swapchain.

Não garante aplicativos sem permissão de GPU, outras arquiteturas, outros ramos ou uma implementação de gráficos própria. O suporte Lakefield permanece experimental, sem certificação CTS.


## Todas as contas locais

A extensão fica em `/var/lib/flatpak/extension/org.freedesktop.Platform.GL.host/x86_64`, no mecanismo de extensões locais de sistema do Flatpak. Contas existentes e futuras usam o mesmo pacote; jogos, contas e configurações pessoais continuam separados. O instalador remove somente antigas extensões pessoais marcadas como gerenciadas por esta solução, após concluir a cópia de sistema.


VA-API: o pacote comum também inclui iHD/GMM privados. O ambiente global contém caminhos de Linux nativo, Snap e GL.host; cada confinamento usa o caminho visível nele. Foi validada a criação de configuração H.264 High e superfície GPU1920×1080. A decodificação real com comparação integral de quadros foi validada no host, não em todos os aplicativos. Requer novo login para processos do menu receberem o ambiente. Consulte [validação](../VALIDATION.md).
