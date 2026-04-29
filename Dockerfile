FROM node:20-bookworm-slim
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    openssl \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /usr/src/app
COPY package*.json ./
COPY prisma ./prisma/
RUN npm install && npx prisma generate
COPY . .
EXPOSE 8000
CMD [ "npm", "start" ]