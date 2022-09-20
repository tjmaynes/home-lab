<p align="center">
    <img src="./docs/vault-boy.webp" width="150">
</p>

# [G.E.C.K.](https://fallout.fandom.com/wiki/geck)
> Configuration files and automation scripts for my G.E.C.K. ([Garden of Eden Creation Kit](https://fallout.fandom.com/wiki/geck)) server.

## Requirements

- [GNU Make](https://www.gnu.org/software/make/)
- [Docker](https://www.docker.com/#)

## Usage
To install home server dependencies, run the following command:
```bash
make install
```

To start the home server, run the following command:
```bash
make start
```

To stop the home server, run the following command:
```bash
make stop
```

To restart the home server, run the following command:
```bash
make restart
```

To run a full backup of the home server, run the following command:
```bash
make backup
```

## Programs

| Program                                                                               | Usage                              | Tools          | Status |
| :------------------------------------------------------------------------------------ | :--------------------------------: | :------------: | :----: |
| [tailscale-agent](https://tailscale.com/)                                             | modern vpn service                 | docker-compose | ✅ |
| [nginx-proxy-manager](https://nginxproxymanager.com/)                                 | reverse-proxy server               | docker-compose | ✅ |
| [homer](https://github.com/bastienwirtz/homer)                                        | start-page                         | docker-compose | ✅ |
| [jellyfin](https://jellyfin.org/)                                                     | media server                       | docker-compose | ✅ |
| [navidrome](https://github.com/navidrome/navidrome)                                   | modern music server                | docker-compose | ✅ |
| [bonob-agent](https://github.com/simojenki/bonob)                                     | modern music server                | docker-compose | ✅ |
| [calibre-web](https://github.com/janeczku/calibre-web)                                | web-based ebook-reader             | docker-compose | ✅ |
| [miniflux-web](https://miniflux.app/)                                                 | rss reader                         | docker-compose | ✅ |
| [audiobookshelf](https://www.audiobookshelf.org/)                                     | podcast & audiobooks server        | docker-compose | ✅ |
| [gogs](https://gogs.io/)                                                              | git server                         | docker-compose | ✅ |
| [podgrab](https://github.com/akhilrex/podgrab)                                        | podcast downloader                 | docker-compose | ✅ |
| [bitwarden](https://bitwarden.com/)                                                   | password manager                   | docker-compose | ✅ |
| [home-assistant](https://www.home-assistant.io/)                                      | home automation server             | docker-compose | ✅ |
| [node-red](https://nodered.org/)                                                      | programmable automation interface  | docker-compose | ✅ |
| [portainer](https://docs.portainer.io/v/ce-2.9/start/install)                         | monitoring docker containers       | docker-compose | ✅ |
| [grafana-agent](https://github.com/grafana/agent)                                     | monitoring agent for grafana cloud | docker-compose | ✅ |
| [promtail-agent](https://grafana.com/docs/loki/latest/clients/promtail/installation/) | logging agent for grafana cloud    | docker-compose | ✅ |
