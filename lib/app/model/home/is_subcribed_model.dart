class UserIsSubcribedModel {
  bool? success;
  String? message;
  String? timestamp;
  int? statusCode;
  Data? data;

  UserIsSubcribedModel(
      {this.success, this.message, this.timestamp, this.statusCode, this.data});

  UserIsSubcribedModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    timestamp = json['timestamp'];
    statusCode = json['status_code'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    data['timestamp'] = this.timestamp;
    data['status_code'] = this.statusCode;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  List<Personas>? personas;
  Personas? userSelectedPersona;
  bool? canSwitch;
  bool? isSubscribed;

  Data(
      {this.personas,
        this.userSelectedPersona,
        this.canSwitch,
        this.isSubscribed});

  Data.fromJson(Map<String, dynamic> json) {
    if (json['personas'] != null) {
      personas = <Personas>[];
      json['personas'].forEach((v) {
        personas!.add(new Personas.fromJson(v));
      });
    }
    userSelectedPersona = json['user_selected_persona'] != null
        ? new Personas.fromJson(json['user_selected_persona'])
        : null;
    canSwitch = json['can_switch'];
    isSubscribed = json['is_subscribed'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.personas != null) {
      data['personas'] = this.personas!.map((v) => v.toJson()).toList();
    }
    if (this.userSelectedPersona != null) {
      data['user_selected_persona'] = this.userSelectedPersona!.toJson();
    }
    data['can_switch'] = this.canSwitch;
    data['is_subscribed'] = this.isSubscribed;
    return data;
  }
}

class Personas {
  int? id;
  String? name;
  String? title;
  String? gender;
  String? personality;
  String? framework;
  String? approach;
  String? riskAversion;
  bool? locationAwareness;
  bool? federalContractorAwareness;
  String? systemPrompt;
  String? avatar;
  bool? isActive;
  String? createdAt;
  String? updatedAt;

  Personas(
      {this.id,
        this.name,
        this.title,
        this.gender,
        this.personality,
        this.framework,
        this.approach,
        this.riskAversion,
        this.locationAwareness,
        this.federalContractorAwareness,
        this.systemPrompt,
        this.avatar,
        this.isActive,
        this.createdAt,
        this.updatedAt});

  Personas.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    title = json['title'];
    gender = json['gender'];
    personality = json['personality'];
    framework = json['framework'];
    approach = json['approach'];
    riskAversion = json['risk_aversion'];
    locationAwareness = json['location_awareness'];
    federalContractorAwareness = json['federal_contractor_awareness'];
    systemPrompt = json['system_prompt'];
    avatar = json['avatar'];
    isActive = json['is_active'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['title'] = this.title;
    data['gender'] = this.gender;
    data['personality'] = this.personality;
    data['framework'] = this.framework;
    data['approach'] = this.approach;
    data['risk_aversion'] = this.riskAversion;
    data['location_awareness'] = this.locationAwareness;
    data['federal_contractor_awareness'] = this.federalContractorAwareness;
    data['system_prompt'] = this.systemPrompt;
    data['avatar'] = this.avatar;
    data['is_active'] = this.isActive;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
