# StinoByte's Media Stack

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
mkdir -p downloads media logs config/jellyfin config/jellyseerr config/radarr config/sonarr config/prowlarr config/qbittorrent config/qbittorrent_cache config/bazarr
```

(Optional) Sets the correct ownership to the newly created folders, just to be sure.

```bash
sudo chown -R $(id -u):$(id -g) downloads media logs config
```

## 3. Generate the .env file

This will create the necessary .env file which the Docker containers will use.

```bash
printf 'PUID=%s\nPGID=%s\nTZ=%s\nBASE_DIR=${PWD}\n' \
       "$(id -u)" \
       "$(id -g)" \
       "$(timedatectl show --value --property=Timezone 2>/dev/null || echo Europe/London)" \
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
