// utils/date_time_utils.dart
import 'package:intl/intl.dart';

class DateTimeUtils {
  // Thai month names
  static const List<String> thaiMonths = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
  ];
  
  static const List<String> thaiShortMonths = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
  ];
  
  static const List<String> thaiDays = [
    'วันจันทร์', 'วันอังคาร', 'วันพุธ', 'วันพฤหัสบดี', 
    'วันศุกร์', 'วันเสาร์', 'วันอาทิตย์'
  ];
  
  static const List<String> thaiShortDays = [
    'จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'
  ];

  // Format message time (used in chat)
  static String formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (messageDate == today) {
      // Today: show only time
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDate == yesterday) {
      // Yesterday: show "เมื่อวาน HH:mm"
      return 'เมื่อวาน ${DateFormat('HH:mm').format(dateTime)}';
    } else if (now.difference(dateTime).inDays < 7) {
      // This week: show day and time
      final dayIndex = dateTime.weekday - 1;
      return '${thaiShortDays[dayIndex]} ${DateFormat('HH:mm').format(dateTime)}';
    } else if (dateTime.year == now.year) {
      // This year: show date and time without year
      return '${dateTime.day} ${thaiShortMonths[dateTime.month - 1]} ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      // Other years: show full date and time
      return '${dateTime.day} ${thaiShortMonths[dateTime.month - 1]} ${dateTime.year} ${DateFormat('HH:mm').format(dateTime)}';
    }
  }
  
  // Format relative time (used in chat list)
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'เมื่อกี้นี้';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays == 1) {
      return 'เมื่อวาน';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks สัปดาห์ที่แล้ว';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months เดือนที่แล้ว';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ปีที่แล้ว';
    }
  }
  
  // Format full date in Thai
  static String formatFullDateThai(DateTime dateTime) {
    final dayIndex = dateTime.weekday - 1;
    return '${thaiDays[dayIndex]}ที่ ${dateTime.day} ${thaiMonths[dateTime.month - 1]} ${dateTime.year + 543}';
  }
  
  // Format short date in Thai
  static String formatShortDateThai(DateTime dateTime) {
    return '${dateTime.day} ${thaiShortMonths[dateTime.month - 1]} ${dateTime.year + 543}';
  }
  
  // Format time only
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
  
  // Format time with seconds
  static String formatTimeWithSeconds(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }
  
  // Format date for API (ISO format)
  static String formatForApi(DateTime dateTime) {
    return dateTime.toIso8601String();
  }
  
  // Parse date from API
  static DateTime parseFromApi(String dateString) {
    return DateTime.parse(dateString);
  }
  
  // Check if date is today
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return checkDate == today;
  }
  
  // Check if date is yesterday
  static bool isYesterday(DateTime dateTime) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final checkDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return checkDate == yesterday;
  }
  
  // Check if date is this week
  static bool isThisWeek(DateTime dateTime) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final checkDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    return checkDate.isAfter(startOfWeekDate.subtract(const Duration(days: 1))) &&
           checkDate.isBefore(startOfWeekDate.add(const Duration(days: 7)));
  }
  
  // Get greeting based on time
  static String getGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour < 12) {
      return 'สวัสดีตอนเช้า';
    } else if (hour < 17) {
      return 'สวัสดีตอนบ่าย';
    } else {
      return 'สวัสดีตอนเย็น';
    }
  }
  
  // Calculate age from birth date
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }
  
  // Get start of day
  static DateTime startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
  
  // Get end of day
  static DateTime endOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, 23, 59, 59, 999);
  }
  
  // Get duration string
  static String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours} ชั่วโมง ${duration.inMinutes % 60} นาที';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} นาที';
    } else {
      return '${duration.inSeconds} วินาที';
    }
  }
  
  // Format chat date separator
  static String formatChatDateSeparator(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (messageDate == today) {
      return 'วันนี้';
    } else if (messageDate == yesterday) {
      return 'เมื่อวาน';
    } else if (now.difference(dateTime).inDays < 7) {
      final dayIndex = dateTime.weekday - 1;
      return thaiDays[dayIndex];
    } else {
      return formatShortDateThai(dateTime);
    }
  }
}