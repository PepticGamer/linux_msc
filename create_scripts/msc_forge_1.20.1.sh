#!/bin/bash

MINECRAFT_VERSION="1.20.1"
FORGE_INSTALLER_URL="https://maven.minecraftforge.net/net/minecraftforge/forge/1.20.1-47.3.0/forge-1.20.1-47.3.0-installer.jar"
FORGE_INSTALLER_JAR="forge-installer.jar"
FORGE_UNIVERSAL_JAR="java @user_jvm_args.txt @libraries/net/minecraftforge/forge/1.20.1-47.3.0/unix_args.txt "$@""

# Accept the custom server directory name and RAM allocation as parameters
server_dir="$1"
ram_allocation="$2"

# Check if the directory name was provided
if [[ -z "$server_dir" ]]; then
    echo "Error: No server directory specified. Usage: $0 <server_directory>"
    exit 1
fi

# Function to install Java 17 if needed
install_java_17() {
    echo "Installing Java 17..."
    sudo apt update
    sudo apt install -y openjdk-17-jdk openjdk-17-jre
}

# Function to automatically switch Java version to Java 17
switch_to_java17() {
    echo "Switching to Java 17..."
    sudo update-alternatives --config java <<EOF
0
EOF
}

# Function to check if Java 17 is installed
check_java_version() {
    switch_to_java17
    java_version=$(java -version 2>&1 | grep -oP 'version "\K[^"]*')

    if [[ $java_version == 17* ]]; then
        return 0  # Java 17 is installed
    else
        return 1  # Java 17 is not installed
    fi
}

# Function to download and set up the Forge server
download_forge_server() {
    mkdir -p "$server_dir"
    cd "$server_dir" || exit 1

    echo "Downloading Forge installer..."
    curl -o "$FORGE_INSTALLER_JAR" "$FORGE_INSTALLER_URL"

    # Check if download was successful
    if [ ! -f "$FORGE_INSTALLER_JAR" ]; then
        echo "Download failed. Please check the Forge installer URL."
        exit 1
    fi

    echo "Running Forge installer for Minecraft version $MINECRAFT_VERSION..."
    java -jar "$FORGE_INSTALLER_JAR" --installServer

    # Accept the EULA
    echo "eula=true" > eula.txt

    # Configure JVM arguments with specified RAM allocation
    echo "-Xms1024M" > user_jvm_args.txt
    echo "-Xmx$ram_allocation" >> user_jvm_args.txt

    # Create a start script
    echo "java @user_jvm_args.txt @libraries/net/minecraftforge/forge/1.20.1-47.3.0/unix_args.txt "$@"" > start.sh

    chmod +x start.sh
    echo "Forge server for Minecraft $MINECRAFT_VERSION is ready! To start the server, navigate to '$server_dir' and run: 'bash start.sh'."
}

# Main script flow
if check_java_version; then
    echo "Correct Java version is already installed."
    download_forge_server
else
    echo "Java 17 is not installed. Installing Java 17..."
    install_java_17
    if check_java_version; then
        echo "Java 17 installed successfully."
        download_forge_server
    else
        echo "There was an issue installing Java 17. Attempting to switch to Java 17..."
        switch_to_java17
        download_forge_server
    fi
fi
