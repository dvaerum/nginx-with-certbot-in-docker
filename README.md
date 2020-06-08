# Nginx with Certbot in Docker
This docker container is based on the last LTS of Ubuntu server. It is make as a service for handling the creation, renewal and removed of TLS certificates simply by listing the domains. It also setup Nginx and allow you to use it as a web-server or a reverse proxy. Finally HTTP request are automated redirected to HTTPS (http2https).

## Optional configuration variables
### DOMAINS
List the domains that you need a certificate for. If you have more then one domain you can seperate them with a comma (,) as showen in the example.
```
DOMAINS=example.com,www.example.com
```

### EMAIL
It is **requmented** to set the specify and email there Let's Encrypt can notify you if the certificate isn't getting renewed. Hopefully you should never encounter this problem because that means that I probably failed.
```
EMAIL=notify_me@example.com
```

### NGINX_LOG_ACCESS
```
NGINX_LOG_ACCESS=N
```

### NGINX_LOG_ERROR
```
NGINX_LOG_ERROR=Y
```

### RENEW_INTERVAL
Set the internal for how offen the certificate should be checked for renewel (default is `1d`)
```
RENEW_INTERVAL=1d
```
Note: Using the sleep command, so check `man sleep` for accepted values

### TEST
Set the variable to anything to enabled the used of LetsEncrypt's stating/testing environment.
https://letsencrypt.org/docs/staging-environment/
```
TEST=1
```

### DEBUG
Enable the debugging flag `--debug` for acme.sh
```
DEBUG=1
```

### DEBUG_BASH
Set the variable to anything to enabled the flag `-x (Print commands and their arguments as they are executed)` in the `/entrypoint.sh`.
```
DEBUG_BASH=1
```

### CLI_TOOL (experimentle)
Pick between usung `certbot` or `acme.sh` (default is `certbot`)
```
CLI_TOOL=certbot
```

### ACME_METHOD (experimentle)
Pick between usung `http` or `dns-FOLLOW_BY_PLUGIN` (default is `http`)
List of plugins for...
- certbot - https://certbot.eff.org/docs/using.html#dns-plugins
- acme.sh - https://github.com/acmesh-official/acme.sh/wiki/dnsapi
```
ACME_METHOD=http
```

## Optional PLUGIN configuration variables
### STRICT_TRANSPORT_SECURITY
If not configured `max-age=15768000; includeSubdomains; preload` is the default
```
STRICT_TRANSPORT_SECURITY=max-age=15768000; includeSubdomains; preload
```

### X_CONTENT_TYPE_OPTIONS
If not configured `nosniff` is the default
```
X_CONTENT_TYPE_OPTIONS=nosniff
```

### X_FRAME_OPTIONS
If not configured `DENY` is the default
```
X_FRAME_OPTIONS=SAMEORIGIN
```

### PLUGIN_SSL_DISABLE_HEADER
If not configured `Strict-Transport-Security`, `X-Content-Type-Options` and `X-Frame-Options` is enabled by default
```
PLUGIN_SSL_DISABLE_HEADER=Strict-Transport-Security X-Content-Type-Options X-Frame-Options
```

## Mounting Point
The mountpoint supported by this container

### /etc/nginx/sites-available
All websites you to want to setup should be put in this folder, one file per site.
```
./sites-available:/etc/nginx/sites-available:ro
```
The site template should looks something like this.  
**NOTES:**  
- Don't use `listen 80` because it will break the http2https redirection and HTTP Challenge setup.
- Replace `your.full.domain.name` with your actually domain.
```
server {
    listen 443 ssl http2;
    
    ssl_certificate         /etc/letsencrypt/live/your.full.domain.name/fullchain.pem;
    ssl_certificate_key     /etc/letsencrypt/live/your.full.domain.name/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/your.full.domain.name/chain.pem;
    include /etc/nginx/snippets/ssl.conf;
    
    # Set your dedicated domain
    server_name your.full.domain.name;


    #####################################################
    ### Here you add your configs for the website ... ###
    #####################################################
}
```


### /etc/letsencrypt
All the Let's Encrypt certificates are stored at this location
```
./letsencrypt:/etc/letsencrypt
```
