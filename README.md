= syncNbackup =

== sync.sh ==

Dependencies: unison, sshfs, backup.sh on the remote host (see below)

Syncronizes a local folder with a remote folder using unison over ssh (sshfs).

When unison ssh support didn't offer the latest ciphers/MAC (on freebsd), this was my workaround.

To configure it, edit the script and change the config section according to your need

== backup.sh ==

Dependencies: rsync

Creates rolling incremental backups (default 10) using hardlinks, the same way Time Machine does on OSX

To configure it, edit the script and change the config section according to your need.

backup.sh takes a single argument as a parameter: the folder you want to backup WITHOUT a '/' at the end.

