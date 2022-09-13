# Zeus
> Configuration files and automation scripts for my home server.

## Requirements

- [GNU Make](https://www.gnu.org/software/make/)
- [Docker](https://www.docker.com/#)

## Usage
To install home server dependencies, run the following command:
```bash
ENV_FILE=.envrc.production make install
```

To start the home server, run the following command:
```bash
ENV_FILE=.envrc.production make start
```

To stop the home server, run the following command:
```bash
ENV_FILE=.envrc.production make stop
```

To run a full backup of the home server, run the following command:
```bash
ENV_FILE=.envrc.production make backup
```

To run the home server using `vagrant`, run the following command:
```bash
make dev
```

## Programs

| Program                                                               | Usage                              | Tools          | Status |
| :-------------------------------------------------------------------- | :--------------------------------: | :------------: | :----: |
| [pi-hole](https://pi-hole.net/)                                       | dns server                         | docker-compose | ✅ |
| [nginx-proxy-manager](https://nginxproxymanager.com/)                 | reverse-proxy server               | docker-compose | ✅ |
| [tailscale-agent](https://tailscale.com/)                             | modern vpn service                 | docker-compose | ✅ |
| [homer](https://github.com/bastienwirtz/homer)                        | start-page                         | docker-compose | ✅ |
| [plex-server](https://plex.tv/)                                       | media server                       | docker-compose | ✅ |
| [navidrome](https://github.com/navidrome/navidrome)                   | modern music server                | docker-compose | ✅ |
| [calibre-web](https://github.com/janeczku/calibre-web)                | web-based ebook-reader             | docker-compose | ✅ |
| [audiobookshelf](https://www.audiobookshelf.org/)                     | podcast & audiobooks server        | docker-compose | ✅ |
| [gogs](https://gogs.io/)                                              | git server                         | docker-compose | ✅ |
| [podgrab](https://github.com/akhilrex/podgrab)                        | podcast downloader                 | docker-compose | ✅ |
| [bitwarden](https://bitwarden.com/)                                   | password manager                   | docker-compose | ✅ |
| [portainer](https://docs.portainer.io/v/ce-2.9/start/install)         | monitoring docker containers       | docker-compose | ✅ |
| [grafana](https://grafana.com/)                                       | monitoring dashboard web interface | docker-compose | ✅ |
