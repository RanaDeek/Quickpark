require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
// In-memory queue for ESP commands
typeof global.pendingCommands === 'undefined' && (global.pendingCommands = []);
const pendingCommands = global.pendingCommands;


const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors()); // allows any origin

app.use(express.json());

// MongoDB Connection
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('✅ Connected to MongoDB Atlas'))
.catch(err => console.error('❌ MongoDB Error:', err));

// Schemas & Models

const userSchema = new mongoose.Schema({
  fullName: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  userName: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  wallet: {
    balance: { type: Number, default: 0 },
    lastUpdated: { type: Date, default: Date.now },
  },
});

const User = mongoose.model('User', userSchema);



const chargeLogSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  amount: { type: Number, required: true },
  ownerNumber: { type: String, required: true },  // change this to String
  timestamp: { type: Date, default: Date.now },
  note: String,
});

const ChargeLog = mongoose.model('ChargeLog', chargeLogSchema);

const paymentSchema = new mongoose.Schema({
  userName: String,
  amount: Number,
  description: String,
  date: { type: Date, default: Date.now }
});

const Payment = mongoose.model('Payment', paymentSchema);

const slotSchema = new mongoose.Schema({
  slotNumber: { type: Number, required: true, unique: true },
  status: { type: String, enum: ['available', 'reserved', 'occupied'], default: 'available' },
  userName: { type: String, default: null },
  lastUpdated: { type: Date, default: Date.now },
  lockedBy: { type: String, default: null },
  lockExpiresAt: { type: Date, default: null },
  occupiedSince: { type: Date, default: null },
  timeStayed: { type: Number, default: 0 },
});


const Slot = mongoose.model('Slot', slotSchema);
const cron = require('node-cron');

// Run every minute to release expired locks
cron.schedule('* * * * *', async () => {
  const now = new Date();
  await Slot.updateMany(
    { lockExpiresAt: { $lt: now } },
    { $set: { lockedBy: null, lockExpiresAt: null } }
  );
  console.log('⏳ Expired slot locks released.');
});

