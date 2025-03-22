import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login2.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
 final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  int _currentStep = 0;

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController otherHobbyController = TextEditingController();

  // Drop-down selections
  String selectedGender = 'Female';
  String selectedRelationship = 'Single';
  String selectedOccupation = 'Student';

  // Multiple choice selections
  List<String> selectedHobbies = [];
  List<String> selectedSelfCareActivities = [];
  List<String> closeContacts = [];

  List<String> hobbies = ['Reading', 'Music', 'Art', 'Sports', 'Gaming', 'Traveling', 'Cooking', 'Gardening', 'Others'];
  List<String> selfCareActivities = ['Yoga', 'Meditation', 'Exercise', 'Journaling', 'Beauty Care', 'Nature Walks', 'Therapy'];
  List<String> contacts = ['Mom', 'Dad', 'Sibling', 'Best Friend', 'Partner', 'Other'];

  final List<String> _questions = [
    "What is your gender?",
    "What is your relationship status?",
    "What is your occupation?",
    "Select at least 3 hobbies",
    "Select your self-care activities",
    "Who do you turn to for emotional support?",
  ];
void _nextStep() {
  if (_currentStep == 1 && selectedGender == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select your gender.")));
    return;
  }
  if (_currentStep == 2 && selectedRelationship == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select your relationship status.")));
    return;
  }
  if (_currentStep == 3 && selectedOccupation == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select your occupation.")));
    return;
  }

  if (_currentStep >= _questions.length - 1) {
    _registerUser();
  } else {
    FocusScope.of(context).unfocus(); // Dismiss keyboard before updating state
    setState(() => _currentStep++);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_currentStep == 0) ..._buildBasicInfo(),
                      if (_currentStep > 0) ..._buildQuestionStep(),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                          ),
                          child: Text(_currentStep == _questions.length ? "Finish Registration" : "Next"),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// Step 1: Basic Information UI
  List<Widget> _buildBasicInfo() {
    return [
      const Text(
        "Welcome to HealPal!",
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple),
      ),
      const SizedBox(height: 10),
      const Text("Tell us a bit about yourself to personalize your experience.", style: TextStyle(fontSize: 16)),
      const SizedBox(height: 20),
      _buildTextField(controller: nameController, hintText: 'Full Name'),
      _buildTextField(controller: emailController, hintText: 'Email', keyboardType: TextInputType.emailAddress),
      _buildTextField(controller: passwordController, hintText: 'Password', obscureText: true),
      _buildTextField(controller: ageController, hintText: 'Age', keyboardType: TextInputType.number),
      _buildTextField(controller: phoneController, hintText: 'Phone Number', keyboardType: TextInputType.phone),
      _buildTextField(controller: cityController, hintText: 'City'),
    ];
  }

  /// Step 2+: Single Question UI
  /* List<Widget> _buildQuestionStep() {
    return [
      Text(
        _questions[_currentStep - 1],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
      ),
      const SizedBox(height: 20),
      if (_currentStep == 1)
        _buildDropdown(['Female', 'Male', 'Other'], selectedGender, (value) => setState(() => selectedGender = value!)),
      if (_currentStep == 2)
        _buildDropdown(['Single', 'In a Relationship', 'Married', 'Divorced/Widowed'], selectedRelationship, (value) => setState(() => selectedRelationship = value!)),
      if (_currentStep == 3)
        _buildDropdown(['Student', 'Working Professional', 'Freelancer', 'Homemaker', 'Unemployed'], selectedOccupation, (value) => setState(() => selectedOccupation = value!)),
      if (_currentStep == 4) _buildCheckboxList(hobbies, selectedHobbies),
      if (_currentStep == 5) _buildCheckboxList(selfCareActivities, selectedSelfCareActivities),
      if (_currentStep == 6) _buildCheckboxList(contacts, closeContacts),
      if (_currentStep == 4 && selectedHobbies.contains('Others'))
        _buildTextField(controller: otherHobbyController, hintText: "Enter your hobby"),
    ];
  } */
 List<Widget> _buildQuestionStep() {
  if (_currentStep > _questions.length) return []; // Prevent out-of-range error

  return [
    Text(
      _questions[_currentStep - 1],
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
    ),
    const SizedBox(height: 20),

    if (_currentStep == 1)
      _buildDropdown(['Female', 'Male', 'Other'], selectedGender, 
        (value) => setState(() => selectedGender = value!)),

    if (_currentStep == 2)
      _buildDropdown(['Single', 'In a Relationship', 'Married', 'Divorced/Widowed'], 
        selectedRelationship, (value) => setState(() => selectedRelationship = value!)),

    if (_currentStep == 3)
      _buildDropdown(['Student', 'Working Professional', 'Freelancer', 'Homemaker', 'Unemployed'], 
        selectedOccupation, (value) => setState(() => selectedOccupation = value!)),

    if (_currentStep == 4) _buildCheckboxList(hobbies, selectedHobbies),

    if (_currentStep == 5) _buildCheckboxList(selfCareActivities, selectedSelfCareActivities),

    if (_currentStep == 6) _buildCheckboxList(contacts, closeContacts),

    // Show "Others" text field only if the user selected "Others" in hobbies
    if (selectedHobbies.contains('Others'))
      _buildTextField(controller: otherHobbyController, hintText: "Enter your hobby"),
  ];
}


  /// Firebase Registration Logic
  Future<void> _registerUser() async {
    if (passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password must be at least 8 characters long.")));
      return;
    }
    if (selectedHobbies == null || selectedHobbies.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least 3 hobbies.")));
      return;
    }
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      User? user = userCredential.user;
      if (user != null) {
        CollectionReference users = FirebaseFirestore.instance.collection('users');
           await users.doc(user.uid).set({
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'password': passwordController.text.trim(), // ⚠️ Not recommended to store plaintext passwords
      'age': int.parse(ageController.text.trim()),
      'phone': phoneController.text.trim(),
      'city': cityController.text.trim(),
      'gender': selectedGender ?? "Not specified",
      'relationship_status': selectedRelationship ?? "Not specified",
      'occupation': selectedOccupation ?? "Not specified",
      'hobbies': selectedHobbies.isNotEmpty ? selectedHobbies : ["None"],
      'self_care_activities': selectedSelfCareActivities.isNotEmpty ? selectedSelfCareActivities : ["None"],
      'close_contacts': closeContacts.isNotEmpty ? closeContacts : ["None"],
      'xp': 0,
      'streak': 0,
      'role': 'customer'
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registration successful!")));
  }
} catch (e) {
  print("Error: $e");
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Registration failed: $e")));
} finally {
  setState(() => _isLoading = false);
}

  }

  /// UI Helpers
  Widget _buildTextField({required TextEditingController controller, required String hintText, TextInputType keyboardType = TextInputType.text, bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(labelText: hintText, border: OutlineInputBorder()),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String selectedValue, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(border: OutlineInputBorder()),
      value: selectedValue,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildCheckboxList(List<String> items, List<String> selectedItems) {
    return Column(
      children: items.map((item) => CheckboxListTile(
            title: Text(item),
            value: selectedItems.contains(item),
            onChanged: (checked) => setState(() => checked == true ? selectedItems.add(item) : selectedItems.remove(item)),
          )).toList(),
    );
  }
}
