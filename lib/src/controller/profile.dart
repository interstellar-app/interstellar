import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:interstellar/src/api/comments.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/screens/feed/feed_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/actions.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

enum OpenLinksIn { inAppBrowser, externalBrowser }

/// Profile class where all fields are required.
@freezed
class ProfileRequired with _$ProfileRequired {
  const ProfileRequired._();

  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory ProfileRequired({
    // If the autoSwitchAccount key is ever changed, be sure to update the AppController code that removes accounts, which references this key.
    required String? autoSwitchAccount,
    // Behavior settings
    required String defaultCreateLanguage,
    required bool useAccountLanguageFilter,
    required List<String> customLanguageFilter,
    required bool disableTabSwiping,
    required bool askBeforeUnsubscribing,
    required bool askBeforeDeleting,
    required bool autoPlayVideos,
    required bool hapticFeedback,
    required bool autoTranslate,
    required bool markThreadsReadOnScroll,
    required bool markMicroblogsReadOnScroll,
    // Display settings
    required String appLanguage,
    required ThemeMode themeMode,
    required FlexScheme colorScheme,
    required bool enableTrueBlack,
    required bool compactMode,
    required bool hideActionButtons,
    required bool hideFeedUIOnScroll,
    required double globalTextScale,
    required bool alwaysShowInstance,
    required bool coverMediaMarkedSensitive,
    required bool fullImageSizeThreads,
    required bool fullImageSizeMicroblogs,
    // Feed defaults
    required FeedView feedDefaultView,
    required FeedSource feedDefaultFilter,
    required FeedSort feedDefaultThreadsSort,
    required FeedSort feedDefaultMicroblogSort,
    required FeedSort feedDefaultTimelineSort,
    required FeedSort feedDefaultExploreSort,
    required CommentSort feedDefaultCommentSort,
    required bool feedDefaultHideReadPosts,
    // Feed actions
    required ActionLocation feedActionBackToTop,
    required ActionLocation feedActionCreateNew,
    required ActionLocation feedActionExpandFab,
    required ActionLocation feedActionRefresh,
    required ActionLocationWithTabs feedActionSetFilter,
    required ActionLocation feedActionSetSort,
    required ActionLocationWithTabs feedActionSetView,
    required ActionLocation feedActionHideReadPosts,
    // Swipe Actions
    required bool enableSwipeActions,
    required SwipeAction swipeActionLeftShort,
    required SwipeAction swipeActionLeftLong,
    required SwipeAction swipeActionRightShort,
    required SwipeAction swipeActionRightLong,
    required double swipeActionThreshold,
    // Filter list activations
    required Map<String, bool> filterLists,
  }) = _ProfileRequired;

  factory ProfileRequired.fromJson(JsonMap json) =>
      _$ProfileRequiredFromJson(json);

