class personaChatModel {
  bool? success;
  Persona? persona;
  List<Sessions>? sessions;
  int? totalSessions;

  personaChatModel(
      {this.success, this.persona, this.sessions, this.totalSessions});

  personaChatModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    persona =
    json['persona'] != null ? new Persona.fromJson(json['persona']) : null;
    if (json['sessions'] != null) {
      sessions = <Sessions>[];
      json['sessions'].forEach((v) {
        sessions!.add(new Sessions.fromJson(v));
      });
    }
    totalSessions = json['total_sessions'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.persona != null) {
      data['persona'] = this.persona!.toJson();
    }
    if (this.sessions != null) {
      data['sessions'] = this.sessions!.map((v) => v.toJson()).toList();
    }
    data['total_sessions'] = this.totalSessions;
    return data;
  }
}

class Persona {
  int? id;
  String? name;
  String? title;
  String? avatar;

  Persona({this.id, this.name, this.title, this.avatar});

  Persona.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    title = json['title'];
    avatar = json['avatar'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['title'] = this.title;
    data['avatar'] = this.avatar;
    return data;
  }
}

class Sessions {
  String? id;
  String? title;
  int? messageCount;
  int? tokensUsed;
  String? lastMessage;
  String? createdAt;
  String? updatedAt;

  Sessions(
      {this.id,
        this.title,
        this.messageCount,
        this.tokensUsed,
        this.lastMessage,
        this.createdAt,
        this.updatedAt});

  Sessions.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    messageCount = json['message_count'];
    tokensUsed = json['tokens_used'];
    lastMessage = json['last_message'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['message_count'] = this.messageCount;
    data['tokens_used'] = this.tokensUsed;
    data['last_message'] = this.lastMessage;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

