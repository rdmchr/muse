FROM node:18.7.0-slim AS base

# Install ffmpeg
RUN apt-get update && \
    apt-get install -y ffmpeg tini libssl-dev ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install dependencies
FROM base AS dependencies

WORKDIR /usr/app

COPY package.json .
COPY yarn.lock .

RUN yarn install --prod && \
    sed -i "64s/const subBody = body.slice(ndx + functionStart.length);/const end = body.indexOf('.join(\"\")};', ndx);/" node_modules/ytdl-core/lib/sig.js && \
    sed -i "65s/const functionBody = \`var \${functionStart}\${utils.cutAfterJS(subBody)};\${functionName}(ncode);\`;/const subBody = body.slice(ndx, end); const functionBody = \`\${subBody}.join(\"\")};\${functionName}(ncode);\`;/" node_modules/ytdl-core/lib/sig.js

# Only keep what's necessary to run
FROM base AS runner

WORKDIR /usr/app

COPY --from=dependencies /usr/app/node_modules node_modules

COPY . .

RUN yarn prisma generate

ARG COMMIT_HASH=unknown
ARG BUILD_DATE=unknown

ENV DATA_DIR /data
ENV NODE_ENV production
ENV COMMIT_HASH $COMMIT_HASH
ENV BUILD_DATE $BUILD_DATE

CMD ["tini", "--", "yarn", "start"]
