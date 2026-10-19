# VA-API experimental para Lakefield

Validado somente em Samsung767XCL, PCI8086:9840/144d:c18b, kernel7.0.0-38-generic. A renderização OpenGL/Vulkan e a decodificação de vídeo são funções separadas. Aqui foi necessário adicionar os motores de vídeo ao descritor i915 e implementar o descritor de produto Lakefield no driver de vídeo.

O kernel V4 conserva o framebuffer do firmware, o GGTT reservado e as restrições da solução anterior. Acrescenta VCS0/VCS2; o kernel os apresenta como vcs0/vcs1. VEBox de processamento permanece desabilitado: a documentação Lakefield Vol4 descreve seu uso somente em passagem direta. Também não se habilitam codificadores, kernels de mídia ou SFC.

O patch do media-driver usa as interfaces Gen11 com um produto Lakefield próprio, sem falsificar o identificador PCI. O GMM já tem regras Lakefield. O heap MOS, originalmente de1TiB com alocação a partir de endereços altos, é limitado ao tamanho real consultado em I915_CONTEXT_PARAM_GTT_SIZE:36bits neste notebook. A regra existente WaDummyReference permanece; compressão de mídia fica desativada.

## Fontes e compilação

- [Intel media-driver26.1.5](https://github.com/intel/media-driver/tree/1d2d8e96aeaba0471dc7fd0a7e85190519758fc5), commit1d2d8e96aeaba0471dc7fd0a7e85190519758fc5, com o patch deste diretório.
- [Intel gmmlib22.9.0](https://github.com/intel/gmmlib/tree/5f1c01f46ecbfceec59faef9bf3ba4625fc88fed), commit5f1c01f46ecbfceec59faef9bf3ba4625fc88fed, sem alteração.
- Intel UHD Graphics PRM for Lakefield, maio2021, revisão1.0: Vol4 configuração, Vol14 workarounds de mídia; usados para conferir motores, endereçamento e restrições.

`graphics.sh --build` chama este builder antes de empacotar a extensão compartilhada. Requer org.freedesktop.Sdk/x86_64/22.08 instalado e ferramentas de compilação. Fontes são obtidos por HTTPS e fixados pelos commits acima; o patch deve aplicar sem alterações inesperadas. A compilação roda como usuário comum e não tem rede dentro do SDK. `media/build.sh` gera `package/media`; `flatpak/package.py` inclui essas mesmas bibliotecas no GL.host/Snap.

A biblioteca iHD tem RUNPATH `$ORIGIN/..` para encontrar GMM no próprio pacote. Não se distribuem libc/libstdc++ nem caminhos da pasta pessoal. O empacotador recusa GLIBC superior a2.35 ou GLIBCXX superior a3.4.30. A cópia local validada usa máximas2.34/3.4.29. O build reproduz o código/configuração, não há promessa de identidade binária entre compiladores/ambientes diferentes.

Preserve as licenças upstream: media-driver contém componentes MIT/BSD e GMM tem sua própria licença MIT; o pacote copia os arquivos LICENSE/COPYING originais. O patch preserva as licenças dos arquivos alterados. Não há firmware proprietário adicional embutido.

## Instalação e uso

Use `graphics.sh --install`, que instala o pacote privado em `/opt/galaxybook-lakefield/media`, verifica hardware, kernel, marcador V4 e hashes, e atualiza o ambiente para todas as contas locais normais. Atualizar o módulo V2 para V4 em uma instalação antiga exige preparação/reinício protegido; o instalador de mídia recusa misturar versões incompatíveis e apresenta erro. Não copie um módulo sobre um kernel em uso nem o descarregue com o desktop aberto. Em uma instalação nova, o payload V4 já é o módulo correto.

Saia completamente e entre novamente. `vainfo` passa a usar iHD. `graphics.sh --verify` consulta os perfis no render node, além dos testes OpenGL/compositor. Perfis anunciados não equivalem a validação completa: os formatos efetivamente exercitados estão em [VALIDATION.md](../VALIDATION.md).

A extensão GL.host é instalada em nível de sistema; o Snap usa suas pastas de driver compartilhadas. Não se alteram permissões de sandbox, conexões ou perfis AppArmor para permitir vídeo. Aplicativos sem acesso à GPU ou compilados sem decodificadores VA-API continuam dependendo de sua configuração/compilação. Não existe garantia para todos os navegadores, formatos, arquiteturas ou runtimes.

A reversão principal `graphics.sh --disable`, seguida de reinício, desativa o módulo/ambiente privado e remove as integrações gerenciadas. Conserva /opt para histórico/restauração. O overlay gráfico Android continua separado; iHD Linux não fornece MediaCodec ao Waydroid.
