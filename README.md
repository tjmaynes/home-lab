<p align="center">
    <img src="./ansible/roles/geck/files/logo.webp" width="150"></a>
</p>

# Home Lab
> Ansible playbook for my K3s-based home lab.

## Requirements

- [GNU Make](https://www.gnu.org/software/make/)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/)
- [GNU Envsubst](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html)

## Usage
To deploy home lab, run the following command:
```bash
make deploy
```

To teardown home lab, run the following command:
```bash
make teardown
```

## Programs

| Program                                                                               | Usage                              | Status |
| :------------------------------------------------------------------------------------ | :--------------------------------: | :----: |
| [cloudflare-tunnel](https://github.com/cloudflare/cloudflared)                        | cloudflare tunnel client           | ✅ |
| [nginx-proxy-manager](https://nginxproxymanager.com/)                                 | reverse-proxy server               | ✅ |
| [homer](https://github.com/bastienwirtz/homer)                                        | start-page                         | ✅ |
| [cloudfared-agent](https://github.com/cloudflare/cloudflared)                         | cloudflare dns client for pihole   | ✅ |
| [plex-server](https://hub.docker.com/r/linuxserver/plex)                              | media server                       | ✅ |
| [calibre-web](https://github.com/janeczku/calibre-web)                                | web-based ebook-reader             | ✅ |
| [pigallary-web](https://bpatrik.github.io/pigallery2/)                                | photo gallery                      | ✅ |
| [audiobookshelf](https://www.audiobookshelf.org/)                                     | podcast & audiobooks server        | ✅ |
| [podgrab](https://github.com/akhilrex/podgrab)                                        | podcast downloader                 | ✅ |
| [metube](https://github.com/alexta69/metube)                                          | youtube video downloader           | ✅ |
| [gogs](https://gogs.io/)                                                              | git server                         | ✅ |
| [home-assistant](https://www.home-assistant.io/)                                      | home automation server             | ✅ |
| [node-red](https://nodered.org/)                                                      | programmable automation interface  | ✅ |
