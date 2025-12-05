import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/screens/feed/post_comment.dart';
import 'package:interstellar/src/screens/feed/post_page.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_template.dart';
import 'package:provider/provider.dart';

class PostCommentScreen extends StatefulWidget {
  const PostCommentScreen(
    this.postType,
    this.commentId, {
    this.opUserId,
    super.key,
  });

  final PostType postType;
  final int commentId;
  final int? opUserId;

  @override
  State<PostCommentScreen> createState() => _PostCommentScreenState();
}

class _PostCommentScreenState extends State<PostCommentScreen> {
  CommentModel? _comment;

  @override
  void initState() {
    super.initState();

    context
        .read<AppController>()
        .api
        .comments
        .get(widget.postType, widget.commentId)
        .then(
          (value) {
            if (!mounted) return;
            setState(() {
              _comment = value;
            });
          }
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_comment == null) {
      return const LoadingTemplate();
    }

    final comment = _comment!;

    return Scaffold(
      appBar: AppBar(title: Text(l(context).commentBy(comment.user.name))),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: OverflowBar(
              alignment: MainAxisAlignment.center,
              overflowAlignment: OverflowBarAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: OutlinedButton(
                    onPressed: () => pushRoute(
                      context,
                      builder: (context) => PostPage(
                        postType: comment.postType,
                        postId: comment.postId,
                      ),
                    ),
                    child: Text(l(context).comment_openOriginalPost),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: OutlinedButton(
                    onPressed: comment.rootId != null
                        ? () => pushRoute(
                            context,
                            builder: (context) => PostCommentScreen(
                              comment.postType,
                              comment.rootId!,
                            ),
                          )
                        : null,
                    child: Text(l(context).comment_openRoot),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: OutlinedButton(
                    onPressed: comment.parentId != null
                        ? () => pushRoute(
                            context,
                            builder: (context) => PostCommentScreen(
                              comment.postType,
                              comment.parentId!,
                            ),
                          )
                        : null,
                    child: Text(l(context).comment_openParent),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: PostComment(
              comment,
              (newComment) => setState(() {
                _comment = newComment;
              }),
              opUserId: widget.opUserId,
            ),
          ),
        ],
      ),
    );
  }
}
