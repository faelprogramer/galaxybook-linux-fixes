# Galaxy Book Linux Fixes

Community-driven fixes, diagnostics and workarounds for running Linux on Samsung Galaxy Book devices.

> **Current validation scope:** Samsung **767XCL / NP767XCM-K02BR**, Ubuntu **26.04**, Linux **7.0.0-38-generic**.  
> Other models or kernels must be treated as **untested** until someone reports successful results.

[Português abaixo](#português)

## Validated fixes

| Area | Problem | Status | Validated on |
|---|---|---|---|
| Bluetooth | Intel CcP / `hci_uart` support for `INT33E4` | ✅ Validated | 767XCL, Ubuntu 26.04, Linux 7.0 |
| Bluetooth | `ibt-20-1-3.sfi/.ddc` missing from initramfs | ✅ Validated | 767XCL, Ubuntu 26.04, Linux 7.0 |
| Audio | No published fix yet | ⏳ Pending documentation/validation | — |
| Battery | No published fix yet | ⏳ Pending documentation/validation | — |
| Suspend | No published fix yet | ⏳ Pending documentation/validation | — |
| Other Galaxy Book issues | Contributions welcome | 🧪 Case-by-case | — |

## Bluetooth symptoms addressed

Typical symptoms included:

```text
No default controller available
```

and:

```text
Direct firmware load for intel/ibt-20-1-3.sfi failed with error -2
Bluetooth: hci0: Failed to load Intel firmware file (-2)
```

The validated machine had `hci_uart` and `btintel` in the initramfs, while the required Intel Bluetooth firmware was missing from it. After the firmware was materialized with the exact requested names and explicitly added to dracut's `install_items`, boot logs showed:

```text
Found device firmware: intel/ibt-20-1-3.sfi
Firmware loaded
Found Intel DDC parameters: intel/ibt-20-1-3.ddc
Applying Intel DDC parameters completed
Setup complete
```

## Install the Bluetooth fix

Read [fixes/bluetooth/README.md](fixes/bluetooth/README.md) first.

```bash
chmod +x fixes/bluetooth/install.sh
sudo ./fixes/bluetooth/install.sh --instalar
```

To remove:

```bash
sudo ./fixes/bluetooth/install.sh --remover
```

## Project principles

- No compatibility claims without a real report.
- Fixes should be reversible.
- Hardware/kernel checks should fail closed.
- Diagnostics and evidence belong in the repository.
- Experimental work must be labeled as experimental.

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

# Português

Coleção comunitária de correções, diagnósticos e workarounds para Linux em notebooks Samsung Galaxy Book.

> **Escopo atualmente validado:** Samsung **767XCL / NP767XCM-K02BR**, Ubuntu **26.04**, Linux **7.0.0-38-generic**.  
> Outros modelos e kernels devem ser considerados **não testados** até recebermos relatos positivos.

## Correções validadas

| Área | Problema | Status | Validado em |
|---|---|---|---|
| Bluetooth | Suporte Intel CcP / `hci_uart` para `INT33E4` | ✅ Validado | 767XCL, Ubuntu 26.04, Linux 7.0 |
| Bluetooth | `ibt-20-1-3.sfi/.ddc` ausentes do initramfs | ✅ Validado | 767XCL, Ubuntu 26.04, Linux 7.0 |
| Áudio | Ainda sem correção publicada | ⏳ Aguardando documentação/validação | — |
| Bateria | Ainda sem correção publicada | ⏳ Aguardando documentação/validação | — |
| Suspensão | Ainda sem correção publicada | ⏳ Aguardando documentação/validação | — |
| Outros problemas | Contribuições são bem-vindas | 🧪 Caso a caso | — |

## Instalação da correção de Bluetooth

Leia primeiro [fixes/bluetooth/README.md](fixes/bluetooth/README.md).

```bash
chmod +x fixes/bluetooth/install.sh
sudo ./fixes/bluetooth/install.sh --instalar
```

Remoção:

```bash
sudo ./fixes/bluetooth/install.sh --remover
```

## Importante

Este projeto não é oficial da Samsung nem do Ubuntu. Faça backup e leia o script antes de executá-lo. As correções mexem em componentes de baixo nível do sistema e podem deixar de funcionar após atualizações de kernel.
