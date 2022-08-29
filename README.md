# Kratos
> Configuration files and automation scripts for my home server setup.

## Requirements

- [GNU Make](https://www.gnu.org/software/make/)
- [Docker](https://www.docker.com/#)

## Usage
To start the home server, run the following command:
```bash
make start
```

To stop the home server, run the following command:
```bash
make stop
```

## Programs

| Program                                                    | Usage                              | Tools          | Status |
| :--------------------------------------------------------- | :--------------------------------: | :------------: | :----: |
| [pi-hole](https://pi-hole.net/)                            | dns server                         | docker-compose | ✅ |
| [nginx-proxy-manager](https://nginxproxymanager.com/)      | reverse-proxy server               | docker-compose | ✅ |
| [tailscale-agent](https://tailscale.com/)                  | modern vpn service                 | docker-compose | ✅ |
| [nextcloud](https://nextcloud.com/)                        | dropbox replacement                | docker-compose | ✅ |
| [homer](https://github.com/bastienwirtz/homer)             | start-page                         | docker-compose | ✅ |
| [plex-server](https://plex.tv/)                            | media server                       | docker-compose | ✅ |
| [calibre-web](https://github.com/janeczku/calibre-web)     | web-based ebook-reader             | docker-compose | ✅ |
| [audiobookshelf](https://www.audiobookshelf.org/)          | podcast & audiobooks server        | docker-compose | ✅ |
| [gogs](https://gogs.io/)                                   | git server                         | docker-compose | ✅ |
| [podgrab](https://github.com/akhilrex/podgrab)             | podcast downloader                 | docker-compose | ✅ |
| [draw.io](https://github.com/jgraph/drawio)                | web-base diagramming software      | docker-compose | ✅ |
| [bitwarden](https://bitwarden.com/)                        | password manager                   | docker-compose | ✅ |