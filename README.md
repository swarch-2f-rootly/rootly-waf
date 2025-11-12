# Rootly WAF

Servicio de **Web Application Firewall** basado en **Nginx + ModSecurity (OWASP CRS)** que protege el frontend SSR (`rootly-ssr-frontend`) y el API expuesto por el reverse proxy interno.

## Flujo

```
Browser (HTTPS) → rootly-waf → reverse-proxy → frontend / API Gateway
```

`rootly-waf` termina TLS, inspecciona las solicitudes con ModSecurity (Core Rule Set) y reenvía tráfico válido al reverse proxy interno existente (`rootly-deploy/nginx.conf`).

## Archivos relevantes

- `Dockerfile`: imagen basada en `owasp/modsecurity-crs:nginx` con un entrypoint que genera certificados autofirmados cuando no existen.
- `entrypoint.sh`: crea certificados de desarrollo en `/etc/nginx/certs` si no están presentes.
- `nginx.conf` y `conf.d/rootly.conf`: configuración de Nginx que habilita ModSecurity y define el upstream hacia `reverse-proxy`.
- `modsecurity/main.conf`: incluye ModSecurity base, OWASP CRS y reglas personalizadas.
- `modsecurity/custom-rules.conf`: espacio para reglas específicas del proyecto.

## Certificados TLS

En entornos de desarrollo no es necesario montar certificados: el contenedor genera uno autofirmado.  
Para producción, monta tus certificados en `/etc/nginx/certs/fullchain.pem` y `/etc/nginx/certs/privkey.pem`. Ejemplo en `docker-compose.yml`:

```yaml
  rootly-waf:
    volumes:
      - ./certs/fullchain.pem:/etc/nginx/certs/fullchain.pem:ro
      - ./certs/privkey.pem:/etc/nginx/certs/privkey.pem:ro
```

## Personalización de Reglas

Agrega reglas en `modsecurity/custom-rules.conf`. Por ejemplo, para bloquear un user-agent específico:

```apache
SecRule REQUEST_HEADERS:User-Agent "evil-bot" \
  "id:1000001,phase:1,deny,status:403,msg:'Blocked known bad bot'"
```

Recarga el contenedor después de cualquier cambio:

```bash
docker compose restart rootly-waf
```


