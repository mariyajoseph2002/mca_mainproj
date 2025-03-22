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




  final TextEditingController otherOccupationController = TextEditingController();
final TextEditingController otherHobbyController = TextEditingController();
  final TextEditingController otherSelfCareController = TextEditingController();
  final TextEditingController otherContactController = TextEditingController();


  // Drop-down selections
  String selectedGender = 'Female';
  String selectedRelationship = 'Single';
  String selectedOccupation = 'Student';

  // Multiple choice selections
  List<String> selectedHobbies = [];
  List<String> selectedSelfCareActivities = [];
  List<String> closeContacts = [];


@override
  void dispose() {
    // Dispose all controllers
    nameController.dispose();
    emailController.dispose();
    ageController.dispose();
    phoneController.dispose();
    cityController.dispose();
    passwordController.dispose();
   
    otherOccupationController.dispose();
    otherHobbyController.dispose();
    otherSelfCareController.dispose();
    otherContactController.dispose();
    super.dispose();
  }
  // Predefined lists
  List<String> hobbies = ['Reading', 'Music', 'Art', 'Sports', 'Gaming', 'Traveling', 'Cooking', 'Gardening'];
  List<String> selfCareActivities = ['Yoga', 'Meditation', 'Exercise', 'Journaling', 'Beauty Care', 'Nature Walks', 'Therapy'];
  List<String> contacts = ['Mom', 'Dad', 'Sibling', 'Best Friend', 'Partner'];

  final List<String> _questions = [
    "What is your gender?",
    "What is your relationship status?",
    "What is your occupation?",
    "Select at least 3 hobbies",
    "Select your self-care activities",
    "Who do you turn to for emotional support?",
  ];

void _nextStep() {
  if (_currentStep == 6 && closeContacts.isEmpty) {
    showErrorMessage("Please select at least one close contact.");
    return;
  }

  if (_currentStep < _questions.length) {
    setState(() {
      _currentStep++;
    });
  } else {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _registerUser();  // Ensure this function exists and works
    }
  }
}


 /*  void _nextStep() {
  setState(() {
    if (_currentStep == 6 && closeContacts.isEmpty) {
      // Ensure the user selects at least one close contact
      showErrorMessage("Please select at least one close contact.");
      return;
    }
    if (_currentStep < 6) {
      _currentStep++;
    }
  });
  } */
void showErrorMessage(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message, style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
  );
}
/* 
void _nextStep() {
  print("Current Step Before: $_currentStep");
  print("Total Steps: ${_questions.length}");

  // If on the last step (Close Contacts selection), ensure at least one is selected
  if (_currentStep == _questions.length - 1) {
    if (closeContacts.isEmpty) {  
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one emotional support contact."),
          backgroundColor: Colors.red,
        ),
      );
      return;  // Prevent moving forward
    }
  }

  if (_currentStep == _questions.length) {  // Last step before registration
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _registerUser();
    }
  } else {
    setState(() {
      _currentStep++;  // Move to the next step
    });
    print("Current Step After: $_currentStep");
  }
}

 */




/*   @override
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
                            backgroundColor: const Color.fromARGB(255, 178, 153, 222),
                            foregroundColor: Colors.white,
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
  } */
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
              : Form(  // Wrap with Form
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_currentStep == 0) ..._buildBasicInfo(),
                      if (_currentStep > 0) ..._buildQuestionStep(),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 178, 153, 222),
                            foregroundColor: Colors.white,
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
/*   List<Widget> _buildQuestionStep() {
    return [
      Text(
        _questions[_currentStep - 1],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
      ),
      const SizedBox(height: 20),
      if (_currentStep == 1) _buildDropdown(['Female', 'Male', 'Other'], selectedGender, (value) => setState(() => selectedGender = value!)),
      if (_currentStep == 2) _buildDropdown(['Single', 'In a Relationship', 'Married'], selectedRelationship, (value) => setState(() => selectedRelationship = value!)),
      if (_currentStep == 3) _buildDropdown(['Student', 'Working Professional', 'Self-Employed', 'Unemployed'], selectedOccupation, (value) => setState(() => selectedOccupation = value!)),
      //if (_currentStep == 4) _buildMultiSelect(hobbies, selectedHobbies, "Other", otherHobbyController),
      if (_currentStep == 4) _buildMultiSelect(hobbies, selectedHobbies),
      if (_currentStep == 5) _buildMultiSelect(selfCareActivities, selectedSelfCareActivities),
      if (_currentStep == 6) _buildMultiSelect(contacts, closeContacts),
    ];
  } */
 List<Widget> _buildQuestionStep() {
    return [
      Text(
        _questions[_currentStep - 1],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
      ),
      const SizedBox(height: 20),
      if (_currentStep == 1) _buildDropdown(['Female', 'Male', 'Other'], selectedGender, (value) => setState(() => selectedGender = value!)),
      if (_currentStep == 2) _buildDropdown(['Single', 'In a Relationship', 'Married'], selectedRelationship, (value) => setState(() => selectedRelationship = value!)),
      if (_currentStep == 3) _buildDropdown(['Student', 'Working Professional', 'Self-Employed', 'Unemployed', 'Other'], selectedOccupation, (value) => setState(() => selectedOccupation = value!)),
     // if (selectedOccupation == 'Other') _buildTextField(controller: otherOccupationController, hintText: "Specify your occupation"),
      if (_currentStep == 4) _buildMultiSelect(hobbies, selectedHobbies, "Other",otherHobbyController),
      if (_currentStep == 5) _buildMultiSelect(selfCareActivities, selectedSelfCareActivities, "Other",otherSelfCareController),
      if (_currentStep == 6) _buildMultiSelect(contacts, closeContacts, "Other",otherContactController),
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
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ...options.map((option) {
        return CheckboxListTile(
          title: Text(option),
          value: selectedList.contains(option),
          onChanged: (isChecked) {
            setState(() {
              isChecked! ? selectedList.add(option) : selectedList.remove(option);
            });
          },
        );
      }).toList(),

      if (otherOption != null) 
        CheckboxListTile(
          title: Text(otherOption),
          value: selectedList.contains(otherOption),
          onChanged: (isChecked) {
            setState(() {
              if (isChecked!) {
                selectedList.add(otherOption);
              } else {
                selectedList.remove(otherOption);
                otherController?.clear(); // Clear input when deselected
              }
            });
          },
        ),

      if (otherOption != null && selectedList.contains(otherOption))
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: otherController,
            decoration: const InputDecoration(
              labelText: "Specify Other",
              border: OutlineInputBorder(),
            ),
          ),
        ),
    ],
  );
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
 /*  if (_formKey.currentState == null) {
    print("Error: _formKey.currentState is null");
    return;
  }

  if (!_formKey.currentState!.validate()) {
    print("Form validation failed");
    return;
  } */

  setState(() => _isLoading = true);

  try {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    User? user = userCredential.user;

    if (user != null) {
      String uid = user.uid;

      // Replace "Other" with the actual input
      String finalOccupation = selectedOccupation == "Other" ? otherOccupationController.text.trim() : selectedOccupation;
      List<String> finalHobbies = selectedHobbies.map((hobby) => hobby == "Other" ? otherHobbyController.text.trim() : hobby).toList();
      List<String> finalSelfCare = selectedSelfCareActivities.map((activity) => activity == "Other" ? otherSelfCareController.text.trim() : activity).toList();
      List<String> finalContacts = closeContacts.map((contact) => contact == "Other" ? otherContactController.text.trim() : contact).toList();

      // Store user details in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'age': int.parse(ageController.text.trim()),
        'phone': phoneController.text.trim(),
        'city': cityController.text.trim(),
        'gender': selectedGender,
        'relationship_status': selectedRelationship,
        'occupation': finalOccupation,
        'hobbies': finalHobbies,
        'self_care_activities': finalSelfCare,
        'close_contacts': finalContacts,
        'registration_date': Timestamp.now(),
      });
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Succesfully added your details"), backgroundColor: const Color.fromARGB(255, 158, 224, 149)));

      // Navigate to next screen
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
    }
  } catch (e) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red));
  }
}

}
