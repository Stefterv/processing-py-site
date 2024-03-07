FROM alpine as build

RUN apk add --update --no-cache openjdk8 apache-ant git rsync

RUN git clone --depth=1 --single-branch --branch master https://github.com/processing/processing.git  /processing 
RUN git clone --depth=1 --single-branch --branch latest-processing3 https://github.com/processing/processing-video.git /processing-video

# TODO: This is a hack to get the openjfx package installed. It should be replaced with a proper package manager
RUN apk --no-cache add ca-certificates wget
RUN wget --quiet --output-document=/etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
RUN wget https://github.com/sgerrand/alpine-pkg-java-openjfx/releases/download/8.151.12-r0/java-openjfx-8.151.12-r0.apk
RUN apk add --no-cache java-openjfx-8.151.12-r0.apk

WORKDIR /processing/build

RUN ant

WORKDIR /processing-video

RUN echo "processing.dir=../processing" >> local.properties

RUN ant

RUN git clone --depth=1 --single-branch --branch master https://github.com/jdf/processing.py.git /processing.py

WORKDIR /processing.py

RUN ant jar -D processing=/processing

FROM python:2-alpine

RUN apk add --update --no-cache g++ gcc libxslt-dev openjdk8
RUN apk --update add xvfb

WORKDIR /processing.py.site

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

COPY --from=build /processing.py/work/processing-py.jar ./processing-py.jar

ENV DISPLAY :99

RUN printf "\
    \nXvfb :99 & \
    \npython generator.py build --all --images" > generate.sh
RUN chmod a+x generate.sh

CMD ./generate.sh

# BUILD: docker build --platform=linux/amd64 -t processing.py.site:latest .
# RUN: docker run --rm -v $(pwd)/generated:/processing.py.site/generated processing.py.site:latest