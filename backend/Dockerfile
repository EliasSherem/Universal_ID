# Dockerfile for GCP Cloud Run
FROM node:20-alpine

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
COPY package*.json ./
RUN npm install

# Bundle app source
COPY . .

# Build TS if we set up build script, for MVP we can use ts-node
# Or compile manually here: RUN npx tsc

EXPOSE 8080
CMD [ "npx", "ts-node", "src/index.ts" ]
