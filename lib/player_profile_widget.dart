import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

import 'gravatar_image_view.dart';
import 'player.dart';

class PlayerProfileWidget extends StatefulWidget {
  final Player player;
  final int? rank;
  final bool isSelected;

  const PlayerProfileWidget({super.key, required this.player, this.rank, required this.isSelected});

  @override
  PlayerProfileWidgetState createState() => PlayerProfileWidgetState();
}

class PlayerProfileWidgetState extends State<PlayerProfileWidget> {
  List<int> selectedPlayerIds = [];

  Color getRankBorderColor(int? currentRank) {
    currentRank ??= 99;
    switch (currentRank) {
      case 0:
        return const Color(0xFFDAA520);
      case 1:
        return const Color(0xFFC0C0C0);
      case 2:
        return const Color(0xFFECC5C0);
      default:
        return const Color(0xffeeeeee);
    }
  }

  ImageProvider getRankBackImg(int? currentRank) {
    currentRank ??= 99;
    switch (currentRank) {
      case 0:
        return Image.asset("assets/images/rank1.png").image;
      case 1:
        return Image.asset("assets/images/rank2.png").image;
      case 2:
        return Image.asset("assets/images/rank3.png").image;
      default:
        return Image.memory(kTransparentImage).image;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: getRankBorderColor(widget.rank), width: 2.0),
        color: Colors.white38,
        image: DecorationImage(
            alignment: const Alignment(0.8, 0.8), fit: BoxFit.none, scale: 3, image: getRankBackImg(widget.rank)),
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        boxShadow: const [
          BoxShadow(
            color: Colors.white10,
            blurRadius: 4,
            spreadRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minHeight: 150, minWidth: 100),
      height: MediaQuery.of(context).size.height * 0.15,
      width: MediaQuery.of(context).size.width * 0.2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
              child: CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: ClipOval(child: GravatarImageView(email: widget.player.email!)))),
          const SizedBox(
            height: 10.0,
          ),
          Padding(
              padding: const EdgeInsets.all(2.0),
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(widget.player.nickname,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24.0,
                      )))),
          if (widget.isSelected)
            const Chip(
              label: Icon(
                Icons.check,
                color: Colors.white,
              ),
              backgroundColor: Colors.green,
            ),
        ],
      ),
    );
  }
}
