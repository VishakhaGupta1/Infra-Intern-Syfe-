# Use the official MySQL image as the base image
FROM mysql:8.0

# Set the root password environment variable
ENV MYSQL_ROOT_PASSWORD=abcd1234

# Copy custom MySQL configuration file if needed
# COPY my.cnf /etc/mysql/conf.d/

# Copy any initialization scripts
# COPY ./init.sql /docker-entrypoint-initdb.d/

# Expose the MySQL port
EXPOSE 3306

# The CMD instruction is not needed as it's already specified in the base image
