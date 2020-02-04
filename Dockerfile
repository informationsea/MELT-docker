FROM debian:10-slim AS donwload-samtools
RUN apt-get update && apt-get install -y curl bzip2 && rm -rf /var/lib/apt/lists/*
RUN curl -OL https://github.com/samtools/samtools/releases/download/1.10/samtools-1.10.tar.bz2
RUN curl -OL https://github.com/samtools/bcftools/releases/download/1.10.2/bcftools-1.10.2.tar.bz2
RUN curl -OL https://github.com/samtools/htslib/releases/download/1.10.2/htslib-1.10.2.tar.bz2
RUN tar xjf samtools-1.10.tar.bz2
RUN tar xjf bcftools-1.10.2.tar.bz2
RUN tar xjf htslib-1.10.2.tar.bz2

FROM debian:10-slim AS samtools-build
RUN apt-get update && apt-get install -y libssl-dev libncurses-dev build-essential zlib1g-dev liblzma-dev libbz2-dev curl libcurl4-openssl-dev
COPY --from=donwload-samtools /samtools-1.10 /build
WORKDIR /build
RUN ./configure && make -j4 && make install

FROM debian:10-slim AS bcftools-build
RUN apt-get update && apt-get install -y libssl-dev libncurses-dev build-essential zlib1g-dev liblzma-dev libbz2-dev curl libcurl4-openssl-dev
COPY --from=donwload-samtools /bcftools-1.10.2 /build
WORKDIR /build
RUN ./configure && make -j4 && make install

FROM debian:10-slim AS htslib-build
RUN apt-get update && apt-get install -y libssl-dev libncurses-dev build-essential zlib1g-dev liblzma-dev libbz2-dev curl libcurl4-openssl-dev
COPY --from=donwload-samtools /htslib-1.10.2 /build
WORKDIR /build
RUN ./configure && make -j4 && make install

FROM debian:10-slim AS download-bowtie2
RUN apt-get update && apt-get install -y curl unzip && rm -rf /var/lib/apt/lists/*
RUN curl -OL https://downloads.sourceforge.net/project/bowtie-bio/bowtie2/2.3.5.1/bowtie2-2.3.5.1-linux-x86_64.zip
RUN unzip bowtie2-2.3.5.1-linux-x86_64.zip

FROM debian:10-slim AS extract-MELT
COPY ./MELTv2.2.0.tar.gz /
RUN tar xzf MELTv2.2.0.tar.gz

FROM openjdk:8u242-slim-buster
RUN apt-get update && \
    apt-get install -y ncurses-base zlib1g liblzma5 libbz2-1.0 curl libcurl4 && \
    apt-get install -y libsys-hostname-long-perl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
COPY --from=samtools-build /usr/local /usr/local
COPY --from=bcftools-build /usr/local /usr/local
COPY --from=htslib-build /usr/local /usr/local
COPY --from=download-bowtie2 /bowtie2-2.3.5.1-linux-x86_64 /opt/bowtie2
COPY --from=extract-MELT /MELTv2.2.0 /opt/MELTv2.2.0
ENV PATH=/opt/bowtie2:${PATH}
COPY run.sh /
COPY melt /usr/local/bin/
ENTRYPOINT [ "/bin/bash", "/run.sh" ]