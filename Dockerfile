FROM node:20-alpine AS dependencies
WORKDIR /app
COPY AfaPayBackend/package.json AfaPayBackend/package-lock.json ./
RUN npm ci --omit=dev

FROM node:20-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY --from=dependencies /app/node_modules ./node_modules
COPY AfaPayBackend/ ./
EXPOSE 8080
CMD ["node", "afapay.server.js"]
