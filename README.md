# StinoByte's Media Stack

| Service      | Port | Description                                              |
| ------------ | ---- | -------------------------------------------------------- |
| Jellyfin     | 8096 | Media streaming server                                   |
| Jellyseerr   | 5055 | Jellyfin request manager                                 |
| Radarr       | 7878 | Movie manager                                            |
| Sonarr       | 8989 | TV Show manager                                          |
| Prowlarr     | 9696 | Indexer manager for Sonarr/Radarr                        |
| Bazarr       | 6767 | Subtitle manager                                         |
| qBittorrent  | 8080 | Torrent client                                           |
| Flaresolverr | 8091 | Optional, to be able to use certain indexers in Prowlarr |

## 1. Clone repository

```bash
git clone https://github.com/StinoBytes/mediastack.git
```

And move to the cloned directory:

```bash
cd mediastack
```

## 2. Create folder structure & set ownership

Creates the necessary folder structure for the project:

```bash
mkdir -p downloads media/movies media/tv config/jellyfin config/jellyseerr config/radarr config/sonarr config/prowlarr config/qbittorrent config/qbittorrent_cache config/bazarr config/flaresolverr
```

(Optional) Sets the correct ownership to the newly created folders, just to be sure.

```bash
sudo chown -R $(id -u):$(id -g) downloads media config
```

## 3. Generate the .env file

This will create the necessary .env file which the Docker containers will use.

```bash
printf 'PUID=%s\nPGID=%s\nTZ=%s\nCONFIG_DIR=${PWD}/config\nDOWNLOAD_DIR=${PWD}/downloads\nTV_DIR=${PWD}/media/tv\nMOVIE_DIR=${PWD}/media/movies\nSERVER_URL=http://%s\n' \
       "$(id -u)" \
       "$(id -g)" \
       "$(timedatectl show --value --property=Timezone 2>/dev/null || echo Europe/London)" \
       "$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}' || hostname -I | awk '{print $1}')" \
       > .env
```

## 4. Run the containers

This will download the Docker Images and spin up the containers.

```bash
docker compose up -d
```

To stop the containers:

```bash
docker compose down
```

## 5. Configure the services

> [!NOTE]
> If you run the services on another device, change `localhost` in the addresses to the server ip address.

#### qBittorrent - http://localhost:8080

- Log in with user 'admin' and temporary password which can be found in the docker logs (`docker logs qbittorrent`).
- Go to `Options > WebUI` and change the admin password. Optionally you can enable `Bypass authentication for clients on localhost` for your own convenience.
- Scroll down and click `Save`.
- Go to `Options > Downloads` and change Default Save Path to `/data/downloads` and click `Save`.

> [!TIP]
> From this point on it might be easier to follow this YouTube guide: https://www.youtube.com/watch?v=3k_MwE0Z3CE&t=876s together with the steps below.
>
> The guide uses slightly different ports and URL's but you should keep the ones mentioned in the steps below. Also skip the Lidarr and Backup parts (might be added later in this stack but for now it won't).

#### Prowlarr - http://localhost:9696

- Create login.
- Add qBittorrent under `Settings > Download Clients`. Change host to `qbittorrent`, use `admin` username and password created in the previous step.
- Add Flaresolverr under `Settings > Indexers`, with tag `flaresolverr` and host address `http://flaresolverr:8191/`.
- Add your favorite indexers under `Indexers`. If any are blocked by CloudFlare Protection, add the tag `flaresolverr` to this indexer.

#### Sonarr - http://localhost:8989

- Create login.
- Add qBittorrent, same as Prowlarr.
- In `Settings > Download Clients`, add `Remote Path Mappings` for your `downloads` folder. `Host` is `qbittorrent`, set `Remote Path` and `Local Path` to `/data/downloads/`.
- Go to `Settings > General` and copy the API key. Go back to Prowlarr and in `Settings > Apps`, add the Sonarr application and paste the API key. Change Prowlarr Server to `http://prowlarr:9696` and Sonarr Server to `http://sonarr:8989`. Test and save.
- Go to `Series > Library Import > Start Import` and add `/data/tvshows/`.
- In `Settings > Quality` set your preferred quality definitions.

#### Radarr - http://localhost:7878

- Repeat steps for Sonarr but alter mentions of `sonarr` to `radarr` and `tvshows` to `movies`.

#### Prowlarr (again) - http://localhost:9696

- Go to `Indexers` and click `Sync App Indexers`.
- For every indexer, go to settings, show advanced options and set your preferred setings for `Apps Minimum Seeders`, `Seed Ratio` and `Seed Time`, to for example 8, 1, 1.

(YT tutorial only goes to this point, follow the guide from here.)
