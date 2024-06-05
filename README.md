# RTMP Server + HLS

## Integrantes
- Manuel Esteban Dithurbide - 62057
- Gonzalo Martín Elewaut - 61212
- Santiago Andrés Larroudé Alvarez - 60460
- Tobías Perry - 62064

## Introducción
Este proyecto consiste en configurar un servidor de streaming RTMP capaz de manejar transmisiones tanto de multimedia. Incluye la capacidad de grabar sesiones, gestionar múltiples fuentes simultáneas en vivo y diferidas, monitorear las conexiones de los clientes y el uso de ancho de banda. También abarca una integración con HLS, una interfaz web básica y un modulo de estadisticas HLS.

**IMPORTANTE**: Implementación especifica para Linux (Ubuntu 22.04)
## Instalar NGINX
En primer lugar descargar las dependencias necesarias.
#### Descarcar librerias necesarias
```bash
sudo apt update
sudo apt install build-essential libpcre3 libpcre3-dev libssl-dev zlib1g-dev unzip
```

#### Descargar Nginx y el módulo RTMP
```bash
cd /usr/local/src
sudo wget http://nginx.org/download/nginx-1.22.0.tar.gz
sudo tar -zxvf nginx-1.22.0.tar.gz
sudo wget https://github.com/arut/nginx-rtmp-module/archive/master.zip
sudo unzip master.zip
```

#### Build NGINX 
```bash
cd nginx-1.22.0
sudo ./configure --with-http_ssl_module --add-module=../nginx-rtmp-module-master
sudo make
sudo make install
```

## Configurar RTMP
La primera configuración de NGINX sera un servidor de streaming con solo el módulo RTMP.
1. Localizar y Modificar el archivo ```nginx.conf``` en la carpeta ```/usr/local/nginx/conf```

```bash
sudo nano /usr/local/nginx/conf/nginx.conf
```
Agregar el módulo RTMP arriba del módulo HTTP
```bash
rtmp {
    server {
        listen 1935;
        chunk_size 4096;

        application live {
            live on;
            record off;
        }
    }
}
```

#### Iniciar servidor RTMP
Para iniciar el servidor, tienes que ejecutar el siguiente comando:
```bash
sudo /usr/local/nginx/sbin/nginx
```
Para reiniciar o apagar el servidor:
```bash
sudo /usr/local/nginx/sbin/nginx -s reload
sudo /usr/local/nginx/sbin/nginx -s stop
```
Una vez iniciado el servidor ya se puede realizar un primer stream!

Nota: Debes saber la IP del servidor
```bash
ip addr
```

#### Realizar un stream
Utilizando un cliente de tramision RTMP (Ej: OBS) configurar el stream:
- Host: ```rtmp://{host}/live``` (IP del servidor)
- Stream key: ```nombre_stream```

#### Visualizar stream
Con algún cliente de visualizacion RTMP (Ej: VLC) visualiza el stream en la siguiente dirección:
```rtmp://{host}/live/{nombre_stream}```

## Configurar grabacion
En esta sección se configura la opción de grabación en el servidor:

1. Modificar el módulo RTMP en ```nginx.conf``` 
```bash
sudo nano /usr/local/nginx/conf/nginx.conf
```

Cambiar el usuario
```bash
user = www-data;
```

Agregar en el módulo RTMP la configuración de grabación. El módulo queda con la siguiente configuración:
```bash
rtmp {
    server {
        listen 1935;
        chunk_size 4096;

        application live {
            live on;
            #record off;
            #Codigo a nuevo
            record all;
            record_path /var/rec;
            record_unique on;
        }
    }
}
```

2. Configuración de permisos en la carpeta ```/var/rec```
```bash
sudo mkdir /var/rec
sudo chown -R www-data:www-data /var/rec 
sudo chmod -R 755 /var/rec
```

3. Reiniciar el servidor
```bash
sudo /usr/local/nginx/sbin/nginx -s reload
```
4. Realizar un stream y al finalizar ver el archivo de grabación en la carpeta ```/var/rec```


## Configurar estadisticas RTMP
1. Configurar el módulo HTML en ```nginx.conf```
```bash
sudo nano /usr/local/nginx/conf/nginx.conf
```
Reemplazar el módulo HTTP con lo siguiente:

