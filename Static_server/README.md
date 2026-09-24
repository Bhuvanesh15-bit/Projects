# Static Site Deployment with Nginx and rsync

This project documents how to create a remote Linux server, configure SSH access, serve a static site with Nginx, and deploy site changes with `rsync`.

The repository includes a small site in [`site/`](site/), the Nginx configuration in [`server/nginx-site.conf`](server/nginx-site.conf), and deployment scripts in [`scripts/`](scripts/).

## 1. Create the server

1. Create an account with a provider such as [DigitalOcean](https://m.do.co/c/b29aa8845df8), AWS, or another cloud provider.
2. Create a small Ubuntu LTS server and note its public IP address.
3. Record the default server user supplied by the provider, such as `root` or `ubuntu`.
4. Allow inbound TCP port `22` in the provider firewall. Restrict the source to your IP address when possible.

For the commands below, replace these placeholders:

- `SERVER_IP` with the server's public IP address.
- `SERVER_USER` with the provider's default Linux user.

The examples use Ubuntu and the standard web root `/var/www/static-site`. They work with a server IP and do not require a domain name.

## 2. Create two SSH key pairs

Run these commands on the local computer. Use two different passphrases when prompted:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh

ssh-keygen -t ed25519 -f ~/.ssh/remote-server-key-1 -C "remote-server-key-1"
ssh-keygen -t ed25519 -f ~/.ssh/remote-server-key-2 -C "remote-server-key-2"
chmod 600 ~/.ssh/remote-server-key-1 ~/.ssh/remote-server-key-2
```

This creates two private keys and two public keys:

- `~/.ssh/remote-server-key-1` and `~/.ssh/remote-server-key-1.pub`
- `~/.ssh/remote-server-key-2` and `~/.ssh/remote-server-key-2.pub`

Never share or commit the private files. Only the `.pub` files belong on the server.

## 3. Add both public keys to the server

Use the provider's browser console or its initial SSH key to connect once:

```bash
ssh SERVER_USER@SERVER_IP
```

On the server, create the SSH directory and authorized-keys file:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

From the local computer, append both public keys to the server:

```bash
cat ~/.ssh/remote-server-key-1.pub | ssh SERVER_USER@SERVER_IP "cat >> ~/.ssh/authorized_keys"
cat ~/.ssh/remote-server-key-2.pub | ssh SERVER_USER@SERVER_IP "cat >> ~/.ssh/authorized_keys"
```

Check that the server's SSH configuration permits public-key authentication:

```bash
sudo sshd -T | grep -E 'pubkeyauthentication|passwordauthentication'
```

The output should include `pubkeyauthentication yes`. Restart SSH only after validating any configuration changes:

```bash
sudo systemctl restart ssh
```

## 5. Install and configure Nginx

Run the following commands on your local computer, from the repository directory. Do not run these scripts inside the SSH session on the server: the scripts use your local private key to connect to the server. Git Bash, WSL, or another Bash shell is recommended on Windows:

```bash
export SERVER_USER=ubuntu
export SERVER_HOST=SERVER_IP
export SSH_KEY="$HOME/.ssh/remote-server-key-1"
```

Install Nginx and configure it to serve this project's web root from your local computer:

```bash
bash ./scripts/configure-nginx.sh
```

The script installs Nginx, uploads [`server/nginx-site.conf`](server/nginx-site.conf), enables the site, validates the configuration, and starts Nginx. The default server block uses `server_name _`, so you can visit `http://SERVER_IP` without a domain.

Verify the service and configuration:

```bash
ssh -i "$SSH_KEY" "$SERVER_USER@$SERVER_HOST" "systemctl is-active nginx && curl --fail --silent http://127.0.0.1/ | head"
```

## 6. Test both keys

From the local computer, connect with each private key:

```bash
ssh -i ~/.ssh/remote-server-key-1 SERVER_USER@SERVER_IP
ssh -i ~/.ssh/remote-server-key-2 SERVER_USER@SERVER_IP
```

After each connection, confirm the remote host and user:

```bash
hostname
whoami
```

Both commands must authenticate successfully without copying either private key to the server.

## 7. Configure an SSH alias

Create or edit `~/.ssh/config` on the local computer:

```sshconfig
Host remote-server-key-1
   HostName SERVER_IP
   User SERVER_USER
   IdentityFile ~/.ssh/remote-server-key-1
   IdentitiesOnly yes

Host remote-server-key-2
   HostName SERVER_IP
   User SERVER_USER
   IdentityFile ~/.ssh/remote-server-key-2
   IdentitiesOnly yes
```

Protect the configuration and connect using either alias:

```bash
chmod 600 ~/.ssh/config
ssh remote-server-key-1
ssh remote-server-key-2
```

## 8. Deploy the static site with rsync

The deployment script creates the remote web root, then synchronizes [`site/`](site/) to it. `--delete` keeps removed local files from remaining on the server, so review the destination variables before deploying.

```bash
export SERVER_USER=ubuntu
export SERVER_HOST=SERVER_IP
export SSH_KEY="$HOME/.ssh/remote-server-key-1"

bash ./scripts/deploy.sh --dry-run
bash ./scripts/deploy.sh
```

After changing an HTML, CSS, or image file, run `bash ./scripts/deploy.sh` again and refresh `http://SERVER_IP`.

To use a domain, point its DNS A record to `SERVER_IP`, replace `server_name _;` in [`server/nginx-site.conf`](server/nginx-site.conf) with your domain, rerun `./scripts/configure-nginx.sh`, and then add HTTPS with a certificate tool such as Certbot.

## Optional: install fail2ban

On Ubuntu, install and enable `fail2ban`:

```bash
sudo apt update
sudo apt install -y fail2ban
sudo systemctl enable --now fail2ban
sudo fail2ban-client status sshd
```

Ensure your own IP address is allowlisted before enabling aggressive bans, and keep an existing SSH session open while testing firewall or SSH changes.

## Security checklist

- The repository contains documentation only; private keys are never committed.
- The server firewall allows SSH only from trusted addresses where practical.
- Both key-based login commands and both SSH aliases have been tested.
- The provider, server IP, and username are recorded privately rather than exposed in this repository.

https://roadmap.sh/projects/static-site-server
