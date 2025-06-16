# Git Commit Signing Setup Script - Documentation

This document explains how to use the `git_signing_key_setup.sh` script to configure **signed commits** in Git using either **SSH** or **GPG**, and optionally upload the key to GitHub.

## 🔧 Script Capabilities

* Generate **SSH signing keys** or **GPG keys** for commit signing
* Import and configure previously generated SSH signing keys
* Upload SSH signing keys to GitHub via API
* Configure Git to use the keys for commit signing

## 📦 Requirements

* macOS system with:

  * `brew` (Homebrew)
  * `curl`, `ssh-agent`, `gpg`, `git`

---

## 🚀 Usage

```bash
./git_signing_key_setup.sh [options]
```

### Options

| Flag            | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| `-f`            | Force regenerate the signing key                                     |
| `-x`            | Export-only mode: skip key generation, just export key to GitHub     |
| `--import`      | Use existing SSH signing key located at `~/.ssh/git-ssh-signing-key` |
| `-g`            | Use GPG mode instead of SSH signing                                  |
| `-e <email>`    | Email address for GPG key generation                                 |
| `-t <token>`    | GitHub personal access token (for API key upload)                    |
| `-u <username>` | GitHub username                                                      |

---

## 🔐 SSH Signing Mode (Default)

### Generate New SSH Signing Key

```bash
./git_signing_key_setup.sh
```

### Use an Existing SSH Signing Key (imported/copied from another machine)

```bash
./git_signing_key_setup.sh --import
```

### Upload SSH Key to GitHub

```bash
./git_signing_key_setup.sh -t YOUR_GITHUB_TOKEN -u your_username
```

> Make sure the SSH key files exist at `~/.ssh/git-ssh-signing-key` and `~/.ssh/git-ssh-signing-key.pub`.

---

## 🔐 GPG Signing Mode

### Generate GPG Key and Setup Git

```bash
./git_signing_key_setup.sh -g -e your.email@example.com
```

This will:

1. Install required tools: `gpg2`, `gnupg`, `pinentry-mac`
2. Launch GPG key generation
3. Export your public GPG key
4. Configure Git with your GPG key

You’ll be prompted to upload the public key to:
[https://github.com/settings/keys](https://github.com/settings/keys)

---

## 🛠 Files & Key Paths

* **SSH Key**:

  * Private: `~/.ssh/git-ssh-signing-key`
  * Public: `~/.ssh/git-ssh-signing-key.pub`

* **GPG Key (optional)**:

  * Exported Public Key: `~/your.email@example.com_gpgkey.asc`

---

## 🌐 GitHub Integration

The script uses GitHub’s API to upload **SSH signing keys**:

```bash
curl -H "Authorization: token $GITHUB_TOKEN" \
     -H "Accept: application/vnd.github+json" \
     https://api.github.com/user/ssh_signing_keys \
     -d '{"key":"your-public-key","title":"Generated Key"}'
```

Ensure your token has `write:public_key` permission.

---

## 🧪 Testing

To test that signing works:

```bash
git commit -S -m "Test commit"
```

You should see a ✅ "Verified" badge next to your commit on GitHub.

---

## ✅ Summary

| Use Case                | Command Example                                   |
| ----------------------- | ------------------------------------------------- |
| New SSH key setup       | `./git_signing_key_setup.sh`                      |
| Import existing SSH key | `./git_signing_key_setup.sh --import`             |
| SSH key + GitHub upload | `./git_signing_key_setup.sh -t TOKEN -u USERNAME` |
| GPG mode                | `./git_signing_key_setup.sh -g -e your@email.com` |

---

## 📬 Questions / Improvements

For any improvements, raise an issue or PR on the repo where this script is hosted.

Happy Git signing! 🔏
