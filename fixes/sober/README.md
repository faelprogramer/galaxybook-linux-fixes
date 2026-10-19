# Sober

A solução atual usa a extensão padrão Flatpak GL.host descrita em [graphics/flatpak](../graphics/flatpak/README.md). O pacote local do Desktop inclui o driver compilado; `graphics.sh --install` instala a extensão e retira somente os atalhos especiais gerenciados pela correção anterior.

O comando normal `flatpak run org.vinegarhq.Sober` foi validado com Vulkan Intel 8086:9840 e swapchain. Não é necessário usar `flatpak run` com parâmetros extras, conceder acesso a /opt ou manter uma extensão GL.lakefield separada. O alias sober-lakefield continua disponível por compatibilidade.

O instalador deste diretório delega à integração padrão quando existe o pacote Linux compilado ao lado. A solução anterior específica do Sober permanece no histórico do Git.

O ponto de entrada de compatibilidade também encaminha à instalação gráfica global, para não voltar a limitar a correção a uma conta.
