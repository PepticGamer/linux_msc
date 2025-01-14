#!/bin/bash

# Accept the custom server directory name as a parameter
server_dir="$1"
MINECRAFT_VERSION="1.21.4"
FABRIC_INSTALLER_URL="https://maven.fabricmc.net/net/fabricmc/fabric-installer/0.11.2/fabric-installer-0.11.2.jar"
FABRIC_INSTALLER_JAR="fabric-installer.jar"
MINECRAFT_SERVER_JAR="fabric-server-launch.jar"
RAM_ALLOCATION="6G"

# Check if the directory name was provided
if [[ -z "$server_dir" ]]; then
    echo "Error: No server directory specified. Usage: $0 <server_directory>"
    exit 1
fi

# Function to install Java 21 if needed
install_java_21() {
    echo "Installing Java 21..."
    sudo apt update
    sudo apt install -y openjdk-21-jdk openjdk-21-jre
}

# Function to automatically switch Java version to Java 21
switch_to_java21() {
    echo "Switching to Java 21..."
    sudo update-alternatives --config java <<EOF
1
EOF
}

# Function to check if Java 21 is installed
check_java_version() {
    switch_to_java21
    java_version=$(java -version 2>&1 | grep -oP 'version "\K[^"]*')

    if [[ $java_version == 21* ]]; then
        return 0  # Java 21 is installed
    else
        return 1  # Java 21 is not installed
    fi
}

# Function to download and set up the Fabric server
download_fabric_server() {
    mkdir -p "$server_dir"
    cd "$server_dir" || exit 1

    echo "Downloading Fabric installer..."
    curl -o "$FABRIC_INSTALLER_JAR" "$FABRIC_INSTALLER_URL"

    # Check if download was successful
    if [ ! -f "$FABRIC_INSTALLER_JAR" ]; then
        echo "Download failed. Please check the Fabric installer URL."
        exit 1
    fi

    echo "Running Fabric installer for Minecraft version $MINECRAFT_VERSION..."
    java -jar "$FABRIC_INSTALLER_JAR" server -mcversion $MINECRAFT_VERSION -downloadMinecraft

    # Check if Fabric server was successfully created
    if [ ! -f "$MINECRAFT_SERVER_JAR" ]; then
        echo "Fabric installation failed. Please check the installer output."
        exit 1
    fi

    # Accept the EULA
    echo "eula=true" > eula.txt

    # Create a start script
    echo "#!/bin/bash
java -Xms1G -Xmx$RAM_ALLOCATION -jar $MINECRAFT_SERVER_JAR nogui" > start.sh

    chmod +x start.sh
    echo "Fabric server for Minecraft $MINECRAFT_VERSION is ready! To start the server, navigate to '$server_dir' and run: 'bash start.sh'."
}

# Main script flow
if check_java_version; then
    echo "Correct Java version is already installed."
    download_fabric_server
else
    echo "Java 21 is not installed. Installing Java 21..."
    install_java_21
    if check_java_version; then
        echo "Java 21 installed successfully."
        download_fabric_server
    else
        echo "There was an issue installing Java 21. Attempting to switch to Java 21..."
        switch_to_java21
        download_fabric_server
    fi
fi