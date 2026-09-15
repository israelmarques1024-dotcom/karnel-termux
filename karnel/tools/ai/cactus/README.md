# Cactus

Cactus is an on-device inference engine for text, vision, speech, embeddings,
and RAG. Karnel installs the official `cactus-compute` 2.0.1 ARM64 package in
an Ubuntu `proot-distro` environment because its Linux wheel targets glibc,
while native Termux uses Android/Bionic.

If the installed Ubuntu container uses Python 3.14 or newer, Karnel provisions
an isolated upstream-compatible Python 3.13 runtime with `uv`; it does not
replace the container's system Python.

## Install

```bash
karnel install ai --cactus
cactus --help
cactus run Cactus-Compute/needle
```

Other examples:

```bash
cactus download Cactus-Compute/needle
cactus list
cactus serve Cactus-Compute/needle
```

The first model download can be large and inference performance depends on the
device's RAM, storage, and thermal limits. Cactus is currently enabled only on
ARM64 because that is the Linux wheel published by the upstream project.

The upstream ARM64 wheel is compiled for ARMv8.1+ CPUs (LSE atomics, fp16 and
dot-product extensions). On devices whose `/proc/cpuinfo` does not advertise
these (`atomics`/`lse`, `fp16`/`asimdhp`, `dotprod`/`asimddp`), the prebuilt
binary aborts with `SIGILL` (e.g. at `ldaddal` or `sdot`). On such CPUs Karnel
installs `qemu-user` inside the container and runs the native inference binary
under `qemu-aarch64 -cpu max`: the CLI still works, but inference is extremely
slow (minutes per token), so a newer device is strongly recommended for usable
performance.

Karnel removes only its managed Python environment and wrapper. Model data
created elsewhere is preserved. Cactus uses a source-available license with
commercial-use restrictions; review the upstream license before use.

Official project: <https://github.com/cactus-compute/cactus>