```bash
http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;

    keepalive_timeout  65;

    server {
        listen       80;
        server_name  localhost;

        location / {
            root   html;
            index  index.html index.htm;
        }

        location /stats {
            rtmp_stat all;
            rtmp_stat_stylesheet stat.xsl;
        }

        location /stat.xsl {
            root /usr/local/nginx/html;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

    }
}
```

2. Crear el archivo ```stats.xsl``` en ```/usr/local/nginx/html``` con el siguiente contenido
```bash
sudo nano /usr/local/nginx/html/stat.xsl
```
```xml
<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html" indent="yes" />

    <xsl:template match="/">
        <html>
            <head>
                <title>RTMP Server Stats</title>
                <style>
                    body { font-family: Arial, sans-serif; padding: 50px}
                    table { width: 100%; border-collapse: collapse; }
                    th, td { padding: 8px; border: 1px solid #ddd; }
                    th { background-color: #f2f2f2; }
                    .header { font-size: 24px; margin-bottom: 20px; }
                </style>
            </head>
            <body>
                <div class="header">RTMP Server Stats</div>
                <table>
                    <tr>
                        <th>Live Streams</th>
                        <th>Clients</th>
                        <th>Bandwidth IN</th>
                        <th>Bandwidth OUT</th>
                    </tr>
                    <xsl:for-each select="rtmp/server/application">
                        <tr>
                            <td>
                                <xsl:for-each select="live/stream">
                                    <div><xsl:value-of select="name" /></div>
                                </xsl:for-each>
                            </td>
                            <td>
                                <xsl:value-of select="nclients" />
                                <xsl:text> (</xsl:text>
                                <xsl:value-of select="live/nclients" />
                                <xsl:text> live)</xsl:text>
                            </td>
                            <td>
                                <xsl:for-each select="live/stream">
                                    <div>
                                        <xsl:value-of select="bw_in" />
                                    </div>
                                </xsl:for-each>
                            </td>
                            <td>
                                <xsl:for-each select="live/stream">
                                    <div>
                                        <xsl:value-of select="bw_out" />
                                    </div>
                                </xsl:for-each>
                            </td>
                        </tr>
                    </xsl:for-each>
                </table>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
```

3. Reiniciar el servidor, iniciar un stream y ver las estadísticas
```bash
sudo /usr/local/nginx/sbin/nginx -s reload
curl localhost/stats
```

También se pueden visualizar en un buscador web en ```http://{host}/stats```

## Interfaz Web + HLS
#### 1. Configurar protocolo HLS
Para poder visualizar el stream en un buscador moderno, se debe configurar HLS (Http Live Stream) ya que RTMP es solo soportado por FLASH (Descontinuado el 31/12/2020).

Agregar HLS en ```nginx.conf```
```bash
sudo nano /usr/local/nginx/conf/nginx.conf
```
Configurar el módulo RTMP de la siguiente manera:
```bash
rtmp {
    server {
        listen 1935;
        chunk_size 4096;

        application live {
            live on;
            record all;
            record_path /var/rec;
            record_unique on;

            # Codigo Nuevo
            hls on;
            hls_path /tmp/hls;
            hls_fragment 3;
            hls_playlist_length 30s;
        }
    }
}
```

Crear la carpeta ```/tmp/hls``` y ajustar los permisos.
```bash
sudo mkdir /tmp/hls
sudo chown -R www-data:www-data /tmp/hls 
sudo chmod -R 755 /tmp/hls
```

#### 2. Configurar enpoints HTTP
Para servir los fragmentos HLS y las grabaciones debemos configurar los siguientes enpoints en ```nginx.conf```
```bash
sudo nano /usr/local/nginx/conf/nginx.conf
```
Agregar los siguientes endpoint al modulo HTTP:
```bash
http{
    #...
    
    server{
        #...
    
        #Enpoint para servir fragmentos HLS
        location /hls {
            types {
                application/vnd.apple.mpegurl m3u8;
                video/mp2t ts;
            }
            alias /tmp/hls;
            add_header Cache-Control no-cache;
        }

        #Endpoints para conseguir las grabaciones
        location ~ ^/getRecordings/?$ {
            alias /var/rec/;
            autoindex on;
            autoindex_format json;
        }

        location /getRecordings/ {
            alias /var/rec/;
            try_files $uri =404;
        }
        
        #...
    }

}

```

#### 3. Paginas HTML
Finalmente configuramos las paginas htm. En la carpeta ```/usr/local/nginx/html``` crear los siguientes archivos con el contenido correspondiente:

-  ```index.html```: [contenido de index.html](index.html)
-  ```view.html```: [contenido de view.html](view.html)
-  ```joinStream.html```: [contenido de joinStream.html](joinStream.html)

## Estadisticas HLS

1. En el archivo ```nginx.conf``` agregar los logs personalizados para el enpoint HLS:

```bash
http {
    #...

    log_format hls_log '$remote_addr - $remote_user [$time_local] "$request" '
                       '$status $body_bytes_sent "$http_referer" '
                       '"$http_user_agent" "$http_x_forwarded_for" '
                       '$request_time $body_bytes_sent $upstream_cache_status';

    server {

        #...

        location /hls {
            #...
            access_log /usr/local/nginx/logs/hls.log hls_log;
        }

        #...

    }
}
```

2. Crear el archivo ```/usr/local/nginx/logs/hls.log``` y ajustar los permisos
```bash
sudo touch /usr/local/nginx/logs/hls.log
sudo chmod 555 /usr/local/nginx/logs/hls.log
```

3. Crear el archivo para analizar los logs en el lugar que desees. Por ejemplo ```/usr/local/nginx/logs/analyze.sh``` con el siguiente contenido:
```bash
#!/bin/bash

# Default log file location
LOG_FILE="/usr/local/nginx/logs/hls.log"

# Check if the time frame in seconds is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <time_frame_in_seconds>"
    exit 1
fi

TIME_FRAME=$1

# Calculate the start and end times based on the current time and the provided time frame
END_TIME=$(date "+%d/%b/%Y:%H:%M:%S")
START_TIME=$(date -d "-$TIME_FRAME seconds" "+%d/%b/%Y:%H:%M:%S")

# Extract relevant log entries within the specified time frame and ignore .m3u8 files
LOG_ENTRIES=$(awk -v start="$START_TIME" -v end="$END_TIME" '{
    time=$4
    gsub(/[\[\]]/, "", time)
    if (time >= start && time <= end && $7 !~ /\.m3u8$/) print $0
}' "$LOG_FILE")

# Check if LOG_ENTRIES is empty
if [ -z "$LOG_ENTRIES" ]; then
    echo "No log entries found in the specified time frame."
    exit 0
fi

# Process log entries to aggregate data by stream
process_log_entries() {
    local log_entries=$1

    # Declare associative arrays
    declare -A viewers
    declare -A bytes_sent

    while IFS= read -r entry; do
        # Extract stream name and IP address
        stream=$(echo "$entry" | grep -oP '/hls/\K[^-]*')
        ip=$(echo "$entry" | awk '{print $1}')
        bytes=$(echo "$entry" | awk '{print $10}')

        # Aggregate unique viewers by IP
        viewers["$stream,$ip"]=1

        # Aggregate bytes sent
        bytes_sent["$stream"]=$((bytes_sent["$stream"] + bytes))
    done <<< "$log_entries"

    # Aggregate unique viewers per stream
    declare -A unique_viewers_per_stream
    for key in "${!viewers[@]}"; do
        stream=$(echo "$key" | awk -F',' '{print $1}')
        unique_viewers_per_stream["$stream"]=$((unique_viewers_per_stream["$stream"] + 1))
    done

    for stream in "${!unique_viewers_per_stream[@]}"; do
        unique_viewers=${unique_viewers_per_stream["$stream"]}
        total_bytes=${bytes_sent["$stream"]}
        echo "Stream: $stream"
        echo "Unique Viewers: $unique_viewers"
        echo "Bytes Sent: $total_bytes"
        echo "-------------------------"
    done
}

process_log_entries "$LOG_ENTRIES"
```

4. Otorgar permisos de ejecucion y ejecutar para visualizar estadisticas HLS:
```bash
sudo chmod +x /usr/local/nginx/logs/analyze.sh
sudo ./usr/local/nginx/logs/analyze.sh
```

## Resumen
Los archivos finalmente deberian quedar de la siguiente manera.

Configuracion NGINX:
- ```nginx.conf```: [contenido de nginx.conf](nginx.conf)

Pantallas:
- ```stat.xsl```: [contenido de stat.xsl](stat.xsl)
-  ```index.html```: [contenido de index.html](index.html)
-  ```view.html```: [contenido de view.html](view.html)
-  ```joinStream.html```: [contenido de joinStream.html](joinStream.html)

Estadisticas HLS:
- ```analyze.sh```: [contenido de analyze.sh](analyze.sh)
