import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/gravatar_image_view.dart';
import 'package:mini_golf_tracker/player.dart';

class PlayerAvatarWidget extends StatelessWidget {
  const PlayerAvatarWidget({super.key, required this.player, this.radius});

  final Player player;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.teal,
      radius: radius,
      child: player.email == null || player.email!.isEmpty
          ? (player.nickname.isEmpty
              ? Image.asset('assets/images/avatars_3d_avatar_28.png')
              : Text(player.nickname[0].toUpperCase()))
          : ClipOval(child: GravatarImageView(email: player.email!)),
    );
  }
}
