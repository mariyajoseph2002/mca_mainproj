import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  // Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String selectedGender = 'Female'; // Default gender

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    cityController.dispose();
    ageController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 164, 229, 239),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 50),
                          const Text(
                            "Register Now",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 36,
                            ),
                          ),
                          const SizedBox(height: 40),
                          _buildTextField(
                            controller: nameController,
                            hintText: 'Name',
                            validator: _validateName,
                          ),
                          _buildTextField(
                            controller: emailController,
                            hintText: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                          _buildTextField(
                            controller: passwordController,
                            hintText: 'Password',
                            obscureText: true,
                            validator: _validatePassword,
                          ),
                          _buildTextField(
                            controller: confirmPasswordController,
                            hintText: 'Confirm Password',
                            obscureText: true,
                            validator: _validateConfirmPassword,
                          ),
                          _buildTextField(
                            controller: cityController,
                            hintText: 'City',
                            validator: _validateCity,
                          ),
                          _buildTextField(
                            controller: ageController,
                            hintText: 'Age',
                            keyboardType: TextInputType.number,
                            validator: _validateAge,
                          ),
                          _buildTextField(
                            controller: phoneController,
                            hintText: 'Phone Number',
                            keyboardType: TextInputType.phone,
                            validator: _validatePhone,
                          ),
                          _buildGenderDropdown(),
                          const SizedBox(height: 20),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  // TextField Widget
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hintText,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 14),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color.fromARGB(255, 248, 161, 242)),
            borderRadius: BorderRadius.circular(20),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        validator: validator,
      ),
    );
  }

  // Gender Dropdown
  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        value: selectedGender,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        items: ['Female', 'Male', 'Other'].map((String gender) {
          return DropdownMenuItem(
            value: gender,
            child: Text(gender),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedGender = value!;
          });
        },
      ),
    );
  }

  // Action Buttons
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text("Login", style: TextStyle(fontSize: 20)),
        ),
        ElevatedButton(
          onPressed: _register,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text("Register", style: TextStyle(fontSize: 20)),
        ),
      ],
    );
  }

  // Validation Methods
  String? _validateName(String? value) => value!.isEmpty ? "Name cannot be empty" : null;

  String? _validateEmail(String? value) {
    if (value!.isEmpty) return "Email cannot be empty";
    if (!RegExp(r'^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+\.[a-z]+$').hasMatch(value)) {
      return "Enter a valid email";
    }
    return null;
  }

  String? _validatePassword(String? value) => value!.length < 6 ? "Password must be at least 6 characters" : null;

  String? _validateConfirmPassword(String? value) =>
      value != passwordController.text ? "Passwords do not match" : null;

  String? _validateCity(String? value) => value!.isEmpty ? "City cannot be empty" : null;

  String? _validateAge(String? value) {
    if (value!.isEmpty) return "Age cannot be empty";
    if (int.tryParse(value) == null || int.parse(value) <= 0) {
      return "Enter a valid age";
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value!.isEmpty) return "Phone number cannot be empty";
    if (!RegExp(r'^\d{10}$').hasMatch(value)) return "Phone number must be 10 digits";
    return null;
  }

  // Registration Method
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      await _postDetailsToFirestore(userCredential.user!.uid);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration Successful")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _postDetailsToFirestore(String uid) async {
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    await users.doc(uid).set({
      'name': nameController.text,
      'email': emailController.text,
      'role': "Customer", // Default role
      'gender': selectedGender,
      'city': cityController.text,
      'age': int.parse(ageController.text),
      'phone': phoneController.text,
      'xp':0,
      'streak':0
    });
  }
}
