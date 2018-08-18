# Medusa

[![Build Status](https://travis-ci.org/amireh/medusa.svg?branch=master)](https://travis-ci.org/amireh/medusa)

A shell interface to [Ansible as a portable Docker
container](https://hub.docker.com/r/amireh/ansible/).

**Usable in both development and production.**

**Easy to use and install.**

**Consistent experience.**

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## Table of Contents

- [Dependencies](#dependencies)
- [Installation](#installation)
  - [Install script](#install-script)
  - [Verify installation](#verify-installation)
  - [Git install](#git-install)
  - [Updating](#updating)
- [Features](#features)
  - [Overridden Ansible behavior](#overridden-ansible-behavior)
    - [Predictable config file resolving](#predictable-config-file-resolving)
  - [Enhanced Ansible <-> Docker interoperability](#enhanced-ansible---docker-interoperability)
    - [Host directory mounts](#host-directory-mounts)
    - [Play variables](#play-variables)
    - [Host IP address resolving](#host-ip-address-resolving)
    - [Vault password stashing](#vault-password-stashing)
    - [Masquerading](#masquerading)
    - [Ansible image extensibility](#ansible-image-extensibility)
- [Configuration](#configuration)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Dependencies

- Bash 3.2+
- Docker

## Installation

### Install script

To install or update Medusa, you can use the [install script](medusa-installer)
using cuRL:

```shell
curl -fsSL https://github.com/amireh/medusa/raw/master/medusa-installer | bash
```

Or using wget:

```shell
wget -qO- https://github.com/amireh/medusa/raw/master/medusa-installer | bash
```

Close your current terminal and open a new one to reload the profile.

The script clones the medusa repository to `~/.medusa` and adjusts your profile
(`~/.bashrc` or `~/.bash_profile`) to add `medusa` to the PATH and enable TAB
completion.

You can customize the install directory, source, tag, and profile using the
`MEDUSA_DIR`, `MEDUSA_SRC`, `MEDUSA_REF`, and `BASH_PROFILE` variables. Eg:
`curl ... | MEDUSA_DIR="/opt/medusa" bash`. Ensure that the `MEDUSA_DIR` does
not contain a trailing slash.

### Verify installation

Running `medusa info` should output some information about the Medusa
installation. If you still get a command-not-found error, ensure the changes to
your profile are present and that you've restarted the terminal session.

### Git install

While running the script only requires cloning the repository, there are
optional features to enable as shown below.

```shell
# Configure those variables only for the use of this session; they are not required nor used by medusa
export MEDUSA_DIR=/opt/medusa
export BASH_PROFILE=~/.bashrc

# Clone the repository:
git clone https://github.com/amireh/medusa "$MEDUSA_DIR"

# You can now run `bin/medusa` directly:
"$MEDUSA_DIR"/bin/medusa help

# Optional: add it to your `PATH` in your bash profile:
echo 'export PATH="/opt/medusa/bin:${PATH}"' >> "$BASH_PROFILE"

# Optional: use the bash completions script:
{
  echo 'if [ -s /opt/medusa/completions/medusa.bash ]; then'
  echo '  source /opt/medusa/completions/medusa.bash'
  echo 'fi'
} >> "$BASH_PROFILE"
```

### Updating

An update can be done either by re-running the installer or by pulling from git
directly:

```shell
( cd /path/to/medusa && git pull origin master )
```

## Features

### Overridden Ansible behavior

The following modifications made by `medusa` change how Ansible operates. Each
mod may be opted-out of by supplying the relevant environment variables (see
`medusa --help` for more info.)

#### Predictable config file resolving

If `ANSIBLE_CONFIG` is not supplied in the environment __and__ there is no
`ansible.cfg` in the current directory, medusa will look for `ansible.cfg` next
to the playbook being applied and export that as `ANSIBLE_CONFIG` if found.

The intent of this this mod is to achieve predictability in output that is not
affected by `PWD`.

Read more about Ansible's original rules for resolving the config file [here](
https://docs.ansible.com/ansible/latest/reference_appendices/config.html#the-configuration-file).

### Enhanced Ansible <-> Docker interoperability

With the goal of making Ansible inside Docker as native an experience as
possible, Medusa tries to provide usable and unopinionated (to a reasonable
extent) solutions to the various issues that get in the way. This section goes
over those issues and their accompanying solutions.

#### Host directory mounts

- `PWD` from where `medusa` was run is mounted into `{{ medusa_source_dir }}`
- `~/.ssh` is mounted if it exists

#### Play variables

The following variables are made available by medusa for use in playbooks:

```yaml
# Host path to the source directory from which Medusa was run.
# 
# This can be used, for example, to bind-mount a host folder inside a
# container that has access to the host's Docker unix socket.
medusa_host_dir: # [Path]

# Container path to where the source directory from the host is mounted at.
medusa_source_dir: # [Path]

# Container path to where the medusa custom roles can be imported from.
medusa_roles_dir: # [Path]

# The resolved Docker host IP address to be used inside containers.
dockerhost: # [IP]

# The primary group ID (GID) of the host user.
dockerhost_gid: # [String]

# The user ID (UID) of the host user.
dockerhost_uid: # [String]

# The name of the masquerading group on the container.
dockerhost_group: # [String]

# The name of the masquerading user on the container.
dockerhost_user: # [String]
```

#### Host IP address resolving

While inside a container, attempting to communicate with the Docker host  is
difficult without a static IP address. Unfortunately, that IP address is
unpredictable as it depends on the host's network interfaces, the Docker server
version, the platform, or a combination of those and more.

For this reason, Medusa attempts to resolve that IP address and provide it as a
playbook variable that can then be used by containers to reach the services on
the host system (e.g. a database server or a service not part of the Docker
network.)

Keep in mind that for this to work, the services on the host machine must be
listening on _all_ network interfaces (e.g. `localhost` and `127.0.0.1` won't
work!)

An emerging convention is to bind that address to the hostname `dockerhost`
which is then used by containers instead of the explicit IP. At
[Instructure](https://instructure.com) we opt to use `lvh.me` because that will
also resolve to `127.0.0.1` on the _host_ machine which is necessary if the
host services need to refer to themselves.

Examples can be found in [examples/dockerhost](examples/dockerhost/README.md)
and [examples/dockerhost-dns](examples/dockerhost-dns/README.md).

#### Vault password stashing

_TODO_

#### Masquerading

_TODO_

#### Ansible image extensibility

It is often necessary to install certain Python and system packages for modules
to work, or to pull down custom roles from Ansible Galaxy, or perhaps to
install custom Ansible modules from source.

Medusa makes it possible to extend the source Ansible Docker image as desired
by means of writing a regular playbook.

Further, the Docker tagging system is utilized to ensure that an image is built
at most once for any one version of the extension playbook. This process is
transparent to users and doesn't impose a different signature for running
Ansible (through Medusa, that is.)

Building a custom image requires:

- a playbook that provisions the container (which is based on [Alpine
  Linux][1], the [Dockerfile][2] is available for reference)
- path to that playbook be specified in `ansible.cfg` under
  `medusa.ansible_extension_playbook` (the [configuration](#4-configuration)
  section covers configuring Medusa through `ansible.cfg`)

An example is available at [examples/extend](examples/extend/README.md).

[1]: https://alpinelinux.org/
[2]: https://hub.docker.com/r/amireh/ansible/~/dockerfile/

## Configuration

name | default | description
---- | ------- | -----------
`MEDUSA_ANSIBLE_IMAGE`  | some tag of [amireh/ansible](https://hub.docker.com/r/amireh/ansible/tags/) |
`MEDUSA_CONTAINER` | None | 
`MEDUSA_DOCKERHOST` | _inferred_ |
`MEDUSA_INFER_CONFIG` | 1 |
`MEDUSA_SETTINGS_FILE` | `settings.yml` | 
`MEDUSA_SHARE_DIR` | `/mnt/medusa` |
`MEDUSA_SSH_DIR` | `~/.ssh` |
`MEDUSA_VERBOSE` | 0 |

The environment variables can also be configured in the INI `ansible.cfg` file
by removing the MEDUSA_ prefix and lower-casing the keys under the special
`[medusa]` group. For example:

```ini
[defaults]
# ansible config

[medusa]
container = my-ansible
infer_config = 0
settings_file = 
```
