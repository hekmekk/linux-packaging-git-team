FROM golang:1.16-stretch

LABEL maintainer Rea Sand <hekmek@posteo.de>

ARG USERNAME=git-team-pkg
ARG UID=1000
ARG GID=1000
ARG GPG_SIGNING_KEY_ID

RUN groupadd -g $GID $USERNAME
RUN useradd -m -u $UID -g $GID -s /bin/bash $USERNAME

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install \
	man-db \
	build-essential \
	ruby \
	ruby-dev \
	rubygems \
	rpm

RUN gem install --no-ri --no-rdoc fpm

ARG VERSION

WORKDIR /src

ADD https://github.com/hekmekk/git-team/archive/refs/tags/${VERSION}.tar.gz release.tar.gz
RUN tar -zxf release.tar.gz --strip-components=1 && rm release.tar.gz

WORKDIR /build

RUN cp /src/Makefile .
RUN cp /src/go.mod .
RUN cp /src/go.sum .
RUN cp /src/main.go .
RUN cp -r /src/src ./src

RUN chmod +x Makefile

RUN chown -R $UID:$GID .

RUN mkdir -p /go && chown -R $UID:$GID /go && chmod -R 2750 /go
RUN mkdir -p /pkg-target && chown -R $UID:$GID /pkg-target

USER $USERNAME

COPY signing-key.asc /signing-key.asc
RUN gpg --import --batch --no-tty /signing-key.asc

RUN echo -e "%_signature gpg\n \
%_gpg_path /home/${USERNAME}/.gnupg\n \
%_gpg_name ${GPG_SIGNING_KEY_ID}\n \
%_gpgbin /usr/bin/gpg" | tee /home/${USERNAME}/.rpmmacros

ENV GOPATH=/go

RUN make

CMD ["fpm", "--version"]
