# Media Stack

| Service      | Port | Description                                                 |
| ------------ | ---- | ----------------------------------------------------------- |
| Jellyfin     | 8096 | Media streaming server                                      |
| Jellyseerr   | 5055 | Jellyfin request manager                                    |
| Radarr       | 7878 | Movie manager                                               |
| Sonarr       | 8989 | TV Show manager                                             |
| Prowlarr     | 9696 | Indexer manager for Sonarr/Radarr                           |
| Bazarr       | 6767 | Subtitle manager                                            |
| Lingarr      | 9876 | Subtitle translator when no non-English subtitles are found |
| qBittorrent  | 8080 | Torrent client                                              |
| Flaresolverr | 8091 | Optional, to be able to use certain indexers in Prowlarr    |

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
mkdir -p downloads media/movies media/tv config/jellyfin config/jellyseerr config/radarr config/sonarr config/prowlarr config/qbittorrent config/qbittorrent_cache config/bazarr config/flaresolverr config/lingarr config/ollama
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

## 5. Configure the services

> [!NOTE]
> If you run the services on another device, change `localhost` in the addresses to your server ip address.

#### qBittorrent - http://localhost:8080

- Log in with user 'admin' and temporary password which can be found in the docker logs (execute `docker logs qbittorrent` in a terminal on the device the containers run on).
- Go to `Options > WebUI` and change the admin password. Optionally you can enable `Bypass authentication for clients on localhost` for your own convenience.
- Scroll down and click `Save`.
- Go to `Options > Downloads` and change Default Save Path to `/data/downloads` and click `Save`.

> [!TIP]
> For the Prowlarr-Sonarr-Radarr steps it might be easier to follow this YouTube guide along with the next steps: https://www.youtube.com/watch?v=3k_MwE0Z3CE&t=876s
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

(YT tutorial only goes to this point, follow the rest of this guide from here)

#### Bazarr - http://localhost:6767

- Follow the official guide, it is pretty straightforward. You can skip the `Port Mapping` steps for Sonarr and Radarr because the paths should be the same.<br>Guide: https://wiki.bazarr.media/Getting-Started/Setup-Guide/

> [!TIP]
> To find out which subtitle providers have a lot of content in your language, you can check https://wiki.bazarr.media/bazarr-stats/.

- After this, follow the First time installation configuration: https://wiki.bazarr.media/Getting-Started/First-time-installation-configuration/

#### Jellyfin - http://localhost:8096

- Follow setup wizard (guide: https://jellyfin.org/docs/general/post-install/setup-wizard/).
- Optional: Enable

#### Jellyseer - http://localhost:5055

- Configure for Jellyfin
- Enter Jellyfin url (http://jellyfin:8096) and enter email address, username and password.
- Sync libraries and do a Manual Library Scan.
- Add Radarr and Sonarr with API keys.

That should be it, you can select movies and shows in Jellyseer, the mediastack will do the rest! Once downloaded, you can watch with Jellyfin.

#### Ollama

> [!TIP]
> Ollama and Lingarr are optional for when subtitles are not found in your language, it uses a local LLM for translating the subtitles.
> If you do not want this, you can safely comment out or delete the Ollama and Lingarr services in the `docker-compose.yaml` file.

Install an LLM for subtitle translation. Example is for Dutch translation but you can find different models for different languages here: https://ollama.com/library

```bash
docker exec -it ollama ollama pull jobautomation/openeurollm-dutch:latest
```

#### Lingarr - http://localhost:9876

- Go to `Settings > Integrations` and set the API keys for Radarr and Sonarr.
- Go to `Settings > Services` and set the preferred AI model (same as the one you installed in the previous step), source and target languages.
- In `Settings > Automation` you can optionally enable automated translation, this will automatically translate subtitles that are not found once a day.

## 6. Updating and stopping the containers

To update the containers manually, execute in root folder of the project (where the docker-compose.yaml file is).

```bash
# 1. Update images
docker compose pull
# 2. Update containers
docker compose up -d --build
# 3. Remove old images of this container stack
docker image prune -f --filter "label=mediastack"
```

Or you can run the `update_containers.sh` script for a more automatic approach.

> [!TIP]
> If you run the `update_containers.sh` script through a cron job (for example weekly), you don't have to worry about updating yourself and always have the latest versions.<br>More info about cron jobs: https://www.geeksforgeeks.org/linux-unix/crontab-in-linux-with-examples/

To stop the containers:

```bash
docker compose down
```

## 7. Relocating the downloads and/or media folders

Because the use of the `.env` file created by following this guide, it is possible to put the `/downloads`, `/media/movies` and `/media/tv` folders in another location, even on another disk. This could come in handy if you run out of disk space.

Steps to do this:

1. Stop the containers with `docker compose down` from the root direcory of the project (where the `docker-compose.yaml` file is).
2. Move any of these folders to a new location.
3. Change the environment variables in the `.env` file with the **full path** of the new location. (e.g. `DOWNLOAD_DIR=<insert new full path here>` and/or `TV_DIR=<insert new full path here>` and/or `MOVIE_DIR=<insert new full path here>`).
4. Rebuild and start the containers again from the root directory of the project with `docker compose up -d --build`.

After doing this, **DO NOT regenerate the `.env` file** (step 3) because your changes will be overwritten and things will get messed up.
