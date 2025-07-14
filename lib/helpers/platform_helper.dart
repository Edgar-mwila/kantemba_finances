import 'package:flutter/foundation.dart';

bool get isWindows => defaultTargetPlatform == TargetPlatform.windows; 

// Zambian phone number validation
bool isValidZambianPhoneNumber(String phoneNumber) {
  // Remove any spaces, dashes, or other separators
  final cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  
  // Zambian phone number patterns:
  // +260 followed by 9 digits (mobile)
  // +260 followed by 2 digits + 7 digits (landline)
  // 260 followed by 9 digits (mobile without +)
  // 260 followed by 2 digits + 7 digits (landline without +)
  // 0 followed by 9 digits (local format)
  // 0 followed by 2 digits + 7 digits (local landline format)
  
  final patterns = [
    RegExp(r'^\+260[0-9]{9}$'), // +260 + 9 digits (mobile)
    RegExp(r'^\+260[0-9]{2}[0-9]{7}$'), // +260 + 2 digits + 7 digits (landline)
    RegExp(r'^260[0-9]{9}$'), // 260 + 9 digits (mobile without +)
    RegExp(r'^260[0-9]{2}[0-9]{7}$'), // 260 + 2 digits + 7 digits (landline without +)
    RegExp(r'^0[0-9]{9}$'), // 0 + 9 digits (local mobile)
    RegExp(r'^0[0-9]{2}[0-9]{7}$'), // 0 + 2 digits + 7 digits (local landline)
  ];
  
  return patterns.any((pattern) => pattern.hasMatch(cleaned));
}

// Format Zambian phone number for display
String formatZambianPhoneNumber(String phoneNumber) {
  final cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  
  // If it starts with 0, convert to +260 format
  if (cleaned.startsWith('0')) {
    return '+260${cleaned.substring(1)}';
  }
  
  // If it starts with 260 but no +, add +
  if (cleaned.startsWith('260') && !cleaned.startsWith('+260')) {
    return '+$cleaned';
  }
  
  // If it already has +260, return as is
  if (cleaned.startsWith('+260')) {
    return cleaned;
  }
  
  // If it's a 9-digit number, assume it's mobile and add +260
  if (cleaned.length == 9 && cleaned.startsWith('9')) {
    return '+260$cleaned';
  }
  
  // If it's a 9-digit number starting with other digits, assume it's landline
  if (cleaned.length == 9) {
    return '+260$cleaned';
  }
  
  // Return as is if it doesn't match any pattern
  return phoneNumber;
} 