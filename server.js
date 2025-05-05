const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcrypt');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(express.json());


// ✅ MongoDB Connection (Database: QuickParkDB)
mongoose.connect('mongodb://localhost:27017/QuickParkDB', {
  useNewUrlParser: true,
  useUnifiedTopology: true
}).then(() => console.log('✅ MongoDB Connected'))
  .catch(err => console.error('❌ MongoDB Error:', err));

// ✅ Schema and Model
const userSchema = new mongoose.Schema({
  fullName: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  userName: { type: String, required: true, unique: true },
  password: { type: String, required: true },
});

const User = mongoose.model('User', userSchema);

// ✅ API: Register User
app.post('/api/users', async (req, res) => {
  try {
    const { fullName, email, userName, password } = req.body;

    // Validate input
    if (!fullName || !email || !userName || !password) {
      return res.status(400).json({ message: 'All fields are required.' });
    }

    // Check if email or username exists
    const emailExists = await User.findOne({ email });
    const userNameExists = await User.findOne({ userName });

    if (emailExists || userNameExists) {
      return res.status(409).json({ message: 'Email or Username already exists.' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create and save user
    const newUser = new User({
      fullName,
      email,
      userName,
      password: hashedPassword,
    });

    await newUser.save();

    return res.status(201).json({ message: 'User registered successfully.' });
  } catch (error) {
    console.error('❌ Error in /api/users:', error);
    return res.status(500).json({ message: 'Server error.' });
  }
});

// ✅ Start Server
app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
});
