import 'dart:io';
import 'package:diarykuh/data/database_helper.dart';
import 'package:diarykuh/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:email_validator/email_validator.dart';
import 'package:diarykuh/common/custom_form_button.dart';
import 'package:diarykuh/common/custom_input_field.dart';
import 'package:diarykuh/common/page_header.dart';
import 'package:diarykuh/common/page_heading.dart';
import './login_page.dart';

const Color kBackgroundColor = Color.fromARGB(255, 233, 233, 239);

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  File? _profileImage;
  final _signupFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future _pickProfileImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final imageTemporary = File(image.path);
      setState(() => _profileImage = imageTemporary);
    } on PlatformException catch (e) {
      debugPrint('Gagal memilih gambar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        body: SingleChildScrollView(
          child: Form(
            key: _signupFormKey,
            child: Column(
              children: [
                const PageHeader(),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const PageHeading(title: 'Buat Akun DiaryKuh'),
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: Stack(
                            children: [
                              Positioned(
                                bottom: 5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: _pickProfileImage,
                                  child: Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade400,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_sharp,
                                      color: Colors.white,
                                      size: 25,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomInputField(
                        labelText: 'Nama',
                        hintText: 'Masukkan nama Anda',
                        controller: _nameController,
                        validator: (textValue) {
                          if (textValue == null || textValue.isEmpty) {
                            return 'Nama tidak boleh kosong!';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomInputField(
                        labelText: 'Email',
                        hintText: 'Masukkan email Anda',
                        controller: _emailController,
                        validator: (textValue) {
                          if (textValue == null || textValue.isEmpty) {
                            return 'Email tidak boleh kosong!';
                          }
                          if (!EmailValidator.validate(textValue)) {
                            return 'Masukkan email yang valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomInputField(
                        labelText: 'No. Telepon',
                        hintText: 'Masukkan nomor telepon Anda',
                        controller: _phoneController,
                        validator: (textValue) {
                          if (textValue == null || textValue.isEmpty) {
                            return 'Nomor telepon tidak boleh kosong!';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomInputField(
                        labelText: 'Password',
                        hintText: 'Masukkan password Anda',
                        controller: _passwordController,
                        obscureText: true,
                        suffixIcon: true,
                        validator: (textValue) {
                          if (textValue == null || textValue.isEmpty) {
                            return 'Password tidak boleh kosong!';
                          }
                          if (textValue.length < 8) {
                            return 'Password minimal 8 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),
                      CustomFormButton(
                        innerText: 'Daftar',
                        onPressed: _handleSignupUser,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Sudah punya akun? ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xff939393),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            ),
                            child: const Text(
                              'Masuk',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xff748288),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSignupUser() async {
    if (_signupFormKey.currentState!.validate()) {
      // Check if email already exists
      final existingUser =
          await DatabaseHelper().getUserByEmail(_emailController.text);
      if (existingUser != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email already registered')));
        return;
      }

      String userId = DateTime.now().millisecondsSinceEpoch.toString();

      final user = UserModel(
        uid: userId,
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text, // Add password
        imagePath: _profileImage?.path,
      );

      await DatabaseHelper().insertUser(user);

      // Don't save currentUserId on signup, only on login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Registration successful! Please login.')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
