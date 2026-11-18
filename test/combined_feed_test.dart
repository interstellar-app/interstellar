import 'package:flutter_test/flutter_test.dart';
import 'package:interstellar/src/models/feed_item.dart';
import 'package:interstellar/src/models/post.dart';

Map<String, dynamic> content() => {
  'user': {
    'userId': 1,
    'username': 'alice',
    'isBot': false,
    'createdAt': '2026-01-01T00:00:00Z',
  },
  'magazine': {'magazineId': 1, 'name': 'test'},
  'entryId': 42,
  'postId': 42,
  'commentId': 42,
  'body': 'Example',
  'lang': 'en',
  'numComments': 0,
  'comments': 0,
  'isOc': false,
  'isAdult': false,
  'isPinned': false,
  'isLocked': false,
  'createdAt': '2026-01-01T00:00:00Z',
  'lastActive': '2026-01-01T00:00:00Z',
  'visibility': 'visible',
  'children': <dynamic>[],
  'childCount': 0,
};

void main() {
  final entryComment = content()..remove('postId');
  final reply = content()..remove('entryId');
  reply['lang'] = null;
  final comments = [
    {'entryComment': entryComment},
    {'postComment': reply},
  ];
  final pagination = {'currentPage': 1, 'maxPage': 2};

  test('Combined retains all four types even when IDs overlap', () {
    final page = FeedPage.fromMbinCombined({
      'items': [
        {'entry': content()},
        {'post': content()},
        ...comments,
      ],
      'pagination': pagination,
    });
    expect(page.items.length, 4);
    expect(page.items.map((item) => item.kind), FeedItemKind.values);
    expect(page.items.map((item) => item.key).toSet().length, 4);
    expect(page.nextPage, '2');
  });

  test('Comment-only pages retain their targets and pagination', () {
    final page = FeedPage.fromMbinCombined({
      'items': comments,
      'pagination': pagination,
    });
    expect(page.items.length, 2);
    expect(page.items[0].comment!.postType, PostType.thread);
    expect(page.items[1].comment!.postType, PostType.microblog);
    expect(page.items.every((item) => item.comment!.postId == 42), isTrue);
    expect(page.nextPage, '2');
  });
}
