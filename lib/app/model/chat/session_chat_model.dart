class SessonChatHistoryModel {
  bool? success;
  Session? session;
  List<Messages>? messages;
  Pagination? pagination;

  SessonChatHistoryModel(
      {this.success, this.session, this.messages, this.pagination});

  SessonChatHistoryModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    session =
    json['session'] != null ? new Session.fromJson(json['session']) : null;
    if (json['messages'] != null) {
      messages = <Messages>[];
      json['messages'].forEach((v) {
        messages!.add(new Messages.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.session != null) {
      data['session'] = this.session!.toJson();
    }
    if (this.messages != null) {
      data['messages'] = this.messages!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    return data;
  }
}

class Session {
  String? id;
  String? title;
  Persona? persona;

  Session({this.id, this.title, this.persona});

  Session.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    persona =
    json['persona'] != null ? new Persona.fromJson(json['persona']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    if (this.persona != null) {
      data['persona'] = this.persona!.toJson();
    }
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


// Add or update this in your Messages model class:

class Messages {
  int? id;
  String? content;
  bool? isUser;
  String? createdAt;
  String? messageType;
  bool? hasVoice;
  String? voice_file_url;
  String? transcript;

  Messages({
    this.id,
    this.content,
    this.isUser,
    this.createdAt,
    this.messageType,
    this.hasVoice,
    this.voice_file_url,
    this.transcript,
  });

  // Enhanced isVoice getter with comprehensive checks
  bool get isVoice {
    // Check multiple indicators for voice messages
    bool hasVoiceUrl = voice_file_url != null && voice_file_url!.isNotEmpty;
    bool hasVoiceType = messageType?.toLowerCase() == 'voice';
    bool hasVoiceFlag = hasVoice == true;
    bool hasTranscriptData = transcript != null && transcript!.isNotEmpty;

    // Also check content for voice indicators (in case backend sends different format)
    bool contentIndicatesVoice = false;
    if (content != null) {
      contentIndicatesVoice = content!.contains('voice_file_url') ||
          content!.contains('transcript');
    }

    bool result = hasVoiceUrl || hasVoiceType || hasVoiceFlag || hasTranscriptData || contentIndicatesVoice;

    // Debug logging for voice detection
    if (hasVoiceUrl || hasVoiceType || hasVoiceFlag || hasTranscriptData) {
      print("🎤 Voice message detected for ID $id:");
      print("  - hasVoiceUrl: $hasVoiceUrl (${voice_file_url})");
      print("  - hasVoiceType: $hasVoiceType (${messageType})");
      print("  - hasVoiceFlag: $hasVoiceFlag");
      print("  - hasTranscript: $hasTranscriptData");
      print("  - Final result: $result");
    }

    return result;
  }

  factory Messages.fromJson(Map<String, dynamic> json) {
    return Messages(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      content: json['content'],
      isUser: json['is_user'] ?? json['isUser'],
      createdAt: json['created_at'] ?? json['createdAt'],
      messageType: json['message_type'] ?? json['messageType'],
      hasVoice: json['has_voice'] ?? json['hasVoice'],
      voice_file_url: json['voice_file_url'] ?? json['voiceFileUrl'],
      transcript: json['transcript'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'is_user': isUser,
      'created_at': createdAt,
      'message_type': messageType,
      'has_voice': hasVoice,
      'voice_file_url': voice_file_url,
      'transcript': transcript,
    };
  }
}
class Pagination {
  int? page;
  int? pageSize;
  bool? hasMore;

  Pagination({this.page, this.pageSize, this.hasMore});

  Pagination.fromJson(Map<String, dynamic> json) {
    page = json['page'];
    pageSize = json['page_size'];
    hasMore = json['has_more'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['page'] = this.page;
    data['page_size'] = this.pageSize;
    data['has_more'] = this.hasMore;
    return data;
  }
}
