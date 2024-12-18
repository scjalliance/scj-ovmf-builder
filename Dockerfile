# --------
# Stage 1A: Build (SMM not required, SecureBoot optional)
# -------

FROM scjalliance/ovmf:stable202408 AS standard-builder

COPY Logo.bmp /opt/src/edk2/MdeModulePkg/Logo/Logo.bmp

RUN ["/bin/bash", "-c", "source edksetup.sh && build -D TPM2_ENABLE -D SECURE_BOOT_ENABLE"]



# --------
# Stage 1B: Build (SMM required / SecureBoot mandatory)
# -------

FROM scjalliance/ovmf:stable202408 AS secboot-builder

COPY Logo.bmp /opt/src/edk2/MdeModulePkg/Logo/Logo.bmp

RUN ["/bin/bash", "-c", "source edksetup.sh && build -D TPM2_ENABLE -D SECURE_BOOT_ENABLE -D SMM_REQUIRE"]



# --------
# Stage 2: Release
# --------

FROM alpine

COPY --from=standard-builder /opt/src/edk2/Build/OvmfX64/RELEASE_GCC5/FV/OVMF*.fd /data/

COPY --from=secboot-builder /opt/src/edk2/Build/OvmfX64/RELEASE_GCC5/FV/OVMF_CODE.fd /data/OVMF_CODE.secboot.fd

VOLUME /ovmf

CMD ["/bin/sh", "-c", "cp /data/* /ovmf"]
