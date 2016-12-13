= syncNbackup =

== sync.sh ==

Dependencies: unison, sshfs

Syncronizes a local folder with a remote folder using unison over ssh (sshfs).

Since unison ssh support don't offer the latest ciphers/MAC, this is a workaround.

== backup.sh ==

Dependencies: rsync

Creates rolling incremental backups (default 10) using hardlinks.
