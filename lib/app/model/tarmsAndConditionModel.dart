class TermsandConditionsModel {
  bool? success;
  String? message;
  Data? data;

  TermsandConditionsModel({this.success, this.message, this.data});

  TermsandConditionsModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  int? id;
  String? settingType;
  String? content;
  String? lastUpdated;

  Data({this.id, this.settingType, this.content, this.lastUpdated});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    settingType = json['setting_type'];
    content = json['content'];
    lastUpdated = json['last_updated'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['setting_type'] = this.settingType;
    data['content'] = this.content;
    data['last_updated'] = this.lastUpdated;
    return data;
  }
}