  factory ProfileRequired.fromOptional(
    ProfileOptional? profile,
  ) => ProfileRequired(
    autoSwitchAccount: profile?.autoSwitchAccount,
    defaultCreateLanguage:
        profile?.defaultCreateLanguage ?? defaultProfile.defaultCreateLanguage,
    useAccountLanguageFilter:
        profile?.useAccountLanguageFilter ??
        defaultProfile.useAccountLanguageFilter,
    customLanguageFilter:
        profile?.customLanguageFilter ?? defaultProfile.customLanguageFilter,
    disableTabSwiping:
        profile?.disableTabSwiping ?? defaultProfile.disableTabSwiping,
    askBeforeUnsubscribing:
        profile?.askBeforeUnsubscribing ??
        defaultProfile.askBeforeUnsubscribing,
    askBeforeDeleting:
        profile?.askBeforeDeleting ?? defaultProfile.askBeforeDeleting,
    autoPlayVideos: profile?.autoPlayVideos ?? defaultProfile.autoPlayVideos,
    hapticFeedback: profile?.hapticFeedback ?? defaultProfile.hapticFeedback,
    autoTranslate: profile?.autoTranslate ?? defaultProfile.autoTranslate,
    markThreadsReadOnScroll:
        profile?.markThreadsReadOnScroll ??
        defaultProfile.markThreadsReadOnScroll,
    markMicroblogsReadOnScroll:
        profile?.markMicroblogsReadOnScroll ??
        defaultProfile.markMicroblogsReadOnScroll,
    appLanguage: profile?.appLanguage ?? defaultProfile.appLanguage,
    themeMode: profile?.themeMode ?? defaultProfile.themeMode,
    colorScheme: profile?.colorScheme ?? defaultProfile.colorScheme,
    enableTrueBlack: profile?.enableTrueBlack ?? defaultProfile.enableTrueBlack,
    compactMode: profile?.compactMode ?? defaultProfile.compactMode,
    hideActionButtons:
        profile?.hideActionButtons ?? defaultProfile.hideActionButtons,
    hideFeedUIOnScroll:
        profile?.hideFeedUIOnScroll ?? defaultProfile.hideFeedUIOnScroll,
    globalTextScale: profile?.globalTextScale ?? defaultProfile.globalTextScale,
    alwaysShowInstance:
        profile?.alwaysShowInstance ?? defaultProfile.alwaysShowInstance,
    coverMediaMarkedSensitive:
        profile?.coverMediaMarkedSensitive ??
        defaultProfile.coverMediaMarkedSensitive,
    fullImageSizeThreads:
        profile?.fullImageSizeThreads ?? defaultProfile.fullImageSizeThreads,
    fullImageSizeMicroblogs:
        profile?.fullImageSizeMicroblogs ??
        defaultProfile.fullImageSizeMicroblogs,
    feedDefaultView: profile?.feedDefaultView ?? defaultProfile.feedDefaultView,
    feedDefaultFilter:
        profile?.feedDefaultFilter ?? defaultProfile.feedDefaultFilter,
    feedDefaultThreadsSort:
        profile?.feedDefaultThreadsSort ??
        defaultProfile.feedDefaultThreadsSort,
    feedDefaultMicroblogSort:
        profile?.feedDefaultMicroblogSort ??
        defaultProfile.feedDefaultMicroblogSort,
    feedDefaultTimelineSort: profile?.feedDefaultTimelineSort ?? defaultProfile.feedDefaultTimelineSort,
    feedDefaultExploreSort:
        profile?.feedDefaultExploreSort ??
        defaultProfile.feedDefaultExploreSort,
    feedDefaultCommentSort:
        profile?.feedDefaultCommentSort ??
        defaultProfile.feedDefaultCommentSort,
    feedDefaultHideReadPosts:
        profile?.feedDefaultHideReadPosts ??
        defaultProfile.feedDefaultHideReadPosts,
    feedActionBackToTop:
        profile?.feedActionBackToTop ?? defaultProfile.feedActionBackToTop,
    feedActionCreateNew:
        profile?.feedActionCreateNew ?? defaultProfile.feedActionCreateNew,
    feedActionExpandFab:
        profile?.feedActionExpandFab ?? defaultProfile.feedActionExpandFab,
    feedActionRefresh:
        profile?.feedActionRefresh ?? defaultProfile.feedActionRefresh,
    feedActionSetFilter:
        profile?.feedActionSetFilter ?? defaultProfile.feedActionSetFilter,
    feedActionSetSort:
        profile?.feedActionSetSort ?? defaultProfile.feedActionSetSort,
    feedActionSetView:
        profile?.feedActionSetView ?? defaultProfile.feedActionSetView,
    feedActionHideReadPosts:
        profile?.feedActionHideReadPosts ??
        defaultProfile.feedActionHideReadPosts,
    enableSwipeActions:
        profile?.enableSwipeActions ?? defaultProfile.enableSwipeActions,
    swipeActionLeftShort:
        profile?.swipeActionLeftShort ?? defaultProfile.swipeActionLeftShort,
    swipeActionLeftLong:
        profile?.swipeActionLeftLong ?? defaultProfile.swipeActionLeftLong,
    swipeActionRightShort:
        profile?.swipeActionRightShort ?? defaultProfile.swipeActionRightShort,
    swipeActionRightLong:
        profile?.swipeActionRightLong ?? defaultProfile.swipeActionRightLong,
    swipeActionThreshold:
        profile?.swipeActionThreshold ?? defaultProfile.swipeActionThreshold,
    filterLists: profile?.filterLists ?? defaultProfile.filterLists,
  );

