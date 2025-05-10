import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rent_mate/services/auth_service.dart';
import 'package:rent_mate/config/app_theme.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({Key? key}) : super(key: key);

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  
  String _status = 'Ready to test';
  bool _isLoading = false;
  File? _selectedImage;
  String? _uploadedImageUrl;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _testAuthentication() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _status = 'Testing authentication...';
      });
      
      try {
        final authService = context.read<AuthService>();
        
        // Test registration
        final userCredential = await authService.registerWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
          name: _nameController.text,
          phoneNumber: _phoneController.text,
        );
        
        setState(() {
          _status = 'Registration successful! User ID: ${userCredential?.user?.uid ?? 'N/A'}';
        });
        
        // Test sign out
        await Future.delayed(const Duration(seconds: 2));
        await authService.signOut();
        
        setState(() {
          _status += '\nSignout successful';
        });
        
        // Test sign in
        await Future.delayed(const Duration(seconds: 2));
        final signInCredential = await authService.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        
        setState(() {
          _status += '\nSign in successful! User ID: ${signInCredential?.user?.uid ?? 'N/A'}';
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _status = 'Authentication error: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _testFirestore() async {
    if (context.read<AuthService>().currentUser == null) {
      setState(() {
        _status = 'Please authenticate first';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _status = 'Testing Firestore...';
    });
    
    try {
      final user = context.read<AuthService>().currentUser!;
      
      // Test writing to Firestore
      final testDoc = {
        'test_field': 'Test value',
        'timestamp': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('test_collection').doc(user.uid).set(testDoc);
      
      setState(() {
        _status = 'Firestore write successful';
      });
      
      // Test reading from Firestore
      await Future.delayed(const Duration(seconds: 2));
      final docSnapshot = await _firestore.collection('test_collection').doc(user.uid).get();
      
      if (docSnapshot.exists) {
        setState(() {
          _status += '\nFirestore read successful: ${docSnapshot.data()}';
        });
      } else {
        setState(() {
          _status += '\nFirestore read failed: Document does not exist';
        });
      }
      
      // Test deleting from Firestore
      await Future.delayed(const Duration(seconds: 2));
      await _firestore.collection('test_collection').doc(user.uid).delete();
      
      setState(() {
        _status += '\nFirestore delete successful';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Firestore error: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _status = 'Image selected: ${image.path}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error picking image: $e';
      });
    }
  }
  
  Future<void> _testStorage() async {
    if (_selectedImage == null) {
      setState(() {
        _status = 'Please select an image first';
      });
      return;
    }
    
    if (context.read<AuthService>().currentUser == null) {
      setState(() {
        _status = 'Please authenticate first';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _status = 'Testing Firebase Storage...';
    });
    
    try {
      final user = context.read<AuthService>().currentUser!;
      
      // Create a unique filename
      final String fileName = 'test_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Create a reference to the file location
      final Reference ref = _storage.ref().child('test/${user.uid}/$fileName');
      
      // Upload the file
      final UploadTask uploadTask = ref.putFile(_selectedImage!);
      
      // Get download URL once upload completes
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      setState(() {
        _uploadedImageUrl = downloadUrl;
        _status = 'Storage upload successful\nURL: $downloadUrl';
      });
      
      // Test deleting the file
      await Future.delayed(const Duration(seconds: 2));
      await ref.delete();
      
      setState(() {
        _status += '\nStorage delete successful';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Storage error: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status display
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(_status),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Authentication test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Authentication Test',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'test@example.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter at least 6 characters',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          hintText: 'John Doe',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '+1234567890',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _testAuthentication,
                        child: const Text('Test Authentication'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Firestore test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Firestore Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('This will test writing, reading, and deleting a document in Firestore.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testFirestore,
                      child: const Text('Test Firestore'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Storage test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Storage Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('This will test uploading and deleting an image in Firebase Storage.'),
                    const SizedBox(height: 16),
                    if (_selectedImage != null)
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _pickImage,
                          child: const Text('Pick Image'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _testStorage,
                          child: const Text('Test Storage'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Current user info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current User Info',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<User?>(
                      builder: (context, user, child) {
                        if (user == null) {
                          return const Text('No user signed in');
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User ID: ${user.uid}'),
                            Text('Email: ${user.email}'),
                            Text('Email verified: ${user.emailVerified}'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
