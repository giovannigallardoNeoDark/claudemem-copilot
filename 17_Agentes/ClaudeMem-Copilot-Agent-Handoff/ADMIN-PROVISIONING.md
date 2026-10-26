# Entrega a administrador: ClaudeMem Copilot

## Estado
Este paquete esta preparado y validado localmente, pero no ha sido provisionado porque la cuenta actual no tiene Copilot Access habilitado.

## Requisitos del administrador
- Tenant de prueba con Custom App Upload habilitado.
- Usuario con Copilot Access habilitado.
- Microsoft 365 Agents Toolkit 6.12.0 o posterior.
- Registro de clave API creado en Developer Portal.
- Endpoint MCP HTTPS activo y accesible.

## Preparacion
1. Copiar `config.example.json` como `config.local.json`.
2. Completar App ID, URL MCP y API key registration ID. No agregar la clave API.
3. Ejecutar `scripts\Configurar-Paquete-Agente.ps1 -Config .\config.local.json`.
4. Ejecutar `scripts\Validar-Paquete-Agente.ps1`.
5. Revisar `dist\appPackage`.
6. Provisionar con una cuenta autorizada desde Agents Toolkit o cargar el paquete generado, segun las politicas del tenant.

## Restricciones
- El MCP es solo lectura.
- La URL de Dev Tunnel es temporal y requiere que VS Code, el tunnel y Node.js permanezcan activos.
- Para produccion usar un endpoint estable y OAuth o Entra SSO.
