# Zeus
> Configuration files and automation scripts for my home server.

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
| [duplicati](https://www.duplicati.com/)                               | automated backup solution          | docker-compose | ✅ |
| [homer](https://github.com/bastienwirtz/homer)                        | start-page                         | docker-compose | ✅ |
| [plex-server](https://plex.tv/)                                       | media server                       | docker-compose | ✅ |
| [navidrome](https://github.com/navidrome/navidrome)                   | modern music server                | docker-compose | ✅ |
| [calibre-web](https://github.com/janeczku/calibre-web)                | web-based ebook-reader             | docker-compose | ✅ |
| [audiobookshelf](https://www.audiobookshelf.org/)                     | podcast & audiobooks server        | docker-compose | ✅ |
| [gogs](https://gogs.io/)                                              | git server                         | docker-compose | ✅ |
| [podgrab](https://github.com/akhilrex/podgrab)                        | podcast downloader                 | docker-compose | ✅ |
| [draw.io](https://github.com/jgraph/drawio)                           | web-base diagramming software      | docker-compose | ✅ |
| [bitwarden](https://bitwarden.com/)                                   | password manager                   | docker-compose | ✅ |
| [grafana](https://grafana.com/)                                       | Monitoring dashboard web interface | docker-compose | ✅ |
| [influxdb](https://www.influxdata.com/)                               | Monitoring database                | docker-compose | ✅ |
| [telegraf](https://www.influxdata.com/time-series-platform/telegraf/) | Telemetry aggregator for InfluxDB  | docker-compose | ✅ |
