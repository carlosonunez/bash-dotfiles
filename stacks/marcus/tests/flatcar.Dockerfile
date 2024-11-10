FROM local/faux-marcus
ARG FLATCAR_LINUX_VERSION
RUN emerge-gitclone
RUN emerge -gKv coreos-sources
RUN gzip -cd /proc/config.gz > /usr/src/linux/.config
RUN make -C /usr/src/linux modules_prepare

#RUN git -C /var/lib/portage/coreos-overlay checkout "tags/stable-$FLATCAR_LINUX_VERSION" && \
#    git -C /var/lib/portage/portage-stable checkout "tags/stable-$FLATCAR_LINUX_VERSION"
#
#RUN emerge -gKq --jobs 4 --load-average 4 coreos-sources || \
#    echo "failed to download binaries, fallback build from source:" && \
#      emerge -q --jobs 4 --load-average 4 coreos-sources
#
#RUN ls /usr/src/linux-5.10.84-coreos
#RUN cp /usr/lib64/modules/$(ls /usr/lib64/modules)/build/.config /usr/src/linux/ \
#    && make -C /usr/src/linux modules_prepare \
#    && cp /usr/lib64/modules/$(ls /usr/lib64/modules)/build/Module.symvers /usr/src/linux/
