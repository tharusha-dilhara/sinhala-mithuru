// Basic Models
class StudentRank {
  final int studentId;
  final String name;
  final int level;
  final int totalScore;

  StudentRank({
    required this.studentId,
    required this.name,
    required this.level,
    required this.totalScore,
  });

  factory StudentRank.fromJson(Map<String, dynamic> json) {
    return StudentRank(
      studentId: json['student_id'] ?? 0,
      name: json['name'] ?? '',
      level: json['level'] ?? 0,
      totalScore: json['total_score'] ?? 0,
    );
  }
}

class SkillPerformance {
  final String componentType;
  final double averageScore;

  SkillPerformance({required this.componentType, required this.averageScore});

  factory SkillPerformance.fromJson(Map<String, dynamic> json) {
    return SkillPerformance(
      componentType: json['component_type'] ?? '',
      averageScore: (json['average_score'] ?? 0.0).toDouble(),
    );
  }
}

class TeacherDashboardSummary {
  final int totalStudents;
  final double classAverageLevel;
  final double assignmentCompletionRate;
  final List<String> strugglingStudents;
  final List<SkillPerformance> skillStats;

  TeacherDashboardSummary({
    required this.totalStudents,
    required this.classAverageLevel,
    required this.assignmentCompletionRate,
    required this.strugglingStudents,
    required this.skillStats,
  });

  factory TeacherDashboardSummary.fromJson(Map<String, dynamic> json) {
    return TeacherDashboardSummary(
      totalStudents: json['total_students'] ?? 0,
      classAverageLevel: (json['class_average_level'] ?? 0.0).toDouble(),
      assignmentCompletionRate: (json['assignment_completion_rate'] ?? 0.0)
          .toDouble(),
      strugglingStudents:
          (json['struggling_students'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      skillStats:
          (json['skill_stats'] as List<dynamic>?)
              ?.map((e) => SkillPerformance.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DifficultItem {
  final String itemName;
  final int failureCount;
  final double averageScore;

  DifficultItem({
    required this.itemName,
    required this.failureCount,
    required this.averageScore,
  });

  factory DifficultItem.fromJson(Map<String, dynamic> json) {
    return DifficultItem(
      itemName: json['item_name'] ?? '',
      failureCount: json['failure_count'] ?? 0,
      averageScore: (json['average_score'] ?? 0.0).toDouble(),
    );
  }
}

class ClassDifficultyAnalytics {
  final String componentType;
  final List<DifficultItem> topDifficultItems;

  ClassDifficultyAnalytics({
    required this.componentType,
    required this.topDifficultItems,
  });

  factory ClassDifficultyAnalytics.fromJson(Map<String, dynamic> json) {
    return ClassDifficultyAnalytics(
      componentType: json['component_type'] ?? '',
      topDifficultItems:
          (json['top_difficult_items'] as List<dynamic>?)
              ?.map((e) => DifficultItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

// --- Detail Report Models ---

class LearningCurvePoint {
  final String day;
  final double avgScore;

  LearningCurvePoint({required this.day, required this.avgScore});

  factory LearningCurvePoint.fromJson(Map<String, dynamic> json) {
    return LearningCurvePoint(
      day: json['day'] ?? '',
      avgScore: (json['avg_score'] ?? 0.0).toDouble(),
    );
  }
}

class ErrorSummary {
  final String component;
  final int failureCount;

  ErrorSummary({required this.component, required this.failureCount});

  factory ErrorSummary.fromJson(Map<String, dynamic> json) {
    return ErrorSummary(
      component: json['component'] ?? '',
      failureCount: json['failure_count'] ?? 0,
    );
  }
}

class StudentDetailedReport {
  final String studentName;
  final List<LearningCurvePoint> learningCurve;
  final List<ErrorSummary> errorSummary;
  final double attemptEfficiency;

  StudentDetailedReport({
    required this.studentName,
    required this.learningCurve,
    required this.errorSummary,
    required this.attemptEfficiency,
  });

  factory StudentDetailedReport.fromJson(Map<String, dynamic> json) {
    return StudentDetailedReport(
      studentName: json['student_name'] ?? '',
      learningCurve:
          (json['learning_curve'] as List<dynamic>?)
              ?.map((e) => LearningCurvePoint.fromJson(e))
              .toList() ??
          [],
      errorSummary:
          (json['error_summary'] as List<dynamic>?)
              ?.map((e) => ErrorSummary.fromJson(e))
              .toList() ??
          [],
      attemptEfficiency: (json['attempt_efficiency'] ?? 0.0).toDouble(),
    );
  }
}

// --- Assignment Models ---

class StudentAssignmentStatus {
  final String studentName;
  final String status;
  final String? completedAt;

  StudentAssignmentStatus({
    required this.studentName,
    required this.status,
    this.completedAt,
  });

  factory StudentAssignmentStatus.fromJson(Map<String, dynamic> json) {
    return StudentAssignmentStatus(
      studentName: json['student_name'] ?? '',
      status: json['status'] ?? '',
      completedAt: json['completed_at'],
    );
  }
}

class AssignmentDetailedReport {
  final int assignmentId;
  final String targetData;
  final String componentType;
  final String deadline;
  final int totalStudents;
  final int completedCount;
  final int missedCount;
  final int inProgressCount;
  final List<String> insights;
  final List<StudentAssignmentStatus> studentDetails;

  AssignmentDetailedReport({
    required this.assignmentId,
    required this.targetData,
    required this.componentType,
    required this.deadline,
    required this.totalStudents,
    required this.completedCount,
    required this.missedCount,
    required this.inProgressCount,
    required this.insights,
    required this.studentDetails,
  });

  factory AssignmentDetailedReport.fromJson(Map<String, dynamic> json) {
    return AssignmentDetailedReport(
      assignmentId: json['assignment_id'] ?? 0,
      targetData: json['target_data'] ?? '',
      componentType: json['component_type'] ?? '',
      deadline: json['deadline'] ?? '',
      totalStudents: json['total_students'] ?? 0,
      completedCount: json['completed_count'] ?? 0,
      missedCount: json['missed_count'] ?? 0,
      inProgressCount: json['in_progress_count'] ?? 0,
      insights:
          (json['insights'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      studentDetails:
          (json['student_details'] as List<dynamic>?)
              ?.map((e) => StudentAssignmentStatus.fromJson(e))
              .toList() ??
          [],
    );
  }
}
