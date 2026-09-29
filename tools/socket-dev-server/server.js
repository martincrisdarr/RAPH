/**
 * Servidor local Socket.IO para desarrollo en RAPH
 * Simula el comportamiento del servidor de sockets en produccion
 * Permite probar colaboracion en tiempo real (Descripcion, Victimas y Novedades)
 */

const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
  path: '/socket.io',
  transports: ['polling', 'websocket'],
});

const PORT = process.env.PORT || 3001;

// Estado en memoria de campos bloqueados por sala
// Estructura: { [roomName]: { [fieldId]: { id: socketId, nombre: userName } } }
const roomLocks = {};

// Parseo basico de datos de usuario desde el token o query (si viene JWT decodificable)
function extractUserData(socket) {
  const token = socket.handshake.auth?.token || socket.handshake.query?.token;
  let nombre = 'Usuario ' + socket.id.substring(0, 4);

  if (token && typeof token === 'string' && token.includes('.')) {
    try {
      const parts = token.split('.');
      if (parts.length === 3) {
        const payload = JSON.parse(Buffer.from(parts[1], 'base64').toString('utf-8'));
        if (payload.nombre || payload.name || payload.user) {
          nombre = payload.nombre || payload.name || payload.user;
        }
      }
    } catch (e) {
      // Usar nombre por defecto
    }
  }

  return { id: socket.id, nombre };
}

io.on('connection', (socket) => {
  const user = extractUserData(socket);
  socket.userName = user.nombre;
  console.log(`[Socket.IO] Cliente conectado: ${socket.id} (${socket.userName})`);

  let currentRoom = null;

  // 1. Unirse a un registro (ej: incidente_123)
  socket.on('record:join', (data) => {
    if (!data || !data.entidad || data.id === undefined) return;

    const newRoom = `${data.entidad}_${data.id}`;

    // Si ya estaba en otra sala de registro, salir de ella
    if (currentRoom && currentRoom !== newRoom) {
      socket.leave(currentRoom);
      console.log(`[Socket.IO] Socket ${socket.id} salio de sala: ${currentRoom}`);
    }

    currentRoom = newRoom;
    socket.join(newRoom);
    console.log(`[Socket.IO] Socket ${socket.id} (${socket.userName}) se unio a sala: ${newRoom}`);

    // Inicializar estado de locks si no existe
    if (!roomLocks[newRoom]) {
      roomLocks[newRoom] = {};
    }

    // Sincronizar estado actual al cliente (Late Joiner)
    socket.emit('record:sync', roomLocks[newRoom]);
  });

  // 2. Bloquear campo colaborativo
  socket.on('field:lock', (data) => {
    if (!currentRoom || !data || !data.field) return;
    const field = data.field;

    if (!roomLocks[currentRoom]) roomLocks[currentRoom] = {};
    roomLocks[currentRoom][field] = { id: socket.id, nombre: socket.userName };

    console.log(`[Socket.IO] Campo bloqueado: "${field}" en ${currentRoom} por ${socket.userName}`);

    // Notificar a los demas en la sala
    socket.to(currentRoom).emit('field:locked', {
      field,
      lockedBy: { id: socket.id, nombre: socket.userName },
    });
  });

  // 3. Desbloquear campo colaborativo
  socket.on('field:unlock', (data) => {
    if (!currentRoom || !data || !data.field) return;
    const field = data.field;

    if (roomLocks[currentRoom] && roomLocks[currentRoom][field]) {
      delete roomLocks[currentRoom][field];
    }

    console.log(`[Socket.IO] Campo desbloqueado: "${field}" en ${currentRoom}`);

    // Notificar a los demas en la sala
    socket.to(currentRoom).emit('field:unlocked', { field });
  });

  // 4. Actualizar campo colaborativo (texto, accion o novedad)
  socket.on('field:update', (data) => {
    if (!currentRoom || !data || data.field === undefined) return;
    const { field, value } = data;

    console.log(`[Socket.IO] field:update en ${currentRoom} -> field: "${field}"`);

    // Retransmitir a los otros clientes de la misma sala
    socket.to(currentRoom).emit('field:updated', { field, value });
  });

  // 5. Desconexion
  socket.on('disconnect', () => {
    console.log(`[Socket.IO] Cliente desconectado: ${socket.id} (${socket.userName})`);

    if (currentRoom && roomLocks[currentRoom]) {
      // Liberar cualquier campo que este socket tuviera bloqueado
      Object.keys(roomLocks[currentRoom]).forEach((field) => {
        if (roomLocks[currentRoom][field].id === socket.id) {
          delete roomLocks[currentRoom][field];
          socket.to(currentRoom).emit('field:unlocked', { field });
          console.log(`[Socket.IO] Liberado bloqueo huerfano: ${field} en ${currentRoom}`);
        }
      });
    }
  });
});

// Endpoint HTTP compatible con el backend /api/emit (para futuras emisiones del backend PHP si se desea)
app.post('/api/emit', (req, res) => {
  const { event, targetRoom, data } = req.body;
  console.log(`[HTTP /api/emit] Evento: ${event}, targetRoom: ${targetRoom}`);

  if (targetRoom) {
    io.to(targetRoom).emit(event, data);
  } else {
    io.emit(event, data);
  }

  res.json({ success: true, message: 'Evento emitido exitosamente' });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', time: new Date().toISOString() });
});

server.listen(PORT, () => {
  console.log(`====================================================`);
  console.log(` Servidor local Socket.IO RAPH activo en puerto ${PORT}`);
  console.log(` URL: http://localhost:${PORT}`);
  console.log(` Path: /socket.io`);
  console.log(`====================================================`);
});
