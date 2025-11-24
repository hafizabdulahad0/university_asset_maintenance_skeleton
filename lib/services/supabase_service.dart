import '../core/supabase_client.dart';
import '../models/user_model.dart' as app_models;
import '../models/complaint_model.dart';

class SupabaseService {
  // USERS
  static Future<String> upsertUserFromAuth(app_models.User user) async {
    final session = supabase.auth.currentSession;
    final uid = session?.user.id;
    if (uid == null) {
      throw Exception('No auth session');
    }
    await supabase.from('users').upsert({
      'id': uid,
      'auth_user_id': uid,
      'name': user.name,
      'email': user.email,
      'role': user.role,
      'created_at': user.createdAt,
      'updated_at': user.updatedAt,
    });
    return uid;
  }

  static Future<app_models.User?> getUserByEmail(String email) async {
    final data = await supabase.from('users').select().eq('email', email).maybeSingle();
    if (data == null) return null;
    return app_models.User.fromMap(data);
  }

  static Future<app_models.User?> getUserById(String id) async {
    final data = await supabase.from('users').select().eq('id', id).maybeSingle();
    if (data == null) return null;
    return app_models.User.fromMap(data);
  }

  static Future<int> updateUser(app_models.User user) async {
    final res = await supabase
        .from('users')
        .update(user.toMap())
        .eq('id', user.id!)
        .select('id');
    return res.length;
  }

  // COMPLAINTS
  static Complaint _fromDb(Map<String, dynamic> m) => Complaint.fromMap(m);

  static Future<int> insertComplaint(Complaint c) async {
    final session = supabase.auth.currentSession;
    final uid = session?.user.id;
    final res = await supabase.from('complaints').insert({
      'title': c.title,
      'description': c.description,
      'media_path': c.mediaPath,
      'media_is_video': c.mediaIsVideo,
      'status': c.status,
      'teacher_id': c.teacherId,
      'staff_id': c.staffId,
      'reported_by': uid,
      'created_at': c.createdAt,
      'updated_at': c.updatedAt,
    }).select('id').single();
    return (res['id'] as int);
  }

  static Future<List<Complaint>> getComplaintsByTeacher(String teacherId) async {
    final maps = await supabase.from('complaints').select().eq('teacher_id', teacherId);
    return maps.map<Complaint>(_fromDb).toList();
  }

  static Future<List<Complaint>> getUnassignedComplaints() async {
    final maps = await supabase.from('complaints').select().eq('status', 'unassigned');
    return maps.map<Complaint>(_fromDb).toList();
  }

  static Future<List<Complaint>> getAssignedComplaintsByStaff(String staffId) async {
    final maps = await supabase
        .from('complaints')
        .select()
        .eq('staff_id', staffId)
        .eq('status', 'assigned');
    return maps.map<Complaint>(_fromDb).toList();
  }

  static Future<List<Complaint>> getNeedsVerificationComplaints() async {
    final maps = await supabase.from('complaints').select().eq('status', 'needs_verification');
    return maps.map<Complaint>(_fromDb).toList();
  }

  static Future<List<Complaint>> getAllComplaints() async {
    final maps = await supabase.from('complaints').select();
    return maps.map<Complaint>(_fromDb).toList();
  }

  static Future<int> updateComplaint(Complaint c) async {
    final res = await supabase
        .from('complaints')
        .update(c.toMap())
        .eq('id', c.id!)
        .select('id');
    return res.length;
  }
}

