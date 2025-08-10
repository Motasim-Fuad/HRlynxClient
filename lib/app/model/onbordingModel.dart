class OnbordingModel {
  bool? success;
  String? message;
  String? timestamp;
  int? statusCode;
  List<Data>? data;

  OnbordingModel(
      {this.success, this.message, this.timestamp, this.statusCode, this.data});

  OnbordingModel.fromJson(Map<dynamic, dynamic> json) {
    success = json['success'];
    message = json['message'];
    timestamp = json['timestamp'];
    statusCode = json['status_code'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    data['timestamp'] = this.timestamp;
    data['status_code'] = this.statusCode;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
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

  Data(
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

  Data.fromJson(Map<String, dynamic> json) {
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