  static const defaultProfile = ProfileRequired(
    autoSwitchAccount: null,
    defaultCreateLanguage: 'en',
    useAccountLanguageFilter: true,
    customLanguageFilter: [],
    disableTabSwiping: false,
    askBeforeUnsubscribing: false,
    askBeforeDeleting: true,
    autoPlayVideos: false,
    hapticFeedback: true,
    autoTranslate: false,
    markThreadsReadOnScroll: false,
    markMicroblogsReadOnScroll: false,
    appLanguage: '',
    themeMode: ThemeMode.system,
    colorScheme: FlexScheme.custom,
    enableTrueBlack: false,
    compactMode: false,
    hideActionButtons: false,
    hideFeedUIOnScroll: false,
    globalTextScale: 1,
    alwaysShowInstance: false,
    coverMediaMarkedSensitive: true,
    fullImageSizeThreads: false,
    fullImageSizeMicroblogs: true,
    feedDefaultView: FeedView.threads,
    feedDefaultFilter: FeedSource.subscribed,
    feedDefaultThreadsSort: FeedSort.hot,
    feedDefaultMicroblogSort: FeedSort.hot,
    feedDefaultTimelineSort: FeedSort.hot,
    feedDefaultExploreSort: FeedSort.newest,
    feedDefaultCommentSort: CommentSort.hot,
    feedDefaultHideReadPosts: false,
    feedActionBackToTop: ActionLocation.fabMenu,
    feedActionCreateNew: ActionLocation.fabMenu,
    feedActionExpandFab: ActionLocation.fabTap,
    feedActionRefresh: ActionLocation.fabMenu,
    feedActionSetFilter: ActionLocationWithTabs.tabs,
    feedActionSetSort: ActionLocation.appBar,
    feedActionSetView: ActionLocationWithTabs.appBar,
    feedActionHideReadPosts: ActionLocation.fabMenu,
    enableSwipeActions: false,
    swipeActionLeftShort: SwipeAction.upvote,
    swipeActionLeftLong: SwipeAction.boost,
    swipeActionRightShort: SwipeAction.bookmark,
    swipeActionRightLong: SwipeAction.reply,
    swipeActionThreshold: 0.20,
    filterLists: {},
  );
}

/// Profile class where all fields are optional.
@freezed
class ProfileOptional with _$ProfileOptional {
  const ProfileOptional._();

  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory ProfileOptional({
    required String? autoSwitchAccount,
    // Behavior settings
    required String? defaultCreateLanguage,
    required bool? useAccountLanguageFilter,
    required List<String>? customLanguageFilter,
    required bool? disableTabSwiping,
    required bool? askBeforeUnsubscribing,
    required bool? askBeforeDeleting,
    required bool? autoPlayVideos,
    required bool? hapticFeedback,
    required bool? autoTranslate,
    required bool? markThreadsReadOnScroll,
    required bool? markMicroblogsReadOnScroll,
    // Display settings
    required String? appLanguage,
    required ThemeMode? themeMode,
    required FlexScheme? colorScheme,
    required bool? enableTrueBlack,
    required bool? compactMode,
    required bool? hideActionButtons,
    required bool? hideFeedUIOnScroll,
    required double? globalTextScale,
    required bool? alwaysShowInstance,
    required bool? coverMediaMarkedSensitive,
    required bool? fullImageSizeThreads,
    required bool? fullImageSizeMicroblogs,
    // Feed defaults
    required FeedView? feedDefaultView,
    required FeedSource? feedDefaultFilter,
    required FeedSort? feedDefaultThreadsSort,
    required FeedSort? feedDefaultMicroblogSort,
    required FeedSort? feedDefaultTimelineSort,
    required FeedSort? feedDefaultExploreSort,
    required CommentSort? feedDefaultCommentSort,
    required bool? feedDefaultHideReadPosts,
    // Feed actions
    required ActionLocation? feedActionBackToTop,
    required ActionLocation? feedActionCreateNew,
    required ActionLocation? feedActionExpandFab,
    required ActionLocation? feedActionRefresh,
    required ActionLocationWithTabs? feedActionSetFilter,
    required ActionLocation? feedActionSetSort,
    required ActionLocationWithTabs? feedActionSetView,
    required ActionLocation? feedActionHideReadPosts,
    required bool? enableSwipeActions,
    required SwipeAction? swipeActionLeftShort,
    required SwipeAction? swipeActionLeftLong,
    required SwipeAction? swipeActionRightShort,
    required SwipeAction? swipeActionRightLong,
    required double? swipeActionThreshold,
    // Filter list activations
    required Map<String, bool>? filterLists,
  }) = _ProfileOptional;

