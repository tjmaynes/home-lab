<p align="center">
    <img src="./static/images/vault-boy.webp" width="150">
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
| [cloudfared-tunnel](https://github.com/cloudflare/cloudflared)                        | cloudflare tunnel client           | systemd        | ✅ |
| [nginx-proxy-manager](https://nginxproxymanager.com/)                                 | reverse-proxy server               | docker-compose | ✅ |
| [homer](https://github.com/bastienwirtz/homer)                                        | start-page                         | docker-compose | ✅ |
| [pi-hole](https://pi-hole.net/)                                                       | dns server                         | docker-compose | ✅ |
| [cloudfared-agent](https://github.com/cloudflare/cloudflared)                         | cloudflare dns client for pihole   | docker-compose | ✅ |
| [plex-server](https://hub.docker.com/r/linuxserver/plex)                              | media server                       | docker-compose | ✅ |
| [calibre-web](https://github.com/janeczku/calibre-web)                                | web-based ebook-reader             | docker-compose | ✅ |
| [pigallary-web](https://bpatrik.github.io/pigallery2/)                                | photo gallery                      | docker-compose | ✅ |
| [audiobookshelf](https://www.audiobookshelf.org/)                                     | podcast & audiobooks server        | docker-compose | ✅ |
| [podgrab](https://github.com/akhilrex/podgrab)                                        | podcast downloader                 | docker-compose | ✅ |
| [metube](https://github.com/alexta69/metube)                                          | youtube video downloader           | docker-compose | ✅ |
| [codimd](https://hackmd.io/c/codimd-documentation)                                    | notetaking tool                    | docker-compoes | ✅ |
| [gogs](https://gogs.io/)                                                              | git server                         | docker-compose | ✅ |
| [drawio](https://hub.docker.com/r/jgraph/drawio)                                      | architecture diagramming tool      | docker-compose | ✅ |
| [home-assistant](https://www.home-assistant.io/)                                      | home automation server             | docker-compose | ✅ |
| [node-red](https://nodered.org/)                                                      | programmable automation interface  | docker-compose | ✅ |
| [nanomq-server](https://github.com/emqx/nanomq)                                       | pub/sub for IoT (MQTT broker)      | docker-compose | ✅ |
| [node-exporter](https://github.com/prometheus/node_exporter)                          | linux metrics scraper              | docker-compose | ✅ |
| [prometheus](https://prometheus.io/)                                                  | timeseriesdb monitoring server     | docker-compose | ✅ |
| [loki-server](https://github.com/grafana/loki)                                        | logging server for grafana         | docker-compose | ✅ |
| [promtail-agent](https://grafana.com/docs/loki/latest/clients/promtail/installation/) | logging agent for loki             | docker-compose | ✅ |
| [grafana](https://github.com/grafana/grafana)                                         | monitoring dashboard               | docker-compose | ✅ |