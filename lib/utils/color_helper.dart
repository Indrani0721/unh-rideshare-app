import 'package:flutter/material.dart';

class ColorHelper {
  List<String> colorNames() {
    return [
      "White",
      "Black",
      "Grey",
      "Red",
      "Blue",
      "Green",
      "Yellow",
      "Orange",
      "Brown",
      "Silver",
    ];
  }

  Color resolveColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'black':
        return Colors.black;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'brown':
        return Colors.brown;
      case 'grey':
        return Colors.grey;
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'silver':
        return Colors.blueGrey;
      case 'white':
        return Colors.white;
      case 'yellow':
        return Colors.yellow;
      default:
        return Colors.transparent;
    }
  }
}