  factory ProfileOptional.fromJson(JsonMap json) =>
      _$ProfileOptionalFromJson(json);

  static const nullProfile = ProfileOptional(
    autoSwitchAccount: null,
    defaultCreateLanguage: null,
    useAccountLanguageFilter: null,
    customLanguageFilter: null,
    disableTabSwiping: null,
    askBeforeUnsubscribing: null,
    askBeforeDeleting: null,
    autoPlayVideos: null,
    hapticFeedback: null,
    autoTranslate: null,
    markThreadsReadOnScroll: null,
    markMicroblogsReadOnScroll: null,
    appLanguage: null,
    themeMode: null,
    colorScheme: null,
    enableTrueBlack: null,
    compactMode: null,
    hideActionButtons: null,
    hideFeedUIOnScroll: null,
    globalTextScale: null,
    alwaysShowInstance: null,
    coverMediaMarkedSensitive: null,
    fullImageSizeThreads: null,
    fullImageSizeMicroblogs: null,
    feedDefaultView: null,
    feedDefaultFilter: null,
    feedDefaultThreadsSort: null,
    feedDefaultMicroblogSort: null,
    feedDefaultTimelineSort: null,
    feedDefaultExploreSort: null,
    feedDefaultCommentSort: null,
    feedDefaultHideReadPosts: null,
    feedActionBackToTop: null,
    feedActionCreateNew: null,
    feedActionExpandFab: null,
    feedActionRefresh: null,
    feedActionSetFilter: null,
    feedActionSetSort: null,
    feedActionSetView: null,
    feedActionHideReadPosts: null,
    enableSwipeActions: null,
    swipeActionLeftShort: null,
    swipeActionLeftLong: null,
    swipeActionRightShort: null,
    swipeActionRightLong: null,
    swipeActionThreshold: null,
    filterLists: null,
  );

  ProfileOptional merge(ProfileOptional? other) {
    if (other == null) return this;

    return ProfileOptional(
      autoSwitchAccount: other.autoSwitchAccount,
      defaultCreateLanguage:
          other.defaultCreateLanguage ?? defaultCreateLanguage,
      useAccountLanguageFilter:
          other.useAccountLanguageFilter ?? useAccountLanguageFilter,
      customLanguageFilter: other.customLanguageFilter ?? customLanguageFilter,
      disableTabSwiping: other.disableTabSwiping ?? disableTabSwiping,
      askBeforeUnsubscribing:
          other.askBeforeUnsubscribing ?? askBeforeUnsubscribing,
      askBeforeDeleting: other.askBeforeDeleting ?? askBeforeDeleting,
      autoPlayVideos: other.autoPlayVideos ?? autoPlayVideos,
      hapticFeedback: other.hapticFeedback ?? hapticFeedback,
      autoTranslate: other.autoTranslate ?? autoTranslate,
      markThreadsReadOnScroll:
          other.markThreadsReadOnScroll ?? markThreadsReadOnScroll,
      markMicroblogsReadOnScroll:
          other.markMicroblogsReadOnScroll ?? markMicroblogsReadOnScroll,
      appLanguage: other.appLanguage ?? appLanguage,
      themeMode: other.themeMode ?? themeMode,
      colorScheme: other.colorScheme ?? colorScheme,
      enableTrueBlack: other.enableTrueBlack ?? enableTrueBlack,
      compactMode: other.compactMode ?? compactMode,
      hideActionButtons: other.hideActionButtons ?? hideActionButtons,
      hideFeedUIOnScroll: other.hideFeedUIOnScroll ?? hideFeedUIOnScroll,
      globalTextScale: other.globalTextScale ?? globalTextScale,
      alwaysShowInstance: other.alwaysShowInstance ?? alwaysShowInstance,
      coverMediaMarkedSensitive:
          other.coverMediaMarkedSensitive ?? coverMediaMarkedSensitive,
      fullImageSizeThreads: other.fullImageSizeThreads ?? fullImageSizeThreads,
      fullImageSizeMicroblogs:
          other.fullImageSizeMicroblogs ?? fullImageSizeMicroblogs,
      feedDefaultView: other.feedDefaultView ?? feedDefaultView,
      feedDefaultFilter: other.feedDefaultFilter ?? feedDefaultFilter,
      feedDefaultThreadsSort:
          other.feedDefaultThreadsSort ?? feedDefaultThreadsSort,
      feedDefaultMicroblogSort:
          other.feedDefaultMicroblogSort ?? feedDefaultMicroblogSort,
      feedDefaultTimelineSort: other.feedDefaultTimelineSort ?? feedDefaultTimelineSort,
      feedDefaultExploreSort:
          other.feedDefaultExploreSort ?? feedDefaultExploreSort,
      feedDefaultCommentSort:
          other.feedDefaultCommentSort ?? feedDefaultCommentSort,
      feedDefaultHideReadPosts:
          other.feedDefaultHideReadPosts ?? feedDefaultHideReadPosts,
      feedActionBackToTop:
          other.feedActionBackToTop ?? this.feedActionBackToTop,
      feedActionCreateNew:
          other.feedActionCreateNew ?? this.feedActionCreateNew,
      feedActionExpandFab:
          other.feedActionExpandFab ?? this.feedActionExpandFab,
      feedActionRefresh: other.feedActionRefresh ?? this.feedActionRefresh,
      feedActionSetFilter:
          other.feedActionSetFilter ?? this.feedActionSetFilter,
      feedActionSetSort: other.feedActionSetSort ?? this.feedActionSetSort,
      feedActionSetView: other.feedActionSetView ?? this.feedActionSetView,
      feedActionHideReadPosts:
          other.feedActionHideReadPosts ?? this.feedActionHideReadPosts,
      enableSwipeActions: other.enableSwipeActions ?? this.enableSwipeActions,
      swipeActionLeftShort:
          other.swipeActionLeftShort ?? this.swipeActionLeftShort,
      swipeActionLeftLong:
          other.swipeActionLeftLong ?? this.swipeActionLeftLong,
      swipeActionRightShort:
          other.swipeActionRightShort ?? this.swipeActionRightShort,
      swipeActionRightLong:
          other.swipeActionRightLong ?? this.swipeActionRightLong,
      swipeActionThreshold:
          other.swipeActionThreshold ?? this.swipeActionThreshold,
      filterLists: filterLists != null && other.filterLists != null
          ? {...filterLists!, ...other.filterLists!}
          : other.filterLists ?? filterLists,
    );
  }

  ProfileOptional cleanupActions(
    String actionName,
    ProfileRequired builtProfile,
  ) {
    // Only clean up actions with the following locations
    if (![
      ActionLocation.fabTap.name,
      ActionLocation.fabHold.name,
      ActionLocationWithTabs.tabs.name,
    ].contains(actionName)) {
      return this;
    }

    return copyWith(
      feedActionBackToTop: builtProfile.feedActionBackToTop.name == actionName
          ? ActionLocation.hide
          : this.feedActionBackToTop,
      feedActionCreateNew: builtProfile.feedActionCreateNew.name == actionName
          ? ActionLocation.hide
          : this.feedActionCreateNew,
      feedActionExpandFab: builtProfile.feedActionExpandFab.name == actionName
          ? ActionLocation.hide
          : this.feedActionExpandFab,
      feedActionRefresh: builtProfile.feedActionRefresh.name == actionName
          ? ActionLocation.hide
          : this.feedActionRefresh,
      feedActionSetFilter: builtProfile.feedActionSetFilter.name == actionName
          ? ActionLocationWithTabs.hide
          : this.feedActionSetFilter,
      feedActionSetSort: builtProfile.feedActionSetSort.name == actionName
          ? ActionLocation.hide
          : this.feedActionSetSort,
      feedActionSetView: builtProfile.feedActionSetView.name == actionName
          ? ActionLocationWithTabs.hide
          : this.feedActionSetView,
    );
  }

  // Remove fields that depend on a certain setup
  ProfileOptional exportReady() {
    return copyWith(autoSwitchAccount: null, filterLists: null);
  }
}
