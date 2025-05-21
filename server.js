require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors({
  origin: 'http://127.0.0.1:5500',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
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

const carSchema = new mongoose.Schema({
  plateNumber: { type: String, required: true, unique: true },
  carBrand: { type: String, required: true },
  insuranceProvider: { type: String, required: true },
  carModel: { type: String, required: true },
  carType: { type: String, required: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
});

const Car = mongoose.model('Car', carSchema);

const chargeLogSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  amount: { type: Number, required: true },
  ownerId: { type: mongoose.Schema.Types.ObjectId, required: true },
  timestamp: { type: Date, default: Date.now },
  note: String,
});

const ChargeLog = mongoose.model('ChargeLog', chargeLogSchema);

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

// Routes

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

// Get all cars for user
app.get('/api/cars/user/:userName', async (req, res) => {
  try {
    const user = await User.findOne({ userName: req.params.userName });
    if (!user) return res.status(404).json({ message: 'User not found.' });

    const cars = await Car.find({ userId: user._id });
    res.status(200).json(cars);
  } catch {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Add new car
app.post('/api/cars', async (req, res) => {
  const { plateNumber, carBrand, insuranceProvider, carModel, carType, userName } = req.body;

  try {
    if (await Car.findOne({ plateNumber })) return res.status(400).json({ message: 'Plate number already registered.' });

    const user = await User.findOne({ userName });
    if (!user) return res.status(404).json({ message: 'User not found.' });

    const newCar = new Car({
      plateNumber,
      carBrand,
      insuranceProvider,
      carModel,
      carType,
      userId: user._id,
    });

    await newCar.save();
    res.status(201).json({ message: 'Car registered successfully.' });
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
  const { userName, amount, ownerId } = req.body;

  if (!userName || !amount || !ownerId) {
    return res.status(400).json({ message: 'Missing required fields.' });
  }

  try {
    const user = await User.findOne({ userName });
    if (!user) return res.status(404).json({ message: 'User not found.' });

    user.wallet.balance += amount;
    user.wallet.lastUpdated = new Date();
    await user.save();

    const log = new ChargeLog({
      userId: user._id,
      amount,
      ownerId,
      note: `Owner ${ownerId} charged user ${userName}`,
    });

    await log.save();

    res.status(200).json({ message: 'Wallet charged and log saved.' });
  } catch {
    res.status(500).json({ message: 'Server error.' });
  }
});

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
