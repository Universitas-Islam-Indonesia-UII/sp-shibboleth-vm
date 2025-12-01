# sp-shibboleth-vm

Lightweight installer and configuration files to set up a Shibboleth Service Provider (SP) + Nginx on Ubuntu.

Overview
- Installs Nginx, Shibboleth SP, builds required Nginx modules, and copies configuration helpers for integrating Shibboleth with Nginx and PHP-FPM.
- Key orchestration is performed by the installer script: [install.sh](install.sh).

Quick links to workspace files
- [install.sh](install.sh)
- [shibboleth2.xml](shibboleth2.xml)
- [attribute-map.xml](attribute-map.xml)
- [nginx-default.conf](nginx-default.conf)
- [nginx-ssl.conf](nginx-ssl.conf)
- [shibboleth.conf](shibboleth.conf)
- [shib_fastcgi_params](shib_fastcgi_params)
- [shib_clear_headers](shib_clear_headers)
- [README.md](README.md)

Prerequisites
- Run as root (the installer checks EUID).
- Ubuntu-based system with internet access to download packages and build modules.

Configuration before install
- Set the hostname variables at the top of [install.sh](install.sh):
  - [`HOSTNAME`](install.sh)
  - [`IDP_HOSTNAME`](install.sh)
- Ensure the workspace files above are present in the current directory when running [install.sh](install.sh). The installer will copy:
  - Nginx configs: [nginx-default.conf](nginx-default.conf), [nginx-ssl.conf](nginx-ssl.conf)
  - Shibboleth configs: [shibboleth2.xml](shibboleth2.xml), [attribute-map.xml](attribute-map.xml)
  - Supervisor config: [shibboleth.conf](shibboleth.conf)
  - Nginx helper files: [shib_fastcgi_params](shib_fastcgi_params), [shib_clear_headers](shib_clear_headers)

Install (quick)
```sh
# make sure you're in the directory with the repository files and run as root
sudo bash ./install.sh
```

What the installer does (high level)
- Installs apt packages including nginx, supervisor, shibboleth-sp, php-fpm.
- Adds official nginx repository and GPG key.
- Builds and installs Nginx modules (headers-more and nginx-http-shibboleth) to match the installed nginx version.
- Generates a self-signed TLS certificate and copies Nginx/Shibboleth configs into /etc.
- Runs `shib-keygen -h "${HOSTNAME}"` to generate SP keys and downloads IdP metadata from the configured IdP host.

Important files to review
- [shibboleth2.xml](shibboleth2.xml): SP configuration (entityID, SSO, metadata provider, attribute extraction/filtering, credential resolvers).
- [attribute-map.xml](attribute-map.xml): Maps incoming attribute OIDs/names to internal IDs.
- [nginx-ssl.conf](nginx-ssl.conf): Nginx server block integrating Shibboleth FastCGI responders and PHP-FPM.
- [shib_fastcgi_params](shib_fastcgi_params) and [shib_clear_headers](shib_clear_headers): Nginx helper fragments used to pass attributes and clear upstream headers.

Security notes
- The provided installer generates a self-signed certificate; replace with a valid CA-signed cert for production.
- Review cookie/cipher settings in [shibboleth2.xml](shibboleth2.xml) and TLS settings in [nginx-ssl.conf](nginx-ssl.conf).
- The sample Supervisor config ([shibboleth.conf](shibboleth.conf)) runs shibauthorizer and shibresponder as _shibd; confirm ownership and socket permissions meet your security policy.

Troubleshooting
- Check Supervisor logs in /var/log/supervisor/ (configured in [shibboleth.conf](shibboleth.conf)).
- Nginx error logs and PHP-FPM socket path must match the distro version (nginx config expects php8.3-fpm in the sample).
- If the installer fails to find files, confirm you ran it from the directory containing the repository files listed above.

License
- This repository contains configuration and installation scripts — adapt and reuse as needed for your environment.