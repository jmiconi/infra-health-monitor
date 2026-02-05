# Infra Health Monitor (DB + DFS)

## 📌 Descripción

**Infra Health Monitor** es un servicio de monitoreo liviano, implementado en **Bash + systemd**, orientado a verificar la salud básica de componentes críticos de infraestructura on-premise.

Actualmente monitorea:

- Conectividad TCP hacia **SQL Server**
- Conectividad TCP hacia **DFS / File Server (SMB 445)**

El proyecto está diseñado para ser:
- simple
- auditable
- fácil de extender
- seguro en el manejo de credenciales

---

## 🎯 Objetivos

- Proveer health checks confiables de infraestructura crítica
- Separar **lógica**, **configuración** y **secretos**
- Integrarse de forma nativa con `systemd` y `journalctl`
- Servir como proyecto de portfolio (Infra / SRE / DevOps)

---

## 🧱 Arquitectura

- **Lenguaje:** Bash
- **Ejecución:** systemd service
- **Logs:** stdout / stderr → journal
- **Configuración:** variables de entorno
- **Secretos:** archivo externo con permisos restrictivos
- **Frecuencia:** ejecución periódica (ej. cada 30s)

---

## 🔍 Qué se monitorea

### Base de datos (SQL Server)

- Conectividad TCP al host y puerto configurados
- Medición de latencia
- Umbrales configurables:
  - WARN
  - CRIT

> En esta etapa **no se ejecutan queries**.  
> El foco está en disponibilidad de red y servicio.

---

### DFS / File Server

- Conectividad TCP al puerto SMB (445)
- Chequeo opcional (puede deshabilitarse vía configuración)

---

## 🔐 Manejo de secretos

Las credenciales **NO se almacenan**:
- en el script
- en el unit file
- en el repositorio

Se utilizan archivos externos, por ejemplo:

/etc/infra-monitor/secrets.env


Permisos recomendados:

chmod 600 /etc/infra-monitor/secrets.env
chown root:svc_monitor /etc/infra-monitor/secrets.env


Permisos recomendados:

chmod 600 /etc/infra-monitor/secrets.env
chown root:svc_monitor /etc/infra-monitor/secrets.env


El archivo se carga desde systemd:
EnvironmentFile=/etc/infra-monitor/secrets.env

Cada entorno debe crear su propio archivo de secretos.


📁 Estructura del proyecto

infra-health-monitor/
├── monitor.sh
├── infra-health-monitor.service
├── README.md
├── .gitignore
└── examples/
    └── secrets.env.example

⚙️ Instalación básica

Copiar el script:
/opt/infra-monitor/monitor.sh

Crear usuario de servicio:
useradd -r -s /usr/sbin/nologin svc_monitor

Crear archivo de secretos:
/etc/infra-monitor/secrets.env

Instalar el unit file:
/etc/systemd/system/infra-health-monitor.service

Recargar systemd:
systemctl daemon-reload

Habilitar y arrancar:
systemctl enable infra-health-monitor
systemctl start infra-health-monitor


📊 Logs
journalctl -u infra-health-monitor.service


🚧 Estado del proyecto

✔️ Monitoreo TCP DB
✔️ Monitoreo TCP DFS
✔️ Separación de secretos
✔️ Integración con systemd
🔜 Queries reales a SQL Server
🔜 Escalado de estado (warnings acumulados → critical)
🔜 Integración con herramientas externas

🤝 Motivación

Proyecto desarrollado como:
Laboratorio técnico
Ejercicio de buenas prácticas de infraestructura
Pieza de portfolio profesional
