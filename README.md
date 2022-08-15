# Kratos
> Configuration files and automation scripts for my home server setup.

| Program                                                    | Usage                              | Tools          | Status |
| :--------------------------------------------------------- | :--------------------------------: | :------------: | :----: |
| [plex-server](https://plex.tv/)                            | media server                       | docker-compose | ✅ |
| [home-assistant](https://www.home-assistant.io/)           | home automation server             | docker-compose | ✅ |
| [calibre-web](https://github.com/janeczku/calibre-web)     | web-based ebook-reader             | docker-compose | ✅ |
| [gogs](https://gogs.io/)                                   | git server                         | docker-compose | ✅ |
| [homer](https://github.com/bastienwirtz/homer)             | start-page                         | docker-compose | ✅ |
| [tailscale-agent](https://tailscale.com/)                  | vpn provider                       | docker-compose | ✅ |
| [audiobookshelf](https://www.audiobookshelf.org/)          | podcast & audiobooks server        | docker-compose | ✅ |
| [podgrab](https://github.com/akhilrex/podgrab)             | podcast downloader                 | docker-compose | ✅ |
| [node-red](https://nodered.org/)                           | programmable automation interface  | docker-compose | ✅ |
| [photoview](https://github.com/photoview/photoview)        | photo gallery                      | docker-compose | ✅ |
| [draw.io](https://github.com/jgraph/drawio)                | web-base diagramming software      | docker-compose | ✅ |
| [bitwarden](https://bitwarden.com/)                        | password manager                   | docker-compose | ✅ |

## Requirements

- [Docker](https://www.docker.com/#)

## Usage
To install the home server, run the following command:
```bash
./scripts/install.sh "<some-base-directory>" "<some-plex-claim-token>"
```

To uninstall the home server, run the following command:
```bash
./scripts/uninstall.sh "<some-base-directory>"
```
