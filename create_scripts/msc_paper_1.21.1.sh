#!/bin/bash

# Get the server directory name from the first argument
SERVER_DIR="$1"
PAPER_VERSION="1.21.1"
PAPER_API_URL="https://api.papermc.io/v2/projects/paper/versions/$PAPER_VERSION/builds/131/downloads/paper-1.21.1-131.jar"
PAPER_JAR="paper-$PAPER_VERSION.jar"
RAM_ALLOCATION="6G"

# Ensure a server directory name is provided
if [ -z "$SERVER_DIR" ]; then
    echo "Error: You must specify a server directory name as the first argument."
    echo "Usage: $0 <server_directory_name>"
    exit 1
fi

# Function to install Java 21 if needed
install_java_21() {
    echo "Installing Java 21 manually..."

    # Step 1: Download OpenJDK 21 (aarch64 build) from Adoptium
    cd ~
    wget https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.2%2B13/OpenJDK21U-jdk_aarch64_linux_hotspot_21.0.2_13.tar.gz

    # Step 2: Extract and move it to /opt
    tar -xvf OpenJDK21U-jdk_aarch64_linux_hotspot_21.0.2_13.tar.gz
    sudo mv jdk-21.0.2+13 /opt/jdk-21

    # Step 3: Create a system-wide environment setup
    echo "export JAVA_HOME=/opt/jdk-21" | sudo tee /etc/profile.d/jdk21.sh
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" | sudo tee -a /etc/profile.d/jdk21.sh

    # Step 4: Apply the environment variables
    source /etc/profile.d/jdk21.sh

    # Step 5: Enable java 21 to appear in the alternatives system
    sudo update-alternatives --install /usr/bin/java java /opt/jdk-21/bin/java 2
    sudo update-alternatives --install /usr/bin/javac javac /opt/jdk-21/bin/javac 2

    echo "Java 21 installation completed and environment variables set."
}

# Function to switch to Java 21 if available
switch_to_java21() {
    echo "Switching to Java 21..."
    sudo update-alternatives --config java <<EOF
1
EOF
}

# Function to install Java 21 manually from Adoptium
install_java_21() {
    echo "Installing Java 21..."
    sudo apt update
    sudo apt install -y default-jdk
    sudo apt install -y openjdk-21-jdk
}

# Function to download the Minecraft server .jar file
download_server() {
    mkdir -p "$SERVER_DIR"
    cd "$SERVER_DIR" || exit 1

    echo "Downloading Paper server version $PAPER_VERSION..."
    curl -o "$PAPER_JAR" "$PAPER_API_URL"
    if [ ! -f "$PAPER_JAR" ]; then
        echo "Download failed. Check the version and build number and try again."
        exit 1
    fi

    echo "eula=true" > eula.txt
    echo "#!/bin/bash
    java -Xms1G -Xmx$RAM_ALLOCATION -jar $PAPER_JAR nogui" > start.sh
    chmod +x start.sh
    echo "Server setup complete! Navigate to '$SERVER_DIR' and run './start.sh' to start the server."
}

# Main script flow
# Attempt to switch to Java 21 first
switch_to_java21

# Now check if Java 21 is installed after switching
if check_java_version; then
    echo "Java 21 is already installed."
    download_server
else
    install_java21
    if check_java_version; then
        echo "Java 21 installed successfully."
        download_server
    else
        echo "There was a problem installing Java 21."
        exit 1
    fi
fi
