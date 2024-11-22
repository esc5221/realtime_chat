#!/bin/sh
set -e

# Clean up any leftover WAL files
rm -f /app/realtime_chat_dev.db-*

# Ensure database directory exists with correct permissions
mkdir -p "$(dirname /app/realtime_chat_dev.db)"
touch /app/realtime_chat_dev.db
chown nobody:nobody /app/realtime_chat_dev.db
chmod 644 /app/realtime_chat_dev.db

# Wait for database file to be accessible
timeout=30
while [ ! -w /app/realtime_chat_dev.db ] && [ $timeout -gt 0 ]; do
    echo "Waiting for database file to become writable..."
    sleep 1
    timeout=$((timeout - 1))
done

if [ $timeout -eq 0 ]; then
    echo "Error: Database file is not writable after 30 seconds"
    exit 1
fi

# Switch to nobody user and run the application
exec su-exec nobody:nobody sh -c "
    # Ensure Hex and Rebar are installed for nobody user
    mix local.hex --force
    mix local.rebar --force
    
    # Get and compile dependencies
    mix deps.get
    mix deps.compile

    # Run migrations and start server
    mix do ecto.create, ecto.migrate, phx.server
"
