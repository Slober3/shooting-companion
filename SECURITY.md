# Security policy

Report vulnerabilities privately to the repository owner instead of opening a
public exploit issue. Do not include real backups, target photos or identifying
metadata in a report.

Version 0.1 stores its database and images in Android internal application
storage without an additional application lock. Exported `.scbackup` containers
use Argon2id and AES-256-GCM. CSV and PDF exports are intentionally unencrypted
and display a warning before creation.

No signing key, password or production dataset may be committed. Dependency and
license checks run in CI. Security support applies to the newest tagged release.