// Utility function to send OTP email
async function sendOTPEmail(email, otp) {
  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASSWORD,
    },
  });

  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: email,
    subject: 'Your OTP Code for Password Reset',
    text: `Your OTP code is: ${otp}`,
  };

  await transporter.sendMail(mailOptions);
}
// Request OTP for password reset
app.post('/api/request-otp', async (req, res) => {
  const { email } = req.body;
  const user = await User.findOne({ email });
  if (!user) return res.status(404).json({ message: 'User not found.' });

  const otp = Math.floor(100000 + Math.random() * 900000).toString();

  const otpToken = jwt.sign(
    { email, otp },
    process.env.JWT_SECRET,
    { expiresIn: '10m' }
  );

  await sendOTPEmail(email, otp);

  res.status(200).json({
    message: 'OTP sent to your email.',
    otpToken,
  });
});
// Verify OTP
app.post('/api/verify-otp', (req, res) => {
  const { otpToken, otp } = req.body;

  try {
    const decoded = jwt.verify(otpToken, process.env.JWT_SECRET);
    if (decoded.otp !== otp) return res.status(400).json({ message: 'Invalid OTP.' });

    res.status(200).json({
      message: 'OTP verified successfully.',
      email: decoded.email,
      verifiedToken: jwt.sign({ email: decoded.email }, process.env.JWT_SECRET, { expiresIn: '10m' }),
    });
  } catch (error) {
    res.status(400).json({ message: 'Invalid or expired token.' });
  }
});
// Reset password after OTP verified
app.post('/api/reset-password', async (req, res) => {
  const { otpToken, newPassword } = req.body;

  try {
    const decoded = jwt.verify(otpToken, process.env.JWT_SECRET);
    const email = decoded.email;

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    const updateResult = await User.updateOne({ email }, { password: hashedPassword });

    if (updateResult.modifiedCount === 0) {
      return res.status(400).json({ message: 'Failed to update password.' });
    }

    res.status(200).json({ message: 'Password has been reset successfully.' });
  } catch (error) {
    res.status(500).json({ message: 'Failed to reset password.' });
  }
});
// User registration
app.post('/api/users', async (req, res) => {
  const { fullName, email, userName, password } = req.body;

  try {
    if (await User.findOne({ email })) return res.status(400).json({ message: 'Email already in use.' });
    if (await User.findOne({ userName })) return res.status(400).json({ message: 'Username already taken.' });

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = new User({
      fullName,
      email,
      userName,
      password: hashedPassword,
      wallet: { balance: 0, lastUpdated: new Date() },
    });

    await newUser.save();

    res.status(201).json({ message: 'User created successfully.' });
  } catch (error) {
    res.status(500).json({ message: 'Server error.' });
  }
});
// User login
app.post('/api/login', async (req, res) => {
  const { userName, password } = req.body;

  try {
    if (!userName || !password) return res.status(400).json({ message: 'Username and password are required.' });

    const user = await User.findOne({ userName });
    if (!user) return res.status(401).json({ message: 'Invalid credentials.' });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ message: 'Invalid credentials.' });

    res.status(200).json({
      message: 'Login successful.',
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        userName: user.userName,
      },
    });
  } catch {
    res.status(500).json({ message: 'Server error.' });
  }
});
// Get user by username (no password)
app.get('/api/users/username/:userName', async (req, res) => {
  try {
    const user = await User.findOne({ userName: req.params.userName }).select('-password');
    if (!user) return res.status(404).json({ message: 'User not found.' });

    res.status(200).json(user);
  } catch {
    res.status(500).json({ message: 'Server error.' });
  }
});
// Update user by username
app.put('/api/users/update/username/:userName', async (req, res) => {
  const { fullName, email } = req.body;

  if (!fullName || !email) return res.status(400).json({ message: 'Full Name and Email are required.' });

  try {
    const user = await User.findOne({ userName: req.params.userName });
    if (!user) return res.status(404).json({ message: 'User not found.' });

    user.fullName = fullName;
    user.email = email;
    await user.save();

    res.status(200).json({ message: 'User updated successfully', user });
  } catch {
    res.status(500).json({ message: 'Server error.' });
  }
});
// Haversine formula for distance calculation
function haversine(lat1, lon1, lat2, lon2) {
  const toRad = (x) => (x * Math.PI) / 180;

  const R = 6371; // km
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a = Math.sin(dLat/2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon/2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}
// Check distance to fixed parking coordinates
app.post('/check-distance', (req, res) => {
  const { lat, lon } = req.body;

  if (typeof lat !== 'number' || typeof lon !== 'number') {
    return res.status(400).json({ error: 'Invalid or missing lat/lon values' });
  }

  const parkingLat = 31.963158;
  const parkingLon = 35.930359;

  const distance = haversine(lat, lon, parkingLat, parkingLon);
  const maxDistance = 0.1; // km = 100 meters

  res.json({ allowed: distance <= maxDistance });
});
// Charge user wallet and log the charge
app.post('/api/charge-user', async (req, res) => {
  const { userId, amount, ownerNumber } = req.body;

  if (!userId || !amount || !ownerNumber) {
    return res.status(400).json({ message: 'Missing required fields.' });
  }

  try {
    const user = await User.findOne({ _id: userId }); // Assuming userId is MongoDB _id
    if (!user) return res.status(404).json({ message: 'User not found.' });

    user.wallet.balance += amount;
    user.wallet.lastUpdated = new Date();
    await user.save();

    const log = new ChargeLog({
      userId: user._id,
      amount,
      ownerNumber,
      note: `Owner ${ownerNumber} charged user ${userId}`,
    });

    await log.save();

    res.status(200).json({ message: 'Wallet charged and log saved.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error.' });
  }
});
// Get user wallet balance
app.get('/api/wallet/:userName', async (req, res) => {
  try {
    const user = await User.findOne({ userName: req.params.userName }).select('_id wallet');
    if (!user) return res.status(404).json({ message: 'User not found.' });

    res.status(200).json({
      userID: user._id,
      balance: user.wallet.balance,
      lastUpdated: user.wallet.lastUpdated
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});
// Deduct amount from user's wallet and log the payment
app.post('/api/wallet/deduct', async (req, res) => {
  const { userName, amount, description } = req.body;

  if (!userName || typeof amount !== 'number' || !description) {
    return res.status(400).json({ message: 'Username, amount, and description are required.' });
  }

  try {
    const user = await User.findOne({ userName });

    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    if (user.wallet.balance < amount) {
      return res.status(400).json({ message: 'Insufficient wallet balance.' });
    }

    // Deduct balance
    user.wallet.balance -= amount;
    user.wallet.lastUpdated = new Date();
    await user.save();

    // Log payment
    const payment = new Payment({
      userName,
      amount,
      description
    });
    await payment.save();

    res.status(200).json({
      message: 'Amount deducted and payment recorded successfully.',
      newBalance: user.wallet.balance
    });
  } catch (error) {
    console.error('Error deducting amount and logging payment:', error);
    res.status(500).json({ message: 'Server error.' });
  }
});
app.get('/api/payments/:userName', async (req, res) => {
  try {
    const history = await Payment.find({ userName: req.params.userName }).sort({ date: -1 });
    res.status(200).json(history);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});
// Charge wallet from bank (virtual bank integration)
app.post('/api/charge-bank', async (req, res) => {
  const { userName, amount, transactionId } = req.body;

  if (!userName || typeof amount !== 'number') {
    return res.status(400).json({ message: 'Username and amount are required.' });
  }

  try {
    const user = await User.findOne({ userName });

    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    user.wallet.balance += amount;
    user.wallet.lastUpdated = new Date();
    await user.save();

    // Log the bank top-up in the payments history
    const payment = new Payment({
      userName,
      amount,
      description: transactionId ? `Bank Top-Up (Transaction ID: ${transactionId})` : 'Bank Top-Up'
    });

    await payment.save();

    res.status(200).json({
      message: 'Wallet successfully charged from bank.',
      newBalance: user.wallet.balance
    });

  } catch (error) {
    console.error('Bank top-up error:', error);
    res.status(500).json({ message: 'Server error.' });
  }
});
app.get('/api/get-balances', async (req, res) => {
  const ownerNumber = req.query.ownerNumber;
  if (!ownerNumber) {
    return res.status(400).json({ message: 'Missing ownerNumber parameter' });
  }

  try {
    const chargeResult = await ChargeLog.aggregate([
      { $match: { ownerNumber } },
      { $group: { _id: null, totalCharged: { $sum: "$amount" } } }
    ]);

    const totalCharged = chargeResult[0]?.totalCharged || 0;

    res.json({ ownerNumber, totalCharged });
  } catch (error) {
    console.error('Error fetching total charged:', error);
    res.status(500).json({ message: 'Server error' });
  }
});
app.post('/deduct-wallet', async (req, res) => {
  const { userId, amount } = req.body;

  const user = await db.collection('users').findOne({ _id: new ObjectId(userId) });
  if (!user || user.wallet < amount) {
    return res.json({ success: false, message: 'Insufficient balance' });
  }

  await db.collection('users').updateOne(
    { _id: new ObjectId(userId) },
    { $inc: { wallet: -amount } }
  );

  res.json({ success: true });
});
//Get all parking slots
app.get('/api/slots', async (req, res) => {
  try {
    const slots = await Slot.find().sort({ slotNumber: 1 }); // sort by slotNumber ascending
    res.status(200).json(slots);

  } catch (error) {
    console.error('Error fetching slots:', error);
    res.status(500).json({ message: 'Server error while fetching slots.' });
  }
});
// Unified PUT route to update status, lock, unlock, confirm booking, etc.
app.put('/api/slots/:slotNumber', async (req, res) => {
  const { slotNumber } = req.params;
  const { status, userName, lockedBy, lockExpiresAt, from } = req.body;
  const now = new Date();

  const apiKey = req.headers['x-api-key'];
  if (from === 'sensor' && apiKey !== 'MY_SECRET_DEVICE_TOKEN') {
    return res.status(401).json({ error: 'Unauthorized sensor request.' });
  }

  console.log(`[API] Incoming slot update: slot=${slotNumber}, from=${from}, status=${status}`);

  try {
    const slot = await Slot.findOne({ slotNumber: parseInt(slotNumber, 10) });
    if (!slot) return res.status(404).json({ message: 'Slot not found.' });

    // ─── Expire lock if needed ──────────────────────
    if (slot.lockExpiresAt && slot.lockExpiresAt < now) {
      slot.lockedBy = null;
      slot.lockExpiresAt = null;
    }

    // ─── Sensor update rules ─────────────────────────
    if (from === 'sensor') {
      if (slot.status === 'reserved') {
        if (status === 'available') {
          return res.status(200).json({ message: 'Reserved slot, sensor cannot free it.', slot });
        }
        if (status === 'occupied') {
          console.log(`[SENSOR] Reserved slot ${slotNumber} now occupied.`);
        }
      } else if (slot.status === 'occupied' && status === 'occupied') {
        return res.status(409).json({ error: 'Slot already occupied.' });
      }

      if (status === 'occupied') {
        if (!userName) {
          console.warn(`[SENSOR] No userName provided for slot ${slotNumber}, applying fallback.`);
        }
        slot.userName = userName || slot.userName || 'unknown_sensor';
      }
    }

    // ─── Reserved → Available protection ─────────────
    if (slot.status === 'reserved' && status === 'available' && from !== 'admin' && from !== 'sensor') {
      if (slot.userName !== userName) {
        return res.status(403).json({ error: 'Only the user who reserved this slot can make it available.' });
      }
    }

    // ─── Apply status updates ────────────────────────
    if (status) {
      if (status === 'occupied') {
        if (!slot.occupiedSince) {
          slot.occupiedSince = now;
        }
      } else if (status === 'available') {
        if (slot.occupiedSince) {
          const duration = Math.floor((now - slot.occupiedSince) / 1000);
          slot.timeStayed = duration;
        }
        slot.userName = null;
        slot.occupiedSince = null;
      }
      slot.status = status;
    }

    // ─── Lock management ─────────────────────────────
    if (lockedBy !== undefined) slot.lockedBy = lockedBy || null;
    if (lockExpiresAt !== undefined) slot.lockExpiresAt = lockExpiresAt || null;

    slot.lastUpdated = now;

    console.log(`[DEBUG] Saving slot: ${JSON.stringify(slot.toObject(), null, 2)}`);
    await slot.save();

    res.json({ message: 'Slot updated successfully.', slot });

  } catch (err) {
    console.error('[ERROR] Updating slot:', err);
    res.status(500).json({ message: 'Server error.' });
  }
});
app.post('/api/slots/:slotNumber/select', async (req, res) => {
  const { userName } = req.body;
  const slotNumber = parseInt(req.params.slotNumber, 10);

  const now = new Date();
  const lockDurationMs = 2 * 60 * 1000; // 2 minutes

  try {
    const slot = await Slot.findOne({ slotNumber });

    if (!slot) return res.status(404).json({ message: 'Slot not found.' });

    if (slot.lockedBy && slot.lockExpiresAt && slot.lockExpiresAt > now) {
      if (slot.lockedBy === userName) {
        // Extend lock
        slot.lockExpiresAt = new Date(now.getTime() + lockDurationMs);
        await slot.save();
        return res.status(200).json({ message: 'Lock extended.', slot });
      } else {
        return res.status(409).json({ message: 'Slot is currently locked by another user.' });
      }
    }

    // Lock it
    slot.lockedBy = userName;
    slot.lockExpiresAt = new Date(now.getTime() + lockDurationMs);
    await slot.save();

    res.status(200).json({ message: 'Slot locked successfully.', slot });
  } catch (error) {
    console.error('Error locking slot:', error);
    res.status(500).json({ message: 'Server error.' });
  }
});
// Modified PUT endpoint with proper reserved slot protection
app.put('/api/slots/:slotNumber/confirm', async (req, res) => {
  const { userName } = req.body;
  const slotNumber = parseInt(req.params.slotNumber, 10);
  const now = new Date();

  try {
    const existingSlot = await Slot.findOne({
      userName,
      status: { $in: ['reserved', 'occupied'] }
    });

    if (existingSlot) {
      return res.status(400).json({
        error: `You already have a ${existingSlot.status} slot (#${existingSlot.slotNumber})`
      });
    }

    const slot = await Slot.findOne({ slotNumber });
    if (!slot) return res.status(404).json({ error: 'Slot not found' });

    if (slot.status !== 'available') {
      return res.status(400).json({ error: `Slot is currently ${slot.status}` });
    }

    if (!slot.lockExpiresAt || slot.lockExpiresAt < now) {
      return res.status(403).json({ error: 'Lock has expired or not set' });
    }

    if (slot.lockedBy !== userName) {
      return res.status(403).json({ error: 'You do not hold the lock' });
    }

    slot.userName = userName;
    slot.status = 'reserved';
    slot.lockedBy = userName;
    slot.lockExpiresAt = new Date(now.getTime() + 30 * 60 * 1000); // +30 min
    slot.lastUpdated = now;

    await slot.save();
    res.json({ message: 'Slot reserved successfully', slot });
  } catch (err) {
    console.error('Error confirming slot:', err);
    res.status(500).json({ error: err.message });
  }
});
const cleanupExpiredReservations = async () => {
  const now = new Date();
  const threshold = new Date(now.getTime() - 30 * 60 * 1000); // 30 minutes ago

  try {
    const result = await Slot.updateMany(
      { status: 'reserved', lastUpdated: { $lt: threshold } },
      { $set: {
        status: 'available',
        userName: null,
        lockedBy: null,
        lockExpiresAt: null
      }}
    );

    if (result.modifiedCount > 0) {
      console.log(`⏰ Cleared ${result.modifiedCount} expired reservations`);
    }
  } catch (error) {
    console.error('Error cleaning up expired reservations:', error);
  }
};

// Schedule cleanup every 5 minutes
cron.schedule('*/5 * * * *', cleanupExpiredReservations);


// Cancel reservation API
app.put('/api/slots/:slotNumber/handle_reservation', async (req, res) => {
  const slotNumber = parseInt(req.params.slotNumber, 10);
  
  try {
    const slot = await Slot.findOne({ slotNumber });

    if (!slot) {
      return res.status(404).json({ error: 'Slot not found' });
    }

    // Only cancel if slot is reserved
    if (slot.status === 'reserved') {
      slot.status = 'available';
      slot.userName = null;
      slot.lastUpdated = new Date();
      await slot.save();

      return res.json({ message: 'Reservation cancelled successfully' });
    } else {
      return res.status(400).json({ error: 'Slot is not reserved' });
    }
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

app.post('/api/slots/:slotNumber/cancel', async (req, res) => {
  const { userName } = req.body;
  const slotNumber = parseInt(req.params.slotNumber, 10);

  try {
    const slot = await Slot.findOne({ slotNumber });
    if (!slot) return res.status(404).json({ error: 'Slot not found' });

    if (slot.lockedBy !== userName) {
      return res.status(403).json({ error: 'You do not hold the lock' });
    }

    slot.lockedBy = null;
    slot.lockExpiresAt = null;
    await slot.save();

    res.json({ message: 'Lock released' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});// Occupy a parking slot (after reservation)
app.put('/api/slots/:slotNumber/occupy', async (req, res) => {
  const slotNumber = parseInt(req.params.slotNumber, 10);
  const { userName, duration = 1 } = req.body;  // Optional: duration in 15s units

  if (!userName) {
    return res.status(400).json({ message: 'Missing userName in request body.' });
  }

  try {
    const slot = await Slot.findOne({ slotNumber });

    if (!slot) {
      return res.status(404).json({ message: 'Slot not found.' });
    }

    if (slot.status === 'occupied') {
      return res.status(409).json({ message: 'Slot is already occupied.' });
    }

    if (slot.status !== 'reserved' || slot.userName !== userName) {
      return res.status(400).json({ message: 'Slot must be reserved by the same user before occupation.' });
    }

    // Format slot label (e.g., A01, A02, ...)
    const slotLabel = `A${slotNumber.toString().padStart(2, '0')}`;

    // Update metadata — status will be updated by ESP32 later
    slot.occupiedSince = new Date();
    slot.lockedBy = null;
    slot.lockExpiresAt = null;
    slot.lastUpdated = new Date();

    await slot.save();

    // Send commands to ESP32 in proper order
    pendingCommands.push({ cmd: 'PIN', slot: slotLabel, pin: userName });
    pendingCommands.push({ cmd: `D${duration}` });
    pendingCommands.push({ cmd: 'START', slot: slotLabel, userName });

    return res.status(200).json({
      message: `Slot ${slotNumber} is now occupied by ${userName}.`,
      slot
    });

  } catch (err) {
    console.error('Error occupying slot:', err);
    res.status(500).json({ message: 'Server error.' });
  }
});

// POST a new command (from Flutter)
app.post('/api/cmd', (req, res) => {
  const { cmd, slot, pin, duration } = req.body;
  if (!cmd) return res.status(400).json({ message: 'Missing cmd' });
  pendingCommands.push({ cmd, slot, pin, duration });
  res.json({ status: 'ok' });
});
// GET next pending command (for ESP polling)
app.get('/api/cmd/next', (req, res) => {
  if (pendingCommands.length === 0) {
    return res.status(204).end();
  }
  res.json(pendingCommands.shift());
});
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
