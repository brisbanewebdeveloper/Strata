# Install Strata

This page is for anyone installing or updating Strata (version 0.2.5). Use the **desktop app** for a graphical
interface, or the **Terminal** for `strata launch` and coding tools. Both use released engine packages. A normal
install does not need a source checkout or a startup `.bat` file.

## Quick start

| I want | Do this |
| --- | --- |
| A window with chat | Download the installer from the [latest release](https://github.com/Niko1221/Strata/releases/latest) ([steps](#the-app)) |
| The terminal, or my coding tool | Run the one-line install, then `strata launch` ([steps](#the-terminal)) |
| DeepSeek V4.1-Flash | Pick it in the app, or run `strata launch --family deepseek41` ([model page](MODELS.md#deepseek-v41-flash)) |

[Requirements](#what-you-need) · [Desktop app](#the-app) · [Terminal](#the-terminal) ·
[Update](#updating) · [Files and folders](#where-things-are-stored) · [Build from source](SOURCE_INSTALL.md)

## What you need

| Computer | Guide |
| --- | --- |
| Windows 10/11 or Linux x86-64 with an NVIDIA RTX GPU | Use the app or the Terminal. The engine for your card is downloaded for you. [Older NVIDIA cards](OLDER_GPUS.md) use the CUDA 12 engine. DeepSeek V4.1-Flash runs on RTX 30, 40 and 50 cards in the app and the Terminal. |
| Windows or Linux x86-64 with a supported AMD Radeon | [AMD guide](AMD_HIP.md), including the card-to-package table. DeepSeek V4.1-Flash runs on the Radeon AI PRO R9700 under Linux, in the app and the Terminal. |
| Linux x86-64 with Intel Arc | [Intel Arc guide](INTEL_ARC.md); install the driver/compute runtime and check model preparation requirements |
| Apple Silicon Mac, macOS 15 or newer | [Mac guide](MAC.md). Intel Macs are not supported by the Mac package. |
| AMD Ryzen AI Max / Strix Halo | [Strix Halo guide](STRIX_HALO.md) |
| NVIDIA DGX Spark (Linux ARM64) | [DGX Spark guide](DGX_SPARK_LINUX.md). Use the Terminal; there is no desktop app for ARM64 Linux. |

Memory and disk needs depend on the **model, quantization, context and enabled features**. Check
[which model fits](MODELS.md#pick-by-memory); download size is not the same as RAM use. Unified memory counts once.
Use an SSD and leave room for helper files and model preparation. The Terminal's `--plan` prints what is missing.

Install a graphics driver that supports the package you choose. CUDA 13 packages require NVIDIA driver 580 or newer;
older NVIDIA cards use CUDA 12. AMD and Intel requirements are in their guides. Packaged GPU runtimes do not replace
hardware drivers. Models and updates need an internet connection to download.

## The app

1. Open the [latest release](https://github.com/Niko1221/Strata/releases/latest).
2. Download the one installer for your system. There is one per system, not one per graphics card:
   - **Windows:** run `Strata-0.2.9-windows-x64-setup.exe`. It installs for your user and needs no administrator rights.
   - **Linux:** make `Strata-0.2.9-linux-x86_64.AppImage` executable, then open it. If FUSE is unavailable, run the
     downloaded file with `--appimage-extract-and-run`. [Linux help](TROUBLESHOOTING.md).
   - **Mac:** open `Strata-0.2.9-macos-arm64.dmg`, drag Strata into Applications, then open it. [Mac help](MAC.md).
3. On Windows and Linux the installer has no engine inside. On first start the app shows the engine for your
   graphics card with its size and one **Download** button, with progress and resume. If you already downloaded the
   engine file, choose **I already have the file** and it installs without internet. The Mac file keeps its small
   Metal engine inside.
4. Choose a model and its storage folder, let it download, then chat. DeepSeek V4.1-Flash is in the model list on
   the supported cards ([model page](MODELS.md#deepseek-v41-flash)); it has three sizes, an 8K context and a **Speed**
   choice, Faster or Full quality.

The `strata-engine-…` and `strata-control-…` archives on the release page are components, not installers. The
installer is the same file for a first install and for an update. There is no Intel desktop installer yet; Intel Arc
runs on Linux only, through the [Terminal](INTEL_ARC.md).

The first launch can take time to check and prepare large model files. Watch its progress and logs; there is no fixed
startup time for every model or computer. Closing the desktop app stops its managed engine.

The provider order recommended here is **ISTA-DASLab, Unsloth, Gyro, then others**, when a compatible pack fits.
Current app recommendations can differ; choose the model explicitly when you want a particular provider.

## The Terminal

Install once, then use `strata launch`. The Terminal includes Python and downloads the engine for your computer.

**Linux / Mac**

```sh
curl -fsSL https://github.com/Niko1221/Strata/releases/latest/download/install.sh -o install.sh && sh install.sh
```

**Windows PowerShell**

```powershell
irm https://github.com/Niko1221/Strata/releases/latest/download/install.ps1 | iex
```

On Windows, open a **new terminal** afterwards. On Linux and Mac, if `strata` is not found, use the full path printed
by the installer (normally `~/.local/bin/strata`) or add that folder to your shell's PATH.

```sh
strata launch
```

Follow the screens to choose a model, context, storage folder and access settings. The monitor opens after startup.
Use the address printed by Strata; the default local endpoint is `http://127.0.0.1:8080`.
The Terminal opens a browser only when you add `--open`.

For a script or AI agent, inspect a plan before downloading. This example selects ISTA-DASLab Q2_0 explicitly:

```sh
strata launch --family qwen --model q2_0 --plan
strata launch --family qwen --model q2_0 --yes --no-tui
```

`--no-tui` leaves the server running in the background. Check it, connect a tool, or stop it:

```sh
strata launch --status
strata connect
strata launch --stop
```

If a model is already running with different settings, add `--restart` to replace that run; `--yes` alone does not
restart it. A restart interrupts current answers. See [all launch options](TERMINAL_LAUNCH.md),
[advanced Terminal commands](TERMINAL.md), and [agent setup](AI_SETUP.md).

## Docker (Linux)

See [DOCKER.md](DOCKER.md) for released images, NVIDIA Container Toolkit and driver requirements, and container settings.

### Docker Compose

The repository's `compose.yaml` uses the same NVIDIA image and entrypoint. Build on the machine that will run it: the image contains native CPU kernels. Compose needs the NVIDIA Container Toolkit and driver described in [DOCKER.md](DOCKER.md). The host port binds to `127.0.0.1`; the server listens inside the container on `0.0.0.0` with a required API key.

Choose a long random key in your password manager, then enter it at the hidden prompt. From the repository root, start the default Qwen IQ2_XS model:

```bash
read -rsp 'Strata API key: ' STRATA_API_KEY
export STRATA_API_KEY
docker compose config --quiet
docker compose up --build -d
docker compose logs -f strata
```

Keep the key for your clients and later Compose commands. You can put the variables in a private environment file outside the repository and pass `docker compose --env-file /path/to/strata.env ...` instead. Do not commit keys.

`STRATA_FAMILY`, `STRATA_MODEL`, `STRATA_CONTEXT`, `STRATA_VISION` and `STRATA_KV` map to the entrypoint's settings. The older `STRATA_LOW_RAM`, `STRATA_KV_STREAMING`, `STRATA_RESIDENT_BUDGET_GIB` and `STRATA_REINSTALL` mappings in `compose.yaml` are ignored by the current image; see [migration guidance](DOCKER.md#from-the-older-image). `STRATA_PORT` changes the host port; `STRATA_GPU_DEVICE` selects the host GPU (default `0`, exposed inside as GPU `0`). `STRATA_CUDA_ARCHITECTURES=89` builds for an RTX 4090 only; `STRATA_BUILD_VISION=0` skips the image encoder. Rebuild when changing build settings. No container RAM cap is imposed; if you add one, check the [model's memory requirements](MODELS.md).

Settings are saved on the `strata-data` volume. To change context, vision, KV settings or the API key, recreate the container with the new variables:

```bash
STRATA_CONTEXT=163840 docker compose up -d --force-recreate
```

Keep your chosen settings in your environment file for later starts. Verify the server from another terminal, with the same key exported there:

```bash
curl -fsS http://127.0.0.1:8080/health
curl -fsS http://127.0.0.1:8080/v1/chat/completions \
  --oauth2-bearer "$STRATA_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"model":"strata","messages":[{"role":"user","content":"Say hello in five words."}],"reasoning_effort":"none","max_tokens":64}'
```

If you change `STRATA_PORT`, use that host port in the URLs. The image's health check tests HTTP availability; `/health` also reports `loaded`, which can be false after intentional unloading. First-time downloads can outlast the health check's startup period: watch the logs rather than restarting a download because the container is marked unhealthy.

Use `docker compose stop strata` to stop serving, or `docker compose down` to remove the container and network. Both retain data; `down -v` deletes the Compose-managed data volumes.

### Huihui Swift IQ3_XXS with Compose

`compose.huihui.yaml` uses the abliterated Swift IQ3_XXS files from [huihui-ai/Huihui-Qwen3.8-Flash-Next-abliterated-GGUF](https://huggingface.co/huihui-ai/Huihui-Qwen3.8-Flash-Next-abliterated-GGUF/tree/main/swift-IQ3_XXS). It defaults to RTX 4090 CUDA architecture `89`, text only and 163,840 tokens of context. Override `STRATA_CUDA_ARCHITECTURES` for another card. Both shards total 75.97 GB; allow additional disk space for the image, pack and MTP draft layer. Release other models' VRAM and allow enough free system RAM before loading.

Download both shards from the same pinned revision:

```bash
mkdir -p models/huihui-swift-iq3_xxs
huihui_base='https://huggingface.co/huihui-ai/Huihui-Qwen3.8-Flash-Next-abliterated-GGUF/resolve/4fdf4dc4d85184e2a51f5d33d7373ce053b3ec60/swift-IQ3_XXS'
for shard in 00001 00002; do
  filename="Swift-Qwen3.8-Flash-Next-GSQ-RCO-IQ3_XXS-${shard}-of-00002.gguf"
  curl --fail --location --retry 5 --continue-at - \
    --output "models/huihui-swift-iq3_xxs/$filename" "$huihui_base/$filename" || break
done
sha256sum models/huihui-swift-iq3_xxs/*.gguf
```

Compare both hashes against the published SHA-256 values on the [pinned revision's file pages](https://huggingface.co/huihui-ai/Huihui-Qwen3.8-Flash-Next-abliterated-GGUF/tree/4fdf4dc4d85184e2a51f5d33d7373ce053b3ec60/swift-IQ3_XXS) before continuing. Repeating the download resumes partial files. For files already on another SSD, set `STRATA_GGUF_DIR` to their absolute folder path instead.

With `STRATA_API_KEY` set as above:

```bash
docker compose -f compose.yaml -f compose.huihui.yaml config --quiet
docker compose -f compose.yaml -f compose.huihui.yaml up --build -d
docker compose -f compose.yaml -f compose.huihui.yaml logs -f strata
```

The override mounts the GGUF folder read-only at `/gguf`; a missing folder fails instead of creating an empty one. The existing entrypoint prepares its tokenizer and pack from those files with `FAMILY=swift`, `MODEL=IQ3_XXS` and `GGUF_DIR=/gguf`. No checksum bypass or source edit is needed. A separate `strata-huihui-data` volume avoids reusing a pack made from ordinary Swift weights. The original Qwen MTP draft head is downloaded separately; Huihui's speed and draft acceptance need measurement on your machine.

Use both `-f` arguments on every Compose command for this model, including settings changes and shutdown:

```bash
docker compose -f compose.yaml -f compose.huihui.yaml stop strata
docker compose -f compose.yaml -f compose.huihui.yaml down
```

Compose grants GPU access but does not unload ComfyUI or Ollama. Release their GPU models before starting Strata; stop Strata to return its memory, or use its [load/unload and idle-unload controls](DETAILS.md#sharing-the-gpu-with-other-programs-optional). Automatic restart is disabled so a host restart does not load Strata into another workload's GPU memory.

## Updating

**Desktop app:** open Settings and find the update controls, check for updates, and use the offered app or engine update.
Unload running models before replacing the engine. Your model files and settings are kept.

**Terminal:**

```sh
strata update --check
strata update
strata --version
```

With a model loaded, `strata update` says which model, asks before it stops it, downloads the new engine while the model keeps
serving, stops it cleanly, updates, and asks whether to start it again with the same settings (answer no and it stays stopped;
the start line is printed). If the update fails the old engine stays in use and the model can be started again. The launch
monitor and the start screen show one quiet line when a newer engine is available; press `u` in the monitor to update.
In a script nothing is asked: `--yes` alone never stops a model (exit 7, nothing changed); `--stop-model` lets the update stop it
and `--start-again` starts it again afterwards (exit 8 if it did not start again). The next Terminal command uses the updated
Control component. The app, Control and engine have separate version numbers, so they can differ.

Use `strata components rollback` to return to the previous engine. See [update details](../packaging/UPDATES.md).
Source checkouts have a [separate update workflow](SOURCE_INSTALL.md#updating).

## Where things are stored

| Item | Default location |
| --- | --- |
| Desktop chats and host state | `~/.strata` (or `STRATA_HOME`) |
| Engine components, Windows | `%LOCALAPPDATA%\Strata\components` |
| Engine components, Linux / Mac | `$XDG_DATA_HOME/strata/components`, normally `~/.local/share/strata/components` |
| Terminal files | The `terminal` folder beside `components`; the installer prints the exact path |
| Models | The folder chosen in the app or launch screens; an existing model library is reused |

The desktop app normally proposes `Documents/Strata/Models` for a new library. The Terminal discovers saved
folders from earlier installs. Use the path shown by the app or `strata models list`, not an assumed folder name.
`--data-dir` changes where new downloads go; it does not move existing models unless you add `--move-data`.
See [model discovery](TERMINAL_LAUNCH.md#models-you-already-have).

## More options

- [Docker](DOCKER.md)
- [Build or run from a source checkout](SOURCE_INSTALL.md)
- [Multiple GPUs](MULTI_GPU.md)
- [Troubleshooting and logs](TROUBLESHOOTING.md)
- [Model compatibility](MODELS.md)
