# Snap

Usa o mesmo pacote Linux construído no SDK 22.08, nas pastas compartilhadas de driver do snapd: `/var/lib/snapd/lib/gl`, `glvnd` e `vulkan/icd.d`. Não modifica os snaps, suas conexões ou a política AppArmor.

Testes dentro dos confinamentos Firefox/core24 e Remmina/core22: shader GLES3 com leitura correta dos pixels, GLX direto Intel e comando Vulkan com resultado conferido. Aplicativos gráficos instalados têm a interface opengl conectada; os demais não foram exercitados individualmente.

O carregador Vulkan antigo do Remmina exige VK_ICD_FILENAMES. O gerador da sessão aponta para um manifesto comum com SONAME, resolvido pela biblioteca própria de cada ambiente. Flatpak filtra essa variável e usa seu mecanismo de extensão.

Execute o instalador principal `graphics.sh --install` e saia/entre na sessão para eliminar variáveis antigas herdadas pelo menu. O gerenciador de ambiente do usuário já recebe as novas opções; processos existentes mantêm as antigas até reiniciar.

A reversão remove somente arquivos registrados e cujo conteúdo corresponde ao instalado. Arquivos de terceiros ou alterados são preservados. Bases core18/core20, aplicações de 32 bits e versões futuras não estão validadas.
