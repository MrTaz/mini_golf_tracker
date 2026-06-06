import 'package:flutter/widgets.dart';
import 'package:flutter_gravatar/flutter_gravatar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mini_golf_tracker/core/utils/utilities.dart';

class GravatarImageView extends StatefulWidget {
  const GravatarImageView(
      {super.key, required this.email, this.width, this.height = 0.0});

  final String email;
  final double? height;
  final double? width;

  @override
  State<GravatarImageView> createState() => _GravatarImageViewState();
}

class _GravatarImageViewState extends State<GravatarImageView> {
  final String defaultFriendAvatarImageStr =
      "assets/images/avatars_3d_avatar_28.png";

  late Future<String> _avatarFuture;

  @override
  void initState() {
    super.initState();
    _avatarFuture = getFriendAvatarImage();
  }

  @override
  void didUpdateWidget(GravatarImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.email != widget.email || oldWidget.width != widget.width) {
      setState(() {
        _avatarFuture = getFriendAvatarImage();
      });
    }
  }

  static final Map<String, String> _gravatarImgUrlCache = {};

  Future<String> getFriendAvatarImage() async {
    final email = widget.email;
    final width = widget.width;
    return Future.microtask(() async {
      Utilities.debugPrintWithCallerInfo('Getting gravatar data for $email');
      if (email.isNotEmpty) {
        if (_gravatarImgUrlCache.containsKey(email)) {
          return _gravatarImgUrlCache[email] as String;
        }
        String gravatarImgUrl = Gravatar(email).imageUrl(
            size: width?.toInt() ?? 120,
            defaultImage: defaultFriendAvatarImageStr);
        Utilities.debugPrintWithCallerInfo(
            'found gravatar image url for $email, $gravatarImgUrl');
        _gravatarImgUrlCache[email] = gravatarImgUrl;
        return gravatarImgUrl;
      }
      return defaultFriendAvatarImageStr;
    });
  }

  Widget _fadeInWidget(String imgUrlStr) {
    final width = widget.width;
    final height = widget.height;
    return FadeInImage(
        placeholder: AssetImage(defaultFriendAvatarImageStr),
        image: CachedNetworkImageProvider(imgUrlStr),
        imageErrorBuilder: (context, error, stackTrace) {
          return Image.asset(defaultFriendAvatarImageStr,
              width: width != 0.0 ? width : null,
              height: height != 0.0 ? height : null);
        },
        fit: BoxFit.cover,
        width: width != 0.0 ? width : null,
        height: height != 0.0 ? height : null);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: FutureBuilder<String>(
            future: _avatarFuture,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                return _fadeInWidget(snapshot.data.toString());
              }
              return Text(defaultFriendAvatarImageStr);
            }));
  }
}
