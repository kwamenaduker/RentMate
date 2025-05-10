import 'package:flutter/material.dart';

/// Utility class for form field validation
class Validators {
  /// Validates email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    // Regular expression for email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  /// Validates password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one digit
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    // Check for at least one special character
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }
  
  /// Validates name input
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters long';
    }
    
    if (value.length > 50) {
      return 'Name cannot exceed 50 characters';
    }
    
    // Check for valid name characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value)) {
      return 'Name can only contain letters, spaces, hyphens and apostrophes';
    }
    
    return null;
  }
  
  /// Validates phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove any non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return 'Phone number must be between 10 and 15 digits';
    }
    
    return null;
  }
  
  /// Validates address input
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    
    if (value.length < 5) {
      return 'Address must be at least 5 characters long';
    }
    
    if (value.length > 200) {
      return 'Address cannot exceed 200 characters';
    }
    
    return null;
  }
  
  /// Validates property title
  static String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Title is required';
    }
    
    if (value.length < 5) {
      return 'Title must be at least 5 characters long';
    }
    
    if (value.length > 100) {
      return 'Title cannot exceed 100 characters';
    }
    
    return null;
  }
  
  /// Validates property description
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    
    if (value.length < 20) {
      return 'Description must be at least 20 characters long';
    }
    
    if (value.length > 1000) {
      return 'Description cannot exceed 1000 characters';
    }
    
    return null;
  }
  
  /// Validates price input
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    
    // Try to parse the value as a double
    try {
      final price = double.parse(value);
      
      if (price <= 0) {
        return 'Price must be greater than zero';
      }
      
      if (price > 1000000) {
        return 'Price cannot exceed 1,000,000';
      }
    } catch (e) {
      return 'Please enter a valid price';
    }
    
    return null;
  }
  
  /// Validates input field with custom length requirements
  static String? validateLength(String? value, String fieldName, int minLength, int maxLength) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }
    
    if (value.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    
    return null;
  }
  
  /// Sanitizes user input to prevent XSS or injection attacks
  static String sanitizeInput(String input) {
    // Remove script tags
    var sanitized = input.replaceAll(RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>'), '');
    
    // Remove other potentially dangerous HTML tags
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Escape HTML entities
    sanitized = sanitized.replaceAll('&', '&amp;')
                         .replaceAll('<', '&lt;')
                         .replaceAll('>', '&gt;')
                         .replaceAll('"', '&quot;')
                         .replaceAll("'", '&#x27;')
                         .replaceAll('/', '&#x2F;');
    
    return sanitized;
  }
}
