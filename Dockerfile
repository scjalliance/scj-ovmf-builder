# --------
# Configuration
# --------

# Specify which ubuntu image to use for EFI vars injection
ARG UBUNTU_VERSION=noble



# --------
# Stage 1A: Build (SMM not required, SecureBoot optional)
# -------

FROM scjalliance/ovmf:stable202511 AS standard-builder

COPY Logo.bmp /opt/src/edk2/MdeModulePkg/Logo/Logo.bmp

RUN ["/bin/bash", "-c", "source edksetup.sh && build -D TPM2_ENABLE -D SECURE_BOOT_ENABLE"]



# --------
# Stage 1B: Build (SMM required / SecureBoot mandatory)
# -------

FROM scjalliance/ovmf:stable202511 AS secboot-builder

COPY Logo.bmp /opt/src/edk2/MdeModulePkg/Logo/Logo.bmp

RUN ["/bin/bash", "-c", "source edksetup.sh && build -D TPM2_ENABLE -D SECURE_BOOT_ENABLE -D SMM_REQUIRE"]



# --------
# Stage 2: Inject standard Secure Boot keys into EFI vars
# -------

FROM ubuntu:${UBUNTU_VERSION} AS secboot-keys-injector

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
             python3-virt-firmware \
             && \
    apt-get purge -y --auto-remove && rm -rf /var/lib/apt/lists/*

COPY --from=secboot-builder /opt/src/edk2/Build/OvmfX64/RELEASE_GCC5/FV/OVMF_VARS.fd /data/OVMF_VARS.secboot.fd

RUN ["/usr/bin/virt-fw-vars", "--in-place", "/data/OVMF_VARS.secboot.fd", "--enroll-redhat", "--secure-boot"]



# --------
# Stage 3: Release
# --------

FROM alpine

COPY --from=standard-builder /opt/src/edk2/Build/OvmfX64/RELEASE_GCC5/FV/OVMF*.fd /data/

COPY --from=secboot-builder /opt/src/edk2/Build/OvmfX64/RELEASE_GCC5/FV/OVMF_CODE.fd /data/OVMF_CODE.secboot.fd

COPY --from=secboot-keys-injector /data/OVMF_VARS.secboot.fd /data/OVMF_VARS.secboot.fd

VOLUME /ovmf

CMD ["/bin/sh", "-c", "cp /data/* /ovmf"]
