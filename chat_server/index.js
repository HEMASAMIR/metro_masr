require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json({ limit: '50mb' })); 

const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

app.get('/', (req, res) => {
  res.send('Rafiq Metro Real-Time Chat Server is Running!');
});

io.on('connection', (socket) => {
  console.log(`User connected: ${socket.id}`);

  socket.on('join_metro_room', (roomId) => {
    socket.join(roomId);
    console.log(`User ${socket.id} joined metro room: ${roomId}`);
  });

  socket.on('send_message', async (data) => {
    console.log('Received message:', data);
    
    const messageResponse = {
      id: Date.now().toString(),
      sender: data.sender,
      text: data.text || "مرفق صورة/مقطع",
      imageBase64: data.imageBase64,
      type: data.type,
      timestamp: new Date().toISOString(),
    };

    io.to(data.roomId).emit('receive_message', messageResponse);
  });

  socket.on('disconnect', () => {
    console.log(`User disconnected: ${socket.id}`);
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀 Rafiq Metro Chat Streaming Server running on port ${PORT}`);
});
