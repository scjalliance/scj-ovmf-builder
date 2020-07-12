# --------
# Stage 1: Build
# -------

FROM scjalliance/ovmf:stable202005 as builder

COPY Logo.bmp /opt/src/edk2/MdeModulePkg/Logo/Logo.bmp

RUN ["/bin/bash", "-c", "source edksetup.sh && build"]



# --------
# Stage 2: Release
# --------

FROM alpine

COPY --from=builder /opt/src/edk2/Build/OvmfX64/RELEASE_GCC5/FV/OVMF*.fd /data/

VOLUME /ovmf

CMD ["/bin/sh", "-c", "cp /data/* /ovmf"]

