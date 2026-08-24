# Reglas y Estructura del Proyecto RAPH

## Estructura de Repositorios / Directorios
- **Frontend (Flutter)**: `c:\Users\Administrador\Documents\RAPH` (Aplicación web/móvil Flutter).
- **Backend General (PHP/Yii2)**: `c:\xampp\htdocs\RAPH` (Proyecto servidor general).
- **Módulo de Backend Activo**: `c:\xampp\htdocs\RAPH\raph` (Módulo específico del backend donde residen `controllers/`, `models/`, `components/`, etc. para las modificaciones del backend).

## Módulo de Sockets y Despachos (Tiempo Real)
- **Servidor de Sockets**: Servidor Socket.IO preexistente (Configurado en `params.php` -> `socketServerUrl`, por defecto `https://emergenciasyriesgos.neuquen.gov.ar/giro`).
- **Servicio Emisor en PHP**: `c:\xampp\htdocs\RAPH\raph\components\services\SocketDespachoNotificador.php` (Emite HTTP POST a la URL de sockets configurada).
- **Eventos de Sockets emitidos**: `nuevo_despacho`, `despacho_actualizado`.
- **Filtro por Móvil / Salas**: La app de ambulancias/despachos se une a su canal emitiendo `join:movil` con `{ idmovil: id_movil }` para recibir únicamente las alertas dirigidas a su unidad (`movil_X`).


