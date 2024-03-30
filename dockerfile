# Use the specified base image
FROM joseluisq/static-web-server:latest

# Copy the current directory's ./public folder to /public in the container
COPY ./public /public

# Set the environment variable SERVER_ROOT to /public
ENV SERVER_ROOT=/public
