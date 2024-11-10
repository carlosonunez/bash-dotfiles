FROM alpine:3.20 AS base
COPY flatcar.bin.bz2 /
RUN mkdir /flatcar && cd /flatcar && bunzip2 /flatcar.bin.bz2

FROM scratch
COPY --from=base /flatcar /
RUN systemd-nspawn --bind=/usr/lib64/modules --image=flatcar_developer_container.bin
