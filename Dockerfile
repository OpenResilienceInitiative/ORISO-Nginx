FROM nginx:alpine

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose the port nginx listens on
EXPOSE 8089

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8089/health/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]

