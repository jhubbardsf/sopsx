# sopsx

**SOPS wrapper that automatically sets AWS_PROFILE based on KMS keys**

Stop manually setting `AWS_PROFILE` every time you run SOPS. `sopsx` automatically detects the correct AWS profile by extracting the KMS key from your encrypted files or `.sops.yaml` config.

## The Problem

When using [SOPS](https://github.com/getsops/sops) with AWS KMS across multiple AWS accounts, you constantly need to remember which profile to use:

```bash
# The painful way
AWS_PROFILE=dev-admin sops -d dev/secrets.enc.yaml
AWS_PROFILE=staging-admin sops -d staging/secrets.enc.yaml
AWS_PROFILE=prod-admin sops -d prod/secrets.enc.yaml
```

With multiple projects and accounts, you're always context-switching and hunting for the right profile.

## The Solution

Just use `sopsx` instead of `sops`:

```bash
# The easy way
sopsx -d dev/secrets.enc.yaml      # Profile auto-detected!
sopsx -d staging/secrets.enc.yaml  # Profile auto-detected!
sopsx -d prod/secrets.enc.yaml     # Profile auto-detected!
```

`sopsx` extracts the KMS ARN from the encrypted file (or `.sops.yaml`), finds the matching AWS account in your `~/.aws/config`, and automatically sets `AWS_PROFILE` before calling SOPS.

## Installation

### Homebrew (Recommended)

```bash
brew install jhubbardsf/sopsx/sopsx
```

### Manual Install

```bash
curl -fsSL https://raw.githubusercontent.com/jhubbardsf/sopsx/main/install.sh | bash
```

## Requirements

- **macOS** or Linux
- **bash** 4.0+
- **sops** (the tool we're wrapping)
- **AWS CLI v2** with SSO profiles configured

## Usage

`sopsx` is a drop-in replacement for `sops`. Just use it the same way:

```bash
# Decrypt a file
sopsx -d secrets.enc.yaml

# Edit an encrypted file
sopsx secrets.enc.yaml

# Encrypt a new file (uses .sops.yaml for KMS key)
sopsx -e secrets.yaml > secrets.enc.yaml

# Show version
sopsx --version

# Show help
sopsx help
```

### Debug Mode

See exactly how `sopsx` detects the profile:

```bash
SOPSX_DEBUG=1 sopsx -d secrets.enc.yaml
```

Output:
```
[sopsx debug] sopsx called with args: -d secrets.enc.yaml
[sopsx debug] Found file argument: secrets.enc.yaml
[sopsx debug] Strategy 1: Extracting KMS from encrypted file
[sopsx debug] File appears to have SOPS metadata
[sopsx debug] Found KMS ARN in file: arn:aws:kms:us-east-1:123456789012:key/abc-123
[sopsx debug] Extracted account ID: 123456789012
[sopsx debug] Using AWS profile: dev-admin
```

## Git Integration

Get readable diffs of encrypted files with git:

**~/.gitconfig:**
```ini
[diff "sopsdiffer"]
    textconv = sopsx -d
```

**Your repo's .gitattributes:**
```
*.enc.yaml diff=sopsdiffer
*.enc.json diff=sopsdiffer
secrets/*.yaml diff=sopsdiffer
```

Now `git diff` shows decrypted content instead of encrypted blobs.

## How It Works

1. **Extract KMS ARN** - `sopsx` finds the KMS key ARN from:
   - The encrypted file's SOPS metadata (preferred)
   - The `.sops.yaml` config file (matches file path to creation rules)

2. **Parse Account ID** - Extracts the 12-digit AWS account ID from the KMS ARN:
   ```
   arn:aws:kms:us-east-1:123456789012:key/abc-123
                        ^^^^^^^^^^^^
   ```

3. **Find Best Profile** - Searches `~/.aws/config` for SSO profiles matching that account, preferring higher-privilege roles:
   - AdministratorAccess (priority 100)
   - PowerUserAccess (priority 50)
   - DeveloperAccess (priority 30)
   - ReadOnlyAccess (priority 10)

4. **Execute SOPS** - Sets `AWS_PROFILE` and runs SOPS with your original arguments.

## Configuration

### AWS Config Format

`sopsx` expects SSO profiles in your `~/.aws/config`:

```ini
[profile dev-admin]
sso_session = my-sso
sso_account_id = 123456789012
sso_role_name = AdministratorAccess
region = us-east-1

[profile staging-admin]
sso_session = my-sso
sso_account_id = 234567890123
sso_role_name = AdministratorAccess
region = us-east-1

[sso-session my-sso]
sso_start_url = https://my-company.awsapps.com/start
sso_region = us-east-1
sso_registration_scopes = sso:account:access
```

### .sops.yaml Format

Standard SOPS config with KMS keys:

```yaml
creation_rules:
  - path_regex: dev/.*\.enc\.yaml$
    kms: arn:aws:kms:us-east-1:123456789012:key/dev-key-id

  - path_regex: staging/.*\.enc\.yaml$
    kms: arn:aws:kms:us-east-1:234567890123:key/staging-key-id

  - path_regex: prod/.*\.enc\.yaml$
    kms: arn:aws:kms:us-east-1:345678901234:key/prod-key-id
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `SOPSX_DEBUG` | Set to `1` to enable debug output |
| `AWS_CONFIG_FILE` | Override default `~/.aws/config` location |

## File Locations

| File | Purpose |
|------|---------|
| `~/.aws/config` | AWS CLI configuration with SSO profiles |
| `.sops.yaml` | SOPS configuration (searched in current and parent directories) |

## Troubleshooting

### "Could not determine AWS account ID"

`sopsx` couldn't find a KMS ARN. Check:
- Is the file actually SOPS-encrypted?
- Is there a `.sops.yaml` in the current or parent directory?
- Does the `.sops.yaml` have a `path_regex` matching your file?

### "No AWS profile found for account"

Found the account ID but no matching profile. Check:
- Does `~/.aws/config` have a profile with `sso_account_id = <account>`?
- Is the profile using SSO (has `sso_account_id` field)?

### Profile detected but SOPS fails

The profile exists but AWS credentials aren't working:
- Run `aws sso login` to refresh your SSO session
- Check if [aws-sso-refresh](https://github.com/jhubbardsf/aws-sso-refresh) can help automate this

## Pairs Well With

- **[aws-sso-refresh](https://github.com/jhubbardsf/aws-sso-refresh)** - Auto-refresh AWS SSO sessions before they expire
- **[sops](https://github.com/getsops/sops)** - The secrets manager we're wrapping

## Contributing

Contributions welcome! Feel free to open issues or PRs.

## License

MIT
