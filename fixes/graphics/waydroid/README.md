# Waydroid — suporte experimental

O Android usa Bionic e requer uma compilação própria. Não reutilize bibliotecas Linux/Flatpak dentro do Android. A receita usa Mesa 26.0.8, Android NDK r30, API 33, x86_64, Iris e ANV; libdrm/expat vêm dos subprojetos com hashes do Mesa.

Para compilar, obtenha o NDK r30 no site oficial Android e defina ANDROID_NDK_HOME. Compile primeiro os geradores da solução principal e execute `bash waydroid/build.sh`. O pacote inclui as dependências Android libdrm e libexpat, além das bibliotecas EGL/GLES, GBM e Vulkan.

O instalador cria uma sobreposição vendor, guarda as propriedades anteriores e ordena o serviço do contêiner depois do driver do notebook. Não apaga dados ou aplicativos Android. A atualização offline do Waydroid regenera as propriedades e reinicia somente o Android.

Foi confirmado desenho de shader com leitura correta dos pixels dentro do Android e SurfaceFlinger com Intel / OpenGL ES 3.2 Mesa 26.0.8. Isso comprova aceleração da interface, não compatibilidade de todos os jogos.

Avatar World 1.226 inclui x86_64, sem necessidade de tradução ARM. O processo carregou o driver Iris, mas o usuário relatou imagem preta; compatibilidade do jogo ainda em diagnóstico. Não apresentar o jogo como resolvido.

Reversão específica: `pkexec python3 waydroid/install.py disable`. Remove somente a sobreposição gerenciada e restaura as propriedades anteriores, preservando os dados do Android.

Diagnóstico adicional do Avatar World: falhas repetidas SIGSEGV em libc strlen, chamada por libpairipcore.so do aplicativo, com aproximadamente um segundo de vida do processo. A pilha registrada não contém Iris/ANV/EGL; a causa interna da biblioteca do jogo não foi determinada. O jogo foi encerrado para interromper o ciclo; instalação e dados preservados. Usuário confirmou que o Waydroid em si ficou mais rápido. A aceleração da interface foi validada, a execução desse jogo não.
