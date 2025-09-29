// utils/error_handler.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rider_delivery/pages/Chats/Utils/constants.dart';

class ErrorHandler {
  
  // Handle Dio errors
  static String handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'การเชื่อมต่อหมดเวลา กรุณาลองใหม่';
        
      case DioExceptionType.badResponse:
        return _handleHttpError(error.response?.statusCode, error.response?.data);
        
      case DioExceptionType.cancel:
        return 'การเชื่อมต่อถูกยกเลิก';
        
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return AppConstants.ERROR_NETWORK;
        
      default:
        return 'เกิดข้อผิดพลาดที่ไม่คาดคิด';
    }
  }
  
  // Handle HTTP status codes
  static String _handleHttpError(int? statusCode, dynamic data) {
    String message = 'เกิดข้อผิดพลาด';
    
    // Try to extract message from response
    if (data is Map<String, dynamic> && data['message'] != null) {
      message = data['message'];
    }
    
    switch (statusCode) {
      case 400:
        return message.isNotEmpty ? message : 'ข้อมูลไม่ถูกต้อง';
      case 401:
        return AppConstants.ERROR_AUTH;
      case 403:
        return AppConstants.ERROR_PERMISSION;
      case 404:
        return 'ไม่พบข้อมูลที่ร้องขอ';
      case 422:
        return message.isNotEmpty ? message : 'ข้อมูลไม่ครบถ้วน';
      case 429:
        return 'ส่งคำขอเร็วเกินไป กรุณารอสักครู่';
      case 500:
      case 502:
      case 503:
      case 504:
        return AppConstants.ERROR_SERVER;
      default:
        return message.isNotEmpty ? message : 'เกิดข้อผิดพลาดในเซิร์ฟเวอร์';
    }
  }
  
  // Handle socket errors
  static String handleSocketError(dynamic error) {
    if (error.toString().contains('timeout')) {
      return 'การเชื่อมต่อหมดเวลา';
    } else if (error.toString().contains('denied')) {
      return 'ไม่มีสิทธิ์เข้าถึง';
    } else if (error.toString().contains('network')) {
      return AppConstants.ERROR_NETWORK;
    }
    return AppConstants.ERROR_SOCKET_DISCONNECT;
  }
  
  // Show error snackbar
  static void showError(String message, {
    Duration? duration,
    SnackPosition? position,
  }) {
    if (Get.context != null) {
      Get.snackbar(
        'ข้อผิดพลาด',
        message,
        snackPosition: position ?? SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: duration ?? const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    }
  }
  
  // Show success snackbar
  static void showSuccess(String message, {
    Duration? duration,
    SnackPosition? position,
  }) {
    if (Get.context != null) {
      Get.snackbar(
        'สำเร็จ',
        message,
        snackPosition: position ?? SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: duration ?? const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      );
    }
  }
  
  // Show warning snackbar
  static void showWarning(String message, {
    Duration? duration,
    SnackPosition? position,
  }) {
    if (Get.context != null) {
      Get.snackbar(
        'คำเตือน',
        message,
        snackPosition: position ?? SnackPosition.TOP,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
        duration: duration ?? const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.warning_outlined, color: Colors.white),
      );
    }
  }
  
  // Show info snackbar
  static void showInfo(String message, {
    Duration? duration,
    SnackPosition? position,
  }) {
    if (Get.context != null) {
      Get.snackbar(
        'ข้อมูล',
        message,
        snackPosition: position ?? SnackPosition.TOP,
        backgroundColor: Colors.blue.withOpacity(0.8),
        colorText: Colors.white,
        duration: duration ?? const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.info_outline, color: Colors.white),
      );
    }
  }
  
  // Log error for debugging
  static void logError(String tag, dynamic error, [StackTrace? stackTrace]) {
    print('[$tag] Error: $error');
    if (stackTrace != null) {
      print('[$tag] StackTrace: $stackTrace');
    }
  }
  
  // Handle and show error
  static void handleAndShowError(dynamic error, [String? tag]) {
    String message;
    
    if (error is DioException) {
      message = handleDioError(error);
    } else {
      message = error.toString();
    }
    
    if (tag != null) {
      logError(tag, error);
    }
    
    showError(message);
  }
}

// Custom exceptions
class ChatException implements Exception {
  final String message;
  final int? code;
  
  ChatException(this.message, [this.code]);
  
  @override
  String toString() => message;
}

class SocketException implements Exception {
  final String message;
  
  SocketException(this.message);
  
  @override
  String toString() => message;
}

class AuthenticationException implements Exception {
  final String message;
  
  AuthenticationException(this.message);
  
  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? errors;
  
  ValidationException(this.message, [this.errors]);
  
  @override
  String toString() => message;
}