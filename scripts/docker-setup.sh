#!/bin/bash
# Generated from spec: E01-F02-T03 (Docker and Database Services Setup)
# Spec ID: ce5140df
# Docker installation script for Linux and Windows (via WSL)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            VERSION=$VERSION_ID
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS="windows"
    else
        print_message $RED "Unsupported OS: $OSTYPE"
        exit 1
    fi
    
    print_message $GREEN "Detected OS: $OS"
}

# Function to check if Docker is already installed
check_docker_installed() {
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)
        print_message $YELLOW "Docker is already installed (version: $docker_version)"
        
        read -p "Do you want to continue with the installation/update? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_message $GREEN "Skipping Docker installation"
            return 0
        fi
    fi
    return 1
}

# Function to install Docker on Ubuntu/Debian
install_docker_ubuntu() {
    print_message $GREEN "Installing Docker on Ubuntu/Debian..."
    
    # Update package index
    sudo apt-get update
    
    # Install prerequisites
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Add Docker's official GPG key
    sudo mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Set up the repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    print_message $GREEN "Docker installed successfully on Ubuntu/Debian"
}

# Function to install Docker on CentOS/RHEL/Fedora
install_docker_centos() {
    print_message $GREEN "Installing Docker on CentOS/RHEL/Fedora..."
    
    # Remove old versions
    sudo yum remove -y docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate \
        docker-engine
    
    # Install prerequisites
    sudo yum install -y yum-utils
    
    # Set up the repository
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    # Install Docker Engine
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    print_message $GREEN "Docker installed successfully on CentOS/RHEL/Fedora"
}

# Function to install Docker on macOS
install_docker_macos() {
    print_message $GREEN "Installing Docker on macOS..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        print_message $RED "Homebrew is not installed. Please install Homebrew first."
        print_message $YELLOW "Visit: https://brew.sh"
        exit 1
    fi
    
    # Install Docker Desktop using Homebrew
    brew install --cask docker
    
    print_message $GREEN "Docker Desktop installed successfully on macOS"
    print_message $YELLOW "Please start Docker Desktop from Applications"
}

# Function to install Docker on Windows (WSL2)
install_docker_windows() {
    print_message $YELLOW "Docker installation on Windows requires Docker Desktop"
    print_message $YELLOW "Please follow these steps:"
    echo "1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop"
    echo "2. Install Docker Desktop with WSL2 backend"
    echo "3. Start Docker Desktop"
    echo "4. Ensure WSL2 integration is enabled in Docker Desktop settings"
    echo ""
    print_message $GREEN "After installation, you can use Docker from WSL2 terminal"
}

# Function to verify Docker installation
verify_docker() {
    print_message $GREEN "Verifying Docker installation..."
    
    # Check Docker version
    if docker --version &> /dev/null; then
        docker --version
    else
        print_message $RED "Docker is not installed or not in PATH"
        return 1
    fi
    
    # Check Docker Compose version
    if docker compose version &> /dev/null; then
        docker compose version
    else
        print_message $YELLOW "Docker Compose plugin is not installed"
    fi
    
    # Test Docker
    print_message $GREEN "Testing Docker with hello-world container..."
    if sudo docker run --rm hello-world &> /dev/null; then
        print_message $GREEN "Docker is working correctly!"
    else
        print_message $RED "Docker test failed. Please check your installation."
        return 1
    fi
}

# Function to configure Docker for development
configure_docker() {
    print_message $GREEN "Configuring Docker for development..."
    
    # Create docker config directory if it doesn't exist
    mkdir -p ~/.docker
    
    # Configure Docker daemon (if on Linux)
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]] || [[ "$OS" == "centos" ]] || [[ "$OS" == "fedora" ]]; then
        # Create daemon.json for better performance
        sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2"
}
EOF
        
        # Restart Docker to apply changes
        sudo systemctl restart docker
    fi
    
    print_message $GREEN "Docker configuration completed"
}

# Main installation flow
main() {
    print_message $GREEN "=== JTS Docker Setup Script ==="
    
    # Detect OS
    detect_os
    
    # Check if Docker is already installed
    if check_docker_installed; then
        verify_docker
        exit 0
    fi
    
    # Install Docker based on OS
    case $OS in
        ubuntu|debian)
            install_docker_ubuntu
            ;;
        centos|rhel|fedora)
            install_docker_centos
            ;;
        macos)
            install_docker_macos
            ;;
        windows)
            install_docker_windows
            exit 0
            ;;
        *)
            print_message $RED "Unsupported OS: $OS"
            print_message $YELLOW "Please install Docker manually: https://docs.docker.com/get-docker/"
            exit 1
            ;;
    esac
    
    # Configure Docker
    configure_docker
    
    # Verify installation
    verify_docker
    
    print_message $GREEN "=== Docker installation completed successfully ==="
    print_message $YELLOW "Note: You may need to log out and back in for group changes to take effect"
    print_message $YELLOW "Or run: newgrp docker"
}

# Run main function
main