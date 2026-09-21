# Remote Linux Server SSH Setup

This project documents how to create a remote Linux server, configure SSH access, and connect using two different SSH key pairs.

## 1. Create the server

1. Create an account with a provider such as [DigitalOcean](https://m.do.co/c/b29aa8845df8), AWS, or another cloud provider.
2. Create a small Ubuntu LTS server and note its public IP address.
3. Record the default server user supplied by the provider, such as `root` or `ubuntu`.
4. Allow inbound TCP port `22` in the provider firewall. Restrict the source to your IP address when possible.

For the commands below, replace these placeholders:

- `SERVER_IP` with the server's public IP address.
- `SERVER_USER` with the provider's default Linux user.

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

## 4. Test both keys

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

## 5. Configure an SSH alias

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
