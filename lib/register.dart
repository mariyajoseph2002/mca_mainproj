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

  // Predefined lists
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
    if (_currentStep == _questions.length) {
      _registerUser();
    } else {
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
  List<Widget> _buildQuestionStep() {
    return [
      Text(
        _questions[_currentStep - 1],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
      ),
      const SizedBox(height: 20),
      if (_currentStep == 1) _buildDropdown(['Female', 'Male', 'Other'], selectedGender, (value) => setState(() => selectedGender = value!)),
      if (_currentStep == 2) _buildDropdown(['Single', 'In a Relationship', 'Married'], selectedRelationship, (value) => setState(() => selectedRelationship = value!)),
      if (_currentStep == 3) _buildDropdown(['Student', 'Working Professional', 'Self-Employed', 'Unemployed'], selectedOccupation, (value) => setState(() => selectedOccupation = value!)),
      if (_currentStep == 4) _buildMultiSelect(hobbies, selectedHobbies, "Other", otherHobbyController),
      if (_currentStep == 5) _buildMultiSelect(selfCareActivities, selectedSelfCareActivities),
      if (_currentStep == 6) _buildMultiSelect(contacts, closeContacts),
    ];
  }

  Widget _buildDropdown(List<String> options, String selectedValue, Function(String?) onChanged) {
    return DropdownButtonFormField(
      value: selectedValue,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: options.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
      onChanged: onChanged,
    );
  }
Widget _buildMultiSelect(List<String> options, List<String> selectedList, [String? otherOption, TextEditingController? otherController]) {
  List<Widget> checkboxes = options.map((option) {
    return CheckboxListTile(
      title: Text(option),
      value: selectedList.contains(option),
      onChanged: (isChecked) {
        setState(() {
          isChecked! ? selectedList.add(option) : selectedList.remove(option);
        });
      },
    );
  }).toList();

  if (otherOption != null) {
    checkboxes.add(
      CheckboxListTile(
        title: Text(otherOption),
        value: selectedList.contains(otherOption),
        onChanged: (isChecked) {
          setState(() {
            if (isChecked!) {
              selectedList.add(otherOption);
            } else {
              selectedList.remove(otherOption);
            }
          });
        },
      ),
    );

    if (selectedList.contains(otherOption)) {
      checkboxes.add(
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: TextField(
            controller: otherController,
            decoration: const InputDecoration(
              labelText: "Specify Other",
              border: OutlineInputBorder(),
            ),
          ),
        ),
      );
    }
  }

  return Column(children: checkboxes);
}


  // Widget _buildTextField({required TextEditingController controller, required String hintText, TextInputType keyboardType = TextInputType.text, bool obscureText = false}) {
  //   return TextFormField(
  //     controller: controller,
  //     keyboardType: keyboardType,
  //     obscureText: obscureText,
  //     decoration: InputDecoration(labelText: hintText, border: OutlineInputBorder()),
  //   );
  // }
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

  Future<void> _registerUser() async {
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: emailController.text, password: passwordController.text);
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': nameController.text,
        'email': emailController.text,
        'gender': selectedGender,
        'relationship_status': selectedRelationship,
        'occupation': selectedOccupation,
        'hobbies': selectedHobbies,
        'self_care_activities': selectedSelfCareActivities,
        'close_contacts': closeContacts,
        'role':'customer',
        'xp':0,
        'streak':0
      });
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
