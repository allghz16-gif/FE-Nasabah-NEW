// lib/services/api_service.dart
// Service untuk komunikasi dengan backend RESIK (backend_admin, port 5000)
//
// Tahap 1: daftar/login, profil, setor sampah + foto, riwayat setoran.
// Tahap 2 (belum ada di backend): tukar saldo, rekening, notifikasi, titik setor.
// Fungsi Tahap 2 di bawah dibuat kosong agar layar tetap terbuka tanpa error.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Emulator Android: 10.0.2.2. HP asli: jalankan dengan
  //   flutter run --dart-define=API_BASE_URL=http://IP-LAPTOP:5000/api
  static String get baseUrl {
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredUrl.isNotEmpty) return configuredUrl;
    return kIsWeb ? 'http://localhost:5000/api' : 'http://10.0.2.2:5000/api';
  }

  // ────────────────────────────────────────────────────────────
  // TOKEN MANAGEMENT
  // ────────────────────────────────────────────────────────────

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('resik_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('resik_token', token);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('resik_user', jsonEncode(user));
  }

  static Future<void> saveRememberMe(bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('resik_remember_me', remember);
  }

  static Future<void> saveRememberedLogin(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('resik_remembered_login', identifier);
  }

  static Future<void> clearRememberedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('resik_remembered_login');
  }

  static Future<String?> getRememberedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('resik_remembered_login');
  }

  static Future<bool?> getRememberMePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('resik_remember_me');
  }

  static Future<bool> shouldRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('resik_remember_me') ?? true;
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('resik_user');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static Future<String> _profilePhotoStorageKey() async {
    final user = await getUser();
    final userId = user?['id']?.toString();
    return 'resik_profile_photo_${userId ?? 'guest'}';
  }

  static Future<Uint8List?> getProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(await _profilePhotoStorageKey());
    if (encoded == null) return null;
    try {
      return base64Decode(encoded);
    } on FormatException {
      throw const FormatException('Foto profil tersimpan tidak valid.');
    }
  }

  static Future<void> saveProfilePhoto(Uint8List photo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await _profilePhotoStorageKey(), base64Encode(photo));
  }

  static Future<void> clearProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(await _profilePhotoStorageKey());
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('resik_token');
    await prefs.remove('resik_user');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ────────────────────────────────────────────────────────────
  // BASE REQUEST
  // ────────────────────────────────────────────────────────────

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Map<String, dynamic> _parseResponse(http.Response res) {
    dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } on FormatException {
      throw ApiException('Respons server tidak dapat dibaca', res.statusCode);
    }
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Format respons server tidak valid', res.statusCode);
    }
    final body = decoded;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw ApiException(
      body['message']?.toString() ?? 'Terjadi kesalahan',
      res.statusCode,
    );
  }

  static Future<Map<String, dynamic>> get(
    String path, {
    bool auth = true,
  }) async {
    final res = await http
        .get(Uri.parse('$baseUrl$path'), headers: await _headers(auth: auth))
        .timeout(const Duration(seconds: 20));
    return _parseResponse(res);
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: await _headers(auth: auth),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    return _parseResponse(res);
  }

  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final res = await http
        .put(
          Uri.parse('$baseUrl$path'),
          headers: await _headers(auth: auth),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    return _parseResponse(res);
  }

  /// Kirim form multipart (teks + satu file gambar).
  /// Content-Type jangan diisi manual: boundary diisi otomatis oleh http.
  static Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    required Uint8List fileBytes,
    required String fileName,
    bool auth = true,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    if (auth) {
      final token = await getToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields.addAll(fields);

    // backend hanya menerima image/jpeg dan image/png (dicek juga dari isi file)
    final isPng =
        fileBytes.length > 3 &&
        fileBytes[0] == 0x89 &&
        fileBytes[1] == 0x50 &&
        fileBytes[2] == 0x4E &&
        fileBytes[3] == 0x47;
    request.files.add(
      http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: fileName,
        contentType: MediaType('image', isPng ? 'png' : 'jpeg'),
      ),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final res = await http.Response.fromStream(streamed);
    return _parseResponse(res);
  }

  static List<Map<String, dynamic>> _rows(dynamic value) => value is List
      ? value.whereType<Map<String, dynamic>>().toList()
      : <Map<String, dynamic>>[];

  // ────────────────────────────────────────────────────────────
  // AUTH  (backend: /api/auth/nasabah/...)
  // ────────────────────────────────────────────────────────────

  /// Login nasabah dengan telepon/email + password
  static Future<Map<String, dynamic>> login({
    required String teleponAtauEmail,
    required String password,
    bool rememberMe = true,
  }) async {
    final result = await post('/auth/nasabah/login', {
      'telepon_atau_email': teleponAtauEmail,
      'password': password,
    }, auth: false);
    await _saveAuthResult(result, rememberMe: rememberMe);
    if (rememberMe) {
      await saveRememberedLogin(teleponAtauEmail.trim());
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('resik_remembered_login');
    }
    return result;
  }

  /// Registrasi nasabah baru (akun langsung muncul di web admin)
  static Future<Map<String, dynamic>> register({
    required String nama,
    required String telepon,
    required String password,
    String? email,
    String? alamat,
  }) async {
    final result = await post('/auth/nasabah/register', {
      'nama': nama,
      'telepon': telepon,
      'password': password,
      if (email != null) 'email': email,
      if (alamat != null) 'alamat': alamat,
    }, auth: false);
    await _saveAuthResult(result, rememberMe: true);
    return result;
  }

  static Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    return post('/auth/nasabah/password-reset/request', {
      'email': email.trim().toLowerCase(),
    }, auth: false);
  }

  static Future<Map<String, dynamic>> completePasswordReset({
    required String email,
    required String otp,
    required String password,
  }) async {
    return post('/auth/nasabah/password-reset/complete', {
      'email': email.trim().toLowerCase(),
      'otp': otp.trim(),
      'password': password,
    }, auth: false);
  }

  /// Backend admin membungkus hasil login: { data: { token, nasabah } }
  static Future<void> _saveAuthResult(
    Map<String, dynamic> result, {
    required bool rememberMe,
  }) async {
    final data = result['data'];
    final token = data is Map<String, dynamic> ? data['token'] : result['token'];
    final user = data is Map<String, dynamic> ? (data['nasabah'] ?? data) : null;
    if (token is! String || token.isEmpty || user is! Map<String, dynamic>) {
      throw ApiException('Respons autentikasi server tidak lengkap', 500);
    }
    await saveToken(token);
    await saveUser(user);
    await saveRememberMe(rememberMe);
  }

  // ────────────────────────────────────────────────────────────
  // PROFIL NASABAH  (backend: /api/app/me)
  // ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getProfilSaya() async {
    return get('/app/me');
  }

  static Future<Map<String, dynamic>> updateProfil({
    String? nama,
    String? alamat,
    String? email,
    String? nik,
    String? jenisTempat,
    String? alamatLengkap,
    String? rt,
    String? rw,
    String? kelurahan,
    String? kecamatan,
    String? kota,
    double? latitude,
    double? longitude,
  }) async {
    return put('/app/me', {
      if (nama != null) 'nama': nama,
      if (alamat != null) 'alamat': alamat,
      if (nik != null) 'nik': nik,
      if (jenisTempat != null) 'jenis_tempat': jenisTempat,
      if (rt != null) 'rt': rt,
      if (rw != null) 'rw': rw,
      if (kelurahan != null) 'kelurahan': kelurahan,
      if (kecamatan != null) 'kecamatan': kecamatan,
      if (kota != null) 'kota': kota,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
  }

  static Future<void> logoutNasabah() async {
    Object? requestError;
    try {
      await post('/auth/nasabah/logout', {});
    } catch (error) {
      requestError = error;
    } finally {
      await logout();
    }
    if (requestError != null) {
      throw ApiException(
        'Sesi di perangkat sudah dihapus, tetapi server gagal mengakhiri sesi: $requestError',
        0,
      );
    }
  }

  // ────────────────────────────────────────────────────────────
  // SETORAN  (backend: /api/app/setoran)
  // ────────────────────────────────────────────────────────────

  /// Riwayat setoran milik nasabah yang login.
  /// Field: id, kode, status (verifikasi/berhasil/ditolak), berat_kg,
  /// total_saldo, tanggal, jenis, bukti_timbangan, alasan_tolak.
  static Future<Map<String, dynamic>> getSetoranSaya({String? status}) async {
    return get('/app/setoran');
  }

  /// Kirim satu setoran berisi 1..n jenis sampah + foto bukti timbangan.
  /// items: [{ 'jenis_sampah_id': 1, 'berat': 2.5 }, ...]
  static Future<Map<String, dynamic>> kirimSetoran({
    required List<Map<String, dynamic>> items,
    required Uint8List buktiBytes,
    required String buktiNama,
    String? catatan,
  }) async {
    return postMultipart(
      '/app/setoran',
      fields: {
        'items': jsonEncode(items),
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      },
      fileField: 'bukti', // nama field harus "bukti"
      fileBytes: buktiBytes,
      fileName: buktiNama,
    );
  }

  // ────────────────────────────────────────────────────────────
  // JENIS SAMPAH & HARGA  (backend: /api/app/jenis-sampah, wajib login)
  // ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getJenisSampah() async {
    return get('/app/jenis-sampah');
  }

  // ────────────────────────────────────────────────────────────
  // DASHBOARD BERANDA
  // Backend belum punya endpoint dashboard, jadi dihitung di sini dari
  // data profil + setoran + jenis sampah.
  // ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDashboardSaya() async {
    final profil = (await getProfilSaya())['data'] as Map<String, dynamic>;
    final setoran = _rows((await getSetoranSaya())['data']);
    final jenis = _rows((await getJenisSampah())['data']);

    final now = DateTime.now();
    var totalKg = 0.0;
    var saldoMasukBulanIni = 0;
    final perBulan = <String, double>{};

    for (final s in setoran) {
      final status = '${s['status']}';
      final kg = num.tryParse('${s['total_berat']}')?.toDouble() ?? 0;
      final tanggal = DateTime.tryParse('${s['created_at']}')?.toLocal();

      if (status == 'berhasil') {
        totalKg += kg;
        if (tanggal != null &&
            tanggal.year == now.year &&
            tanggal.month == now.month) {
          saldoMasukBulanIni +=
              (num.tryParse('${s['total_nilai']}') ?? 0).round();
        }
      }
      if (status != 'ditolak' && tanggal != null) {
        final key = '${tanggal.year}-${tanggal.month}';
        perBulan[key] = (perBulan[key] ?? 0) + kg;
      }
    }

    return <String, dynamic>{
      'success': true,
      'data': <String, dynamic>{
        'profile': <String, dynamic>{
          'nama': profil['nama'],
          'saldo': profil['saldo'],
          'total_setoran': totalKg,
        },
        'summary': <String, dynamic>{
          'jumlah_transaksi': setoran.length,
          'saldo_masuk_bulan_ini': saldoMasukBulanIni,
          'notifikasi_belum_dibaca': 0,
        },
        'monthly_deposits': <Map<String, dynamic>>[
          for (final e in perBulan.entries)
            <String, dynamic>{
              'tahun': int.parse(e.key.split('-')[0]),
              'bulan': int.parse(e.key.split('-')[1]),
              'total_kg': e.value,
            },
        ],
        'recent_deposits': setoran.take(5).toList(),
        'recent_transactions': <Map<String, dynamic>>[],
        'prices': jenis
            .map((j) => <String, dynamic>{...j, 'satuan': 'kg'})
            .toList(),
        'drop_points': <Map<String, dynamic>>[],
      },
    };
  }

  // ────────────────────────────────────────────────────────────
  // TAHAP 2: belum ada di backend admin (dibuat kosong / pesan jelas)
  // ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getMetodePencairanSaya() async =>
      <String, dynamic>{'data': <dynamic>[]};

  static Future<Map<String, dynamic>> tambahMetodePencairan({
    required String metode,
    required String namaPemilik,
    required String nomorRekening,
  }) async {
    throw ApiException('Fitur rekening pencairan belum tersedia.', 501);
  }

  static Future<Map<String, dynamic>> jadikanMetodePencairanUtama(
    int id,
  ) async {
    throw ApiException('Fitur rekening pencairan belum tersedia.', 501);
  }

  static Future<Map<String, dynamic>> tarikSaldo({
    required int jumlah,
    required String metode,
    required String nomorTujuan,
  }) async {
    throw ApiException('Fitur tukar saldo belum tersedia.', 501);
  }

  static Future<Map<String, dynamic>> getRiwayatTransaksi({
    String? tipe,
  }) async => <String, dynamic>{'data': <dynamic>[]};

  static Future<Map<String, dynamic>> getNotifikasi() async =>
      <String, dynamic>{'data': <dynamic>[]};

  static Future<Map<String, dynamic>> tandaiNotifikasiBaca(int id) async =>
      <String, dynamic>{'success': true};

  static Future<Map<String, dynamic>> getTitikSetor() async =>
      <String, dynamic>{'data': <dynamic>[]};
}

// Custom exception
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => 'ApiException($statusCode): $message';
}