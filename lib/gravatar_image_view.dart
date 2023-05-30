import 'package:flutter/widgets.dart';
import 'package:flutter_gravatar/flutter_gravatar.dart';

class GravatarImageView extends StatelessWidget {
  final String email;
  final double? height;
  final double? width;
  final String defaultFriendAvatarImageStr =
      "assets/images/avatars_3d_avatar_28.png";
  const GravatarImageView(
      {Key? key, required this.email, this.width, this.height = 0.0})
      : super(key: key);

  Future<String> getFriendAvatarImage() async {
    return Future.microtask(() async {
      debugPrint('Getting gravatar data for $email');
      if (email != "") {
        String gravatarImgUrl = Gravatar(email).imageUrl(
            size: width?.toInt() ?? 120,
            defaultImage: defaultFriendAvatarImageStr);
        debugPrint('found gravatar image url for $email, $gravatarImgUrl');
        return gravatarImgUrl;
      }
      return defaultFriendAvatarImageStr;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: FutureBuilder<String>(
            future: getFriendAvatarImage(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                return _fadeInWidget(snapshot.data.toString());
              }
              return Text(defaultFriendAvatarImageStr);
            }));
  }

  Widget _fadeInWidget(imgUrlStr) {
    return FadeInImage(
        placeholder: AssetImage(defaultFriendAvatarImageStr),
        image: NetworkImage(imgUrlStr),
        imageErrorBuilder: (context, error, stackTrace) {
          return Image.asset(defaultFriendAvatarImageStr,
              width: width != 0.0 ? width : null,
              height: height != 0.0 ? height : null);
        },
        fit: BoxFit.cover,
        width: width != 0.0 ? width : null,
        height: height != 0.0 ? height : null);
  }
}
