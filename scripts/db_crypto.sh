#!/bin/bash

# Function to encrypt the database
encrypt_db() {
    local db_file=$1
    local key=$2
    local encrypted_file="${db_file}.enc"
    
    # Encrypt the database file using openssl
    openssl enc -aes-256-cbc -salt -pbkdf2 -in "$db_file" -out "$encrypted_file" -k "$key"
    echo "Database encrypted to $encrypted_file"
}

# Function to decrypt the database
decrypt_db() {
    local encrypted_file=$1
    local key=$2
    local db_file="${encrypted_file%.enc}"
    
    # Decrypt the database file using openssl
    openssl enc -aes-256-cbc -salt -pbkdf2 -d -in "$encrypted_file" -out "$db_file" -k "$key"
    echo "Database decrypted to $db_file"
}

# Main script
command=$1
db_file=$2
key=$3

case $command in
    "encrypt")
        encrypt_db "$db_file" "$key"
        ;;
    "decrypt")
        decrypt_db "$db_file" "$key"
        ;;
    *)
        echo "Usage: $0 {encrypt|decrypt} <db_file> <key>"
        exit 1
        ;;
esac
