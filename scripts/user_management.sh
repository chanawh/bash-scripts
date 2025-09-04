#!/bin/sh

log_event() {
  local action=$1
  local username=$2
  local message=$3

  echo "$(date '+%Y-%m-%d %H:%M:%S') | $action | $username | $message" >> /var/log/user_mgmt.log
}

create_user() {
  local username=$1
  local password

  # Generate password (Alpine has openssl, but make sure it's installed)
  password=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9!@#$%^&*()_+' | head -c16)

  # Create user with home directory
  adduser -D -s /bin/sh "$username"  # -D skips password prompt, uses defaults

  # Set password
  echo "$username:$password" | chpasswd

  # Force password change on first login - Alpine doesn't have `chage`, so workaround
  # You can expire the password using `passwd -e` if available, or touch `/etc/shadow` manually
  passwd -e "$username" 2>/dev/null || echo "Manual intervention required to expire password"

  # Logging
  log_event "create" "$username" "User created with temp password"
  echo "Created user '$username' | Temporary password: $password"
}

create_user mynewuser
