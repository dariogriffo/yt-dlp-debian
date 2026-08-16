ARG DEBIAN_DIST=bookworm
FROM debian:bookworm

ARG DEBIAN_DIST
ARG YT_DLP_VERSION
ARG BUILD_VERSION
ARG FULL_VERSION
ARG ARCH
ARG YT_DLP_SRC=yt-dlp

RUN mkdir -p /output/usr/bin
RUN mkdir -p /output/usr/share/doc/yt-dlp
RUN mkdir -p /output/usr/share/man/man1
RUN mkdir -p /output/usr/share/bash-completion/completions
RUN mkdir -p /output/usr/share/zsh/vendor-completions
RUN mkdir -p /output/usr/share/fish/vendor_completions.d
RUN mkdir -p /output/DEBIAN

COPY ${YT_DLP_SRC}/yt-dlp /output/usr/bin/yt-dlp
COPY ${YT_DLP_SRC}/yt-dlp.1 /output/usr/share/man/man1/yt-dlp.1
COPY ${YT_DLP_SRC}/completions/bash/yt-dlp /output/usr/share/bash-completion/completions/yt-dlp
COPY ${YT_DLP_SRC}/completions/zsh/_yt-dlp /output/usr/share/zsh/vendor-completions/_yt-dlp
COPY ${YT_DLP_SRC}/completions/fish/yt-dlp.fish /output/usr/share/fish/vendor_completions.d/yt-dlp.fish
COPY ${YT_DLP_SRC}/README.md /output/usr/share/doc/yt-dlp/README.md
COPY output/DEBIAN/control /output/DEBIAN/
COPY output/DEBIAN/postinst /output/DEBIAN/postinst
RUN chmod 755 /output/DEBIAN/postinst
COPY output/copyright /output/usr/share/doc/yt-dlp/
COPY output/changelog.Debian /output/usr/share/doc/yt-dlp/

RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/usr/share/doc/yt-dlp/changelog.Debian
RUN sed -i "s/FULL_VERSION/$FULL_VERSION/" /output/usr/share/doc/yt-dlp/changelog.Debian
RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/DEBIAN/control
RUN sed -i "s/YT_DLP_VERSION/$YT_DLP_VERSION/" /output/DEBIAN/control
RUN sed -i "s/BUILD_VERSION/$BUILD_VERSION/" /output/DEBIAN/control
RUN sed -i "s/SUPPORTED_ARCHITECTURES/$ARCH/" /output/DEBIAN/control

# Debian expects the executable to be 755 and the docs/man pages compressed.
RUN chmod 755 /output/usr/bin/yt-dlp
RUN chmod 644 /output/usr/share/man/man1/yt-dlp.1 \
    /output/usr/share/bash-completion/completions/yt-dlp \
    /output/usr/share/zsh/vendor-completions/_yt-dlp \
    /output/usr/share/fish/vendor_completions.d/yt-dlp.fish \
    /output/usr/share/doc/yt-dlp/README.md \
    /output/usr/share/doc/yt-dlp/copyright \
    /output/usr/share/doc/yt-dlp/changelog.Debian
RUN gzip -9n /output/usr/share/man/man1/yt-dlp.1 \
    /output/usr/share/doc/yt-dlp/README.md \
    /output/usr/share/doc/yt-dlp/changelog.Debian

RUN dpkg-deb --build /output /yt-dlp_${FULL_VERSION}.deb
