// To parse this JSON data, do
//
//     final listJurusan = listJurusanFromJson(jsonString);

import 'dart:convert';

ListJurusan listJurusanFromJson(String str) =>
    ListJurusan.fromJson(json.decode(str));

String listJurusanToJson(ListJurusan data) => json.encode(data.toJson());

class ListJurusan {
  String message;
  List<Datum> data;

  ListJurusan({required this.message, required this.data});

  factory ListJurusan.fromJson(Map<String, dynamic> json) => ListJurusan(
    message: json["message"],
    data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class Datum {
  int id;
  String title;

  Datum({required this.id, required this.title});

  factory Datum.fromJson(Map<String, dynamic> json) =>
      Datum(id: json["id"], title: json["title"]);

  Map<String, dynamic> toJson() => {"id": id, "title": title};
}
