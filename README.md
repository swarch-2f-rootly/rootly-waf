# Rootly WAF

Servicio unificado de **Web Application Firewall y Reverse Proxy** basado en **Nginx + ModSecurity (OWASP CRS)** que protege y enruta el tráfico hacia el frontend SSR (`rootly-ssr-frontend`) y el API Gateway.

## Flujo

```
Browser (HTTPS) → rootly-waf → frontend-ssr / api-gateway
```

`rootly-waf` es el único punto de entrada público al sistema. Termina TLS, inspecciona las solicitudes con ModSecurity (Core Rule Set), aplica rate limiting, y enruta el tráfico válido directamente al frontend SSR y al API Gateway que están en la red privada.

## Archivos relevantes

- `Dockerfile`: imagen basada en `owasp/modsecurity-crs:nginx` con un entrypoint que genera certificados autofirmados cuando no existen.
- `entrypoint.sh`: crea certificados de desarrollo en `/etc/nginx/certs` si no están presentes.
- `nginx.conf` y `conf.d/rootly.conf`: configuración de Nginx que habilita ModSecurity, define rate limiting y enruta el tráfico a `frontend-ssr` y `api-gateway`.
- `modsecurity/main.conf`: incluye ModSecurity base, OWASP CRS y reglas personalizadas.
- `modsecurity/custom-rules.conf`: espacio para reglas específicas del proyecto.

## Funcionalidades

### Protección con ModSecurity
- **OWASP Core Rule Set (CRS)**: Protección contra vulnerabilidades web comunes (SQLi, XSS, etc.)
- **Reglas personalizadas**: Lógica de seguridad específica del proyecto
- **Inspección de tráfico**: Todo el tráfico HTTP/HTTPS es inspeccionado antes de llegar a los servicios

### Rate Limiting
- **Endpoints de sensores**: 10 req/s con burst de 15
- **Endpoints de dispositivos**: 8 req/s con burst de 12
- **Endpoints de plantas**: 8 req/s con burst de 20
- **API general**: 50 req/s con burst de 100

### Enrutamiento
- `/api/v1/*`: Tráfico al API Gateway
- `/graphql`: GraphQL endpoint en API Gateway
- `/api/*`: Tráfico al Frontend SSR (API routes de Next.js)
- `/`: Frontend SSR (páginas y assets estáticos)

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



