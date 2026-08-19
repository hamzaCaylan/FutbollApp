class Ball {
  Ball({this.x = 0.5, this.y = 0.5, this.inFront = true});

  double x;
  double y;
  bool inFront;

  Ball copy() => Ball(x: x, y: y, inFront: inFront);

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'inFront': inFront};

  factory Ball.fromJson(Map<String, dynamic> json) => Ball(
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    inFront: json['inFront'] as bool? ?? true,
  );
}
