import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rider_delivery/APIs/baseAPI_URL/baseURL.dart';
import 'package:rider_delivery/APIs/middleware/authService.dart';

class ReviewsService {
  // ดึง token จาก SharedPreferences
  static Future<Map<String, String>> _getHeaders() async {
    final authService = AuthService(); // สร้าง instance ของ AuthService
    final hasValidToken = await authService.ensureValidToken();
    if (!hasValidToken) {
      // หาก token ไม่ถูกต้องหรือหมดอายุ ให้ส่ง headers พื้นฐาน (หรือคุณอาจโยน error แทน)
      return {'Content-Type': 'application/json'};
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ================ List Reviews Rider =================/reviews/for/riders
  // exports.listRiderReviews = async (req, res) => {
  //   const { user_id } = req.user || {};
  //   if (!user_id) return res.status(401).json({ error: 'Invalid token payload (no user_id)' });

  //   // ใช้ riderId จาก middleware ที่ดึงจาก token
  //   const riderId = req.riderId;
  //   const { limit, offset } = parsePage(req);

  //   const sql = `
  //     SELECT o.order_id, r.review_id, r.rating, r.comment, r.created_at,
  //            u.display_name AS reviewer_name, u.photo_url AS reviewer_photo, r.user_id
  //     FROM public.rider_reviews r
  //     JOIN public.users u ON u.user_id = r.user_id
  //     JOIN public.orders o ON o.order_id = r.order_id AND o.rider_id = r.rider_id
  //     WHERE r.rider_id = $1
  //     ORDER BY r.created_at DESC
  //     LIMIT $2 OFFSET $3
  //   `;

  //     // ดึงสรุปของ rider เพิ่มการดึงรีวิวแต่ละดาว 1-5 มีกี่รีวิว
  //     let summary;
  //     try {
  //         summary = await pool.query(
  //             `SELECT rp.rider_id, u.display_name AS rider_name, rp.rating AS rating_avg, rp.reviews_count,
  //               COUNT(*) FILTER (WHERE r.rating = 5) AS rating_5,
  //               COUNT(*) FILTER (WHERE r.rating = 4) AS rating_4,
  //               COUNT(*) FILTER (WHERE r.rating = 3) AS rating_3,
  //               COUNT(*) FILTER (WHERE r.rating = 2) AS rating_2,
  //               COUNT(*) FILTER (WHERE r.rating = 1) AS rating_1
  //              FROM public.rider_profiles rp
  //               JOIN public.users u ON u.user_id = rp.user_id
  //               LEFT JOIN public.rider_reviews r ON r.rider_id = rp.rider_id
  //               WHERE rp.rider_id = $1
  //               GROUP BY rp.rider_id, u.display_name, rp.rating, rp.reviews_count`,
  //             [riderId]
  //         );
  //     } catch (err) {
  //         return res.status(400).json({ error: 'Cannot fetch rider summary', detail: err.message });
  //     }

  //   try {
  //     const { rows } = await pool.query(sql, [riderId, limit, offset]);
  //     return res.json({
  //       ok: true,
  //       rider_summary: summary.rows[0],
  //       items: rows,
  //       paging: { limit, offset },
  //       authenticated_user: user_id
  //     });
  //   } catch (err) {
  //     return res.status(400).json({ error: 'Cannot list rider reviews', detail: err.message });
  //   }
  // };
  // เชื่อมต่อ API เพื่อดึงรีวิว
  Future<Map<String, dynamic>> fetchRiderReviews({
    int limit = 20,
    int offset = 0,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse(
      '${BaseAPI_URL.HostSocketURL}/reviews/for/riders?limit=$limit&offset=$offset',
    );

    final response = await http.get(url, headers: headers);
    print('RiderReviews URL: $url'); // Debug log
    print('RiderReviews status: ${response.statusCode}');
    print('RiderReviews response: ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'success': true,
        'message': 'ดึงรีวิวของไรเดอร์สำเร็จ',
        'data': data,
      };
    } else {
      final status = response.statusCode;
      return {
        'success': false,
        'message': 'Failed to fetch rider reviews',
        'statusCode': status,
        'authError': status == 401 || status == 403 || status == 404,
      };
    }
  }

}
// OUTPUT EXAMPLE
// {
//     "ok": true,
//     "rider_summary": {
//         "rider_id": 10,
//         "rider_name": "เย้ๆ123",
//         "rating_avg": "5.0",
//         "reviews_count": 2,
//         "rating_5": "2",
//         "rating_4": "0",
//         "rating_3": "0",
//         "rating_2": "0",
//         "rating_1": "0"
//     },
//     "items": [
//         {
//             "order_id": 204,
//             "review_id": 12,
//             "rating": 5,
//             "comment": "ทักทาย",
//             "created_at": "2025-10-05T14:39:13.709Z",
//             "reviewer_name": "Name ",
//             "reviewer_photo": "https://res.cloudinary.com/djqdn2zru/image/upload/v1758281188/Market-LOGO/omheznsanssc2cjii6ww.jpg",
//             "user_id": 36
//         },
//         {
//             "order_id": 205,
//             "review_id": 11,
//             "rating": 5,
//             "comment": "ส่งเร็วจัง",
//             "created_at": "2025-10-05T14:37:12.619Z",
//             "reviewer_name": "Name ",
//             "reviewer_photo": "https://res.cloudinary.com/djqdn2zru/image/upload/v1758281188/Market-LOGO/omheznsanssc2cjii6ww.jpg",
//             "user_id": 36
//         }
//     ],
//     "paging": {
//         "limit": 20,
//         "offset": 0
//     },
//     "authenticated_user": 35
// }