#!/bin/bash

# Nginx Upstream conf path
UPSTREAM_DATA=~/nginx-upstream-editor/upstream.conf


function exit_with_code {
    echo ""
    exit $1
}

function help {
    echo " Usage: ./upstream.sh [OPTIONS]"
    echo " Assist in easily managing the upstream config file"
    echo ""
    echo " Options:"
    echo "   create   Create new upstream config file in current directory"
    echo "   list     Display all servers in the upstream config file"
    echo "   add      Add a server to the upstream config file"
    echo "            Usage: ./upstream.sh add [server] [port]"
    echo "   del      Remove a server from the upstream config file"
    echo "            Usage: ./upstream.sh del [server] [port]"
    echo "   clear    Remove all servers from the upstream config file"
    echo "   reload   Reloads the nginx config (requires sudo permission)"
    echo ""
    echo " Examples:"
    echo " ./upstream.sh create"
    echo " ./upstream.sh list"
    echo " ./upstream.sh add 127.0.0.1 8080"
    echo " ./upstream.sh del 127.0.0.1 8080"
    echo " sudo ./upstream.sh reload"
    echo ""
}

# Function to create new empty upstream config file
function create_config {
  # Check if file already exists
  if [ -e "$UPSTREAM_DATA" ]; then
    echo " Error: $UPSTREAM_DATA already exists."
    exit_with_code 1
  fi
  
  # Check whether process has permission to write to the file.
  if ! touch "$UPSTREAM_DATA"; then
    echo " Error: Failed to create $UPSTREAM_DATA."
    echo ""
    echo " Please verify write permissions for the config file."
    exit_with_code 1
  fi
  
  # Add contents to file
  echo 'upstream servers {' > "$UPSTREAM_DATA" && echo '}' >> "$UPSTREAM_DATA"

  echo " File $UPSTREAM_DATA created successfully."
}

# Function to display all servers in the upstream config file
function list_servers {
    # Extract all server addresses from the Nginx conf file
    SERVERS=$(awk '/upstream servers {/,/}/ {if($0 !~ /servers/) {gsub(/;/,"",$2); print $2}}' "$UPSTREAM_DATA")

    if [ -z "$SERVERS" ]; then
        echo " There are no servers in the upstream config file"
    else
        echo " Servers in the upstream config file:"
        echo "$SERVERS" | while read -r server; do
            echo "  - $server"
        done
    fi
}

# Function to add a server to the upstream config file
function add_server {
    # Check if the server is already in the list
    if grep -q "$1:$2" "$UPSTREAM_DATA"; then
        echo " Server $1:$2 already exists"
        exit_with_code 1
    else
        # Add server to the list
        sed -i "/upstream servers {/a\    server $1:$2;" $UPSTREAM_DATA
        echo " Server $1:$2 added to upstream config file"
    fi
}

# Function to remove a server from the upstream config file
function remove_server {
    # Check if the server exists in the list
    if grep -q "server $1:$2" "$UPSTREAM_DATA"; then
        # Remove server from the list
        sed -i "/server $1:$2;/d" "$UPSTREAM_DATA"
        echo " Server $1:$2 removed from upstream config file"
    else
        echo " Server $1:$2 does not exist in the upstream config file"
        exit_with_code 1
    fi
}

# Function to clear all servers from the upstream config file
function clear_servers {
    # Replace all servers with an empty block
    echo 'upstream servers {' > "$UPSTREAM_DATA" && echo '}' >> "$UPSTREAM_DATA"
    echo " All servers removed from upstream config file"
}

# Handle command 'help', command 'create' and no-argument 
if [ $# -eq 0 ] || [ "$1" == "help" ]; then
    help
    exit_with_code 1
elif [ "$1" == "create" ]; then
    create_config
    exit_with_code 0
fi

# Check if the file exists and is readble and writable
if [ ! -e "$UPSTREAM_DATA" ]; then
    echo " Error: Cannot open the upstream config file at '$UPSTREAM_DATA'"
    echo " Use './upstream.sh create' to create empty config file."
    exit_with_code 1
elif [ ! -r "$UPSTREAM_DATA" ]; then
    echo " Error: Cannot read the upstream config file at '$UPSTREAM_DATA'"
    echo " Please verify read permissions for the config file."
    exit_with_code 1
elif [ ! -w "$UPSTREAM_DATA" ]; then
    echo " Error: Cannot write the upstream config file at '$UPSTREAM_DATA'"
    echo " Please verify write permissions for the config file."
    exit_with_code 1
fi

case $1 in
    list)
        list_servers
        ;;
    clear)
        clear_servers
        ;;
    add)
        if [ $# -ne 3 ]; then
            echo " Error: Invalid number of arguments"
            echo ""
            help
            exit_with_code 1
        fi
        add_server $2 $3
        echo ""
        list_servers
        ;;
    del)
        if [ $# -ne 3 ]; then
            echo " Error: Invalid number of arguments"
            echo ""
            help
            exit_with_code 1
        fi
        remove_server $2 $3
        echo ""
        list_servers
        ;;
    reload)
        sudo systemctl reload nginx
        ;;
    *)
        echo " Error: Unknown Command verb '$1'"
        echo ""
        help
        ;;
esac
echo ""
