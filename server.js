const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB Connection String (MongoDB Atlas)
const mongoURI = process.env.MONGO_URI;

mongoose.connect(mongoURI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('✅ Connected to MongoDB Atlas'))
.catch(err => console.error('❌ MongoDB Error:', err));

const userSchema = new mongoose.Schema({
  fullName: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  userName: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  wallet: {
    balance: { type: Number, default: 0 },
    lastUpdated: { type: Date, default: Date.now }
  }
});

const User = mongoose.model('User', userSchema);

// Car Schema and Model
const carSchema = new mongoose.Schema({
  plateNumber: { type: String, required: true, unique: true },
  carBrand: { type: String, required: true },
  insuranceProvider: { type: String, required: true },
  carModel: { type: String, required: true },
  carType: { type: String, required: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
});

const Car = mongoose.model('Car', carSchema);


// Send OTP Email
const sendOTPEmail = async (email, otp) => {
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
};

// Request OTP
app.post('/api/request-otp', async (req, res) => {
  const { email } = req.body;
  const user = await User.findOne({ email });
  if (!user) return res.status(404).json({ message: 'User not found.' });

  const otp = Math.floor(100000 + Math.random() * 900000).toString(); // 6-digit OTP

  // Sign OTP into a JWT (expires in 10 minutes)
  const otpToken = jwt.sign(
    { email, otp },
    process.env.JWT_SECRET,  // Use the JWT secret
    { expiresIn: '10m' }
  );

  await sendOTPEmail(email, otp); // Send OTP via email

  return res.status(200).json({
    message: 'OTP sent to your email.',
    otpToken, // Send token to client
  });
});
app.post('/api/verify-otp', async (req, res) => {
    const { otpToken, otp } = req.body;
  
    try {
      // Verify the OTP token using JWT
      const decoded = jwt.verify(otpToken, process.env.JWT_SECRET);
  
      if (decoded.otp !== otp) {
        return res.status(400).json({ message: 'Invalid OTP.' });
      }
  
      // OTP is valid
      return res.status(200).json({
        message: 'OTP verified successfully.',
        email: decoded.email, // optional, if needed on client
        verifiedToken: jwt.sign({ email: decoded.email }, process.env.JWT_SECRET, { expiresIn: '10m' })
      });
    } catch (error) {
      console.error(error);
      return res.status(400).json({ message: 'Invalid or expired token.' });
    }
  });
  
// POST endpoint to create a new user (User registration)
app.post('/api/users', async (req, res) => {
    const { fullName, email, userName, password } = req.body;
  
    try {
      // Check if the user already exists
      const existingUser = await User.findOne({ email });
      if (existingUser) {
        return res.status(400).json({ message: 'Email already in use.' });
      }
  
      const existingUserName = await User.findOne({ userName });
      if (existingUserName) {
        return res.status(400).json({ message: 'Username already taken.' });
      }
  
      // Hash the password
      const hashedPassword = await bcrypt.hash(password, 10);
  
      // Create a new user
      const newUser = new User({
        fullName,
        email,
        userName,
        password: hashedPassword,
      });
  
      // Save the user to the database
      await newUser.save();
  
      return res.status(201).json({ message: 'User created successfully.' });
    } catch (error) {
      console.error(error);
      return res.status(500).json({ message: 'Server error.' });
    }
  });

  app.post('/api/login', async (req, res) => {
    try {
      const { userName, password } = req.body;
  
      // 1. Validate input
      if (!userName || !password) {
        return res.status(400).json({ message: 'Username and password are required.' });
      }
  
      // 2. Find the user by userName
      const user = await User.findOne({ userName });
  
      if (!user) {
        return res.status(401).json({ message: 'Invalid credentials.' });
      }
  
      // 3. Compare input password with stored hashed password
      const isMatch = await bcrypt.compare(password, user.password);
  
      if (!isMatch) {
        return res.status(401).json({ message: 'Invalid credentials.' });
      }
  
      // 4. Login success (optionally, generate a token here)
      return res.status(200).json({
        message: 'Login successful.',
        user: {
          id: user._id,
          fullName: user.fullName,
          email: user.email,
          userName: user.userName,
        },
      });
  
    } catch (error) {
      console.error('❌ Error in /api/login:', error);
      return res.status(500).json({ message: 'Server error.' });
    }
  });
  app.post('/api/reset-password', async (req, res) => {
    const { otpToken, newPassword } = req.body;
  
    try {
      // 1. Decode the OTP token
      const decoded = jwt.verify(otpToken, process.env.JWT_SECRET);
      const email = decoded.email;
  
      // 2. Log email and new password
      console.log("Resetting password for:", email);
      console.log("New password:", newPassword);
  
      // 3. Hash the new password
      const hashedPassword = await bcrypt.hash(newPassword, 10);
      console.log("Hashed password:", hashedPassword);
  
      // 4. Update user's password
      const updateResult = await User.updateOne(
        { email },
        { $set: { password: hashedPassword } }
      );
  
      console.log("Update result:", updateResult);
  
      if (updateResult.modifiedCount === 0) {
        return res.status(400).json({ message: 'Failed to update password.' });
      }
  
      res.status(200).json({ message: 'Password has been reset successfully.' });
    } catch (error) {
      console.error("❌ Reset error:", error);
      res.status(500).json({ message: 'Failed to reset password.' });
    }
  });
  // GET user data by username
app.get('/api/users/username/:userName', async (req, res) => {
    const { userName } = req.params;
  
    try {
      const user = await User.findOne({ userName }).select('-password');
      if (!user) return res.status(404).json({ message: 'User not found.' });
  
      res.status(200).json(user);
    } catch (error) {
      console.error('❌ Error fetching user by username:', error);
      res.status(500).json({ message: 'Server error.' });
    }
  });
  // Route to update user data by username
app.put('/api/users/update/username/:userName', async (req, res) => {
  const { userName } = req.params;
  const { fullName, email } = req.body;

  // Validate the input
  if (!fullName || !email) {
    return res.status(400).json({ message: 'Full Name and Email are required.' });
  }

  try {
    // Find the user by username
    const user = await User.findOne({ userName });

    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    // Update user information
    user.fullName = fullName || user.fullName;
    user.email = email || user.email;

    // Save the updated user to the database
    await user.save();

    return res.status(200).json({ message: 'User updated successfully', user });
  } catch (error) {
    console.error('❌ Error updating user:', error);
    return res.status(500).json({ message: 'Server error.' });
  }
});
  
  // GET all cars for a specific user
  app.get('/api/cars/user/:userName', async (req, res) => {
    const { userName } = req.params;
  
    try {
      const user = await User.findOne({ userName });
  
      if (!user) {
        return res.status(404).json({ message: 'User not found.' });
      }
  
      // Assuming 'userId' or 'owner' field in the Car schema links to User._id
      const cars = await Car.find({ userId: user._id });
  
      res.status(200).json(cars);
    } catch (error) {
      console.error('❌ Error fetching cars:', error);
      res.status(500).json({ message: 'Server error.' });
    }
  });
  
// POST to add a new car
app.post('/api/cars', async (req, res) => {
  const { plateNumber, carBrand, insuranceProvider, carModel, carType, userName } = req.body;

  try {
    const existingCar = await Car.findOne({ plateNumber });
    if (existingCar) {
      return res.status(400).json({ message: 'Plate number already registered.' });
    }

    const user = await User.findOne({ userName });
    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    const newCar = new Car({
      plateNumber,
      carBrand,
      insuranceProvider,
      carModel,
      carType,
      userId: user._id, // Use userId, not userName
    });

    await newCar.save();
    res.status(201).json({ message: 'Car registered successfully.' });
  } catch (error) {
    console.error('❌ Error registering car:', error);
    res.status(500).json({ message: 'Server error.' });
  }
});
function haversine(lat1, lon1, lat2, lon2) {
  const toRad = (x) => (x * Math.PI) / 180;

  const R = 6371; // Radius of Earth in kilometers
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c; // distance in kilometers
}

app.post('/check-distance', (req, res) => {
  try {
    const { lat, lon } = req.body;

    if (typeof lat !== 'number' || typeof lon !== 'number') {
      return res.status(400).json({ error: 'Invalid or missing lat/lon values' });
    }

    const parkingLat = 31.963158;
    const parkingLon = 35.930359;

    const distance = haversine(lat, lon, parkingLat, parkingLon);
    const maxDistance = 0.1; // 100 meters

    if (distance <= maxDistance) {
      res.json({ allowed: true });
    } else {
      res.json({ allowed: false });
    }
  } catch (err) {
    console.error('❌ Error in /check-distance:', err);
    res.status(500).json({ error: 'Internal Server Error', details: err.message });
  }
});

  app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
  });