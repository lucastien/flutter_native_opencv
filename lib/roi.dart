// To parse this JSON data, do
//
//     final roi = roiFromJson(jsonString);

import 'dart:convert';

List<Roi> roiFromJson(String str) =>
    List<Roi>.from(json.decode(str).map((x) => Roi.fromJson(x)));

String roiToJson(List<Roi> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Roi {
  Roi({
    this.module,
    this.regions,
  });

  String module;
  List<Region> regions;

  factory Roi.fromJson(Map<String, dynamic> json) => Roi(
        module: json["module"],
        regions:
            List<Region>.from(json["regions"].map((x) => Region.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "module": module,
        "regions": List<dynamic>.from(regions.map((x) => x.toJson())),
      };
}

class Region {
  Region({
    this.id,
    this.rect,
  });

  String id;
  List<int> rect;

  factory Region.fromJson(Map<String, dynamic> json) => Region(
        id: json["id"],
        rect: List<int>.from(json["rect"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "rect": List<dynamic>.from(rect.map((x) => x)),
      };
}
