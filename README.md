<p align="center">
    <img src="./docs/vault-boy.webp" width="150">
</p>

# [G.E.C.K.](https://fallout.fandom.com/wiki/GECK)
> Configuration files and automation scripts for my G.E.C.K. ([Garden of Eden Creation Kit](https://fallout.fandom.com/wiki/GECK)) server.

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

To backup the home server, run the following command:
```bash
make backup
```

## Programs

| Program                                                               | Usage                              | Tools          | Status |
| :-------------------------------------------------------------------- | :--------------------------------: | :------------: | :----: |
| [pi-hole](https://pi-hole.net/)                                       | dns server                         | docker-compose | ✅ |
| [nginx-proxy-manager](https://nginxproxymanager.com/)                 | reverse-proxy server               | docker-compose | ✅ |
| [tailscale-agent](https://tailscale.com/)                             | modern vpn service                 | docker-compose | ✅ |
| [nextcloud](https://nextcloud.com/)                                   | dropbox replacement                | docker-compose | ✅ |
| [homer](https://github.com/bastienwirtz/homer)                        | start-page                         | docker-compose | ✅ |
| [plex-server](https://plex.tv/)                                       | media server                       | docker-compose | ✅ |
| [calibre-web](https://github.com/janeczku/calibre-web)                | web-based ebook-reader             | docker-compose | ✅ |
| [audiobookshelf](https://www.audiobookshelf.org/)                     | podcast & audiobooks server        | docker-compose | ✅ |
| [gogs](https://gogs.io/)                                              | git server                         | docker-compose | ✅ |
| [podgrab](https://github.com/akhilrex/podgrab)                        | podcast downloader                 | docker-compose | ✅ |
| [draw.io](https://github.com/jgraph/drawio)                           | web-base diagramming software      | docker-compose | ✅ |
| [bitwarden](https://bitwarden.com/)                                   | password manager                   | docker-compose | ✅ |
| [home-assistant](https://www.home-assistant.io/)                      | home automation server             | docker-compose | ✅ |
| [node-red](https://nodered.org/)                                      | programmable automation interface  | docker-compose | ✅ |
| [grafana](https://grafana.com/)                                       | Monitoring dashboard web interface | docker-compose | ✅ |
| [influxdb](https://www.influxdata.com/)                               | Monitoring database                | docker-compose | ✅ |
| [telegraf](https://www.influxdata.com/time-series-platform/telegraf/) | Telemetry aggregator for InfluxDB  | docker-compose | ✅ |
