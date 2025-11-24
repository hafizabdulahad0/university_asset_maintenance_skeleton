// File: lib/models/complaint_model.dart

class Complaint {
  int?    id;
  String  title;
  String  description;
  String? mediaPath;
  bool    mediaIsVideo;
  String  status;
  String? teacherId; // uuid
  String? staffId;   // uuid
  String? reportedBy; // uuid
  String  createdAt;
  String  updatedAt;

  Complaint({
    this.id,
    required this.title,
    required this.description,
    this.mediaPath,
    this.mediaIsVideo = false,
    required this.status,
    this.teacherId,
    this.staffId,
    this.reportedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert a Complaint into a map for the database
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'media_path': mediaPath,
      'media_is_video': mediaIsVideo,
      'status': status,
      'teacher_id': teacherId,
      'staff_id': staffId,
      'reported_by': reportedBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
    return map;
  }

  // Create a Complaint object from a map
  factory Complaint.fromMap(Map<String, dynamic> map) {
    return Complaint(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      mediaPath: map['media_path'] as String?,
      mediaIsVideo: (map['media_is_video'] as bool? ?? false),
      status: map['status'] as String,
      teacherId: map['teacher_id'] as String?,
      staffId: map['staff_id'] as String?,
      reportedBy: map['reported_by'] as String?,
      createdAt: (map['created_at'] ?? '') as String,
      updatedAt: (map['updated_at'] ?? '') as String,
    );
  }
}
