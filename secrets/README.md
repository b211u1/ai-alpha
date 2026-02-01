# Secret Management with sops-nix

This project uses [sops](https://github.com/getsops/sops) with [age](https://github.com/FiloSottile/age) encryption for secure secret management.

## Initial Setup (One-time)

### 1. Generate an age keypair

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

### 2. Get your public key

```bash
age-keygen -y ~/.config/sops/age/keys.txt
```

This outputs something like: `age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p`

### 3. Update .sops.yaml

Edit `.sops.yaml` in the project root and replace the placeholder with your public key:

```yaml
keys:
  - &user age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
```

### 4. Create and encrypt secrets

```bash
# Copy the example file
cp secrets/secrets.yaml.example secrets/secrets.yaml

# Edit with your actual API keys
$EDITOR secrets/secrets.yaml

# Encrypt the file (modifies in place)
sops --encrypt --in-place secrets/secrets.yaml
```

## Usage

### View/Edit encrypted secrets

```bash
# View decrypted secrets (does not modify file)
sops --decrypt secrets/secrets.yaml

# Edit secrets (decrypts, opens editor, re-encrypts on save)
sops secrets/secrets.yaml
```

### How it works

When you enter the nix shell (`nix develop`), the shellHook:

1. Checks for `secrets/secrets.yaml`
2. Checks for your age key at `~/.config/sops/age/keys.txt`
3. Decrypts and exports secrets as environment variables

## Adding new secrets

1. Edit the encrypted file: `sops secrets/secrets.yaml`
2. Add new key-value pairs in YAML format
3. Save and close - sops automatically re-encrypts

## Team Setup

To share secrets with team members:

1. Get each team member's age public key
2. Add their keys to `.sops.yaml`:
   ```yaml
   keys:
     - &user1 age1...
     - &user2 age1...

   creation_rules:
     - path_regex: secrets/.*\.yaml$
       key_groups:
         - age:
             - *user1
             - *user2
   ```
3. Re-encrypt existing secrets: `sops updatekeys secrets/secrets.yaml`

## Security Notes

- **Never commit** `secrets.yaml.decrypted` or unencrypted secrets
- **Safe to commit** encrypted `secrets.yaml` files
- Keep your private key (`~/.config/sops/age/keys.txt`) secure
- The `.gitignore` excludes common unencrypted patterns

## Troubleshooting

### "No age key found"

Ensure your key exists at `~/.config/sops/age/keys.txt` or set:
```bash
export SOPS_AGE_KEY_FILE=/path/to/your/keys.txt
```

### "Could not decrypt"

- Verify your public key is in `.sops.yaml`
- Re-encrypt if keys changed: `sops updatekeys secrets/secrets.yaml`
