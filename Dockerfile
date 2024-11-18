# Build Stage
FROM golang:1.22.2 AS builder

# Install dependencies
RUN apt-get update && \
    apt-get install -y wget gnupg pkg-config libtool autoconf automake build-essential

# Install YARA 4.3
RUN wget https://github.com/VirusTotal/yara/archive/refs/tags/v4.3.0.tar.gz && \
    tar -xvzf v4.3.0.tar.gz && \
    cd yara-4.3.0 && \
    ./bootstrap.sh && \
    ./configure && \
    make && \
    make install && \
    ldconfig

# Set the working directory
WORKDIR /app

# Copy the go module files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the rest of the application code
COPY . .

# Build the application
RUN go build -o main .

# Final Stage
FROM golang:1.22.2

# Set the working directory
WORKDIR /app

# Copy the built application from the builder stage
COPY --from=builder /app/main /app/main

# Copy YARA libraries from the builder stage
COPY --from=builder /usr/local/lib/libyara.so.10 /usr/local/lib/libyara.so.10

# Set the library path
ENV LD_LIBRARY_PATH=/usr/local/lib

# Expose port 8081 (if your application uses this port)
EXPOSE 8081

# Run the application
CMD ["./main"]
