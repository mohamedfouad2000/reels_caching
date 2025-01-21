library reels_caching;

/// A Calculator.
// Importing necessary packages
import 'dart:async'; // For asynchronous operations
import 'dart:developer'; // For logging

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'; // For caching files
import 'package:get/get.dart';
import 'package:video_player/video_player.dart'; // For video playback
import 'package:visibility_detector/visibility_detector.dart';

// Abstract class defining a service for obtaining video controllers
abstract class VideoControllerService {
  // Method to get a VideoPlayerController for a given video URL
  Future<VideoPlayerController> getControllerForVideo(
      String url, bool isCaching);
}

// Implementation of VideoControllerService that uses caching
class CachedVideoControllerService extends VideoControllerService {
  final BaseCacheManager _cacheManager; // Cache manager instance

  // Constructor requiring a cache manager instance
  CachedVideoControllerService(this._cacheManager);

  @override
  Future<VideoPlayerController> getControllerForVideo(
      String url, bool isCaching) async {
    if (isCaching) {
      FileInfo?
          fileInfo; // Variable to store file info if video is found in cache

      try {
        // Attempt to retrieve video file from cache
        fileInfo = await _cacheManager.getFileFromCache(url);
      } catch (e) {
        // Log error if encountered while getting video from cache
        log('Error getting video from cache: $e');
      }

      // Check if video file was found in cache
      if (fileInfo != null) {
        // Log that video was found in cache
        // log('Video found in cache');
        // Return VideoPlayerController for the cached file
        return VideoPlayerController.file(fileInfo.file);
      }

      try {
        // If video is not found in cache, attempt to download it
        _cacheManager.downloadFile(url);
      } catch (e) {
        // Log error if encountered while downloading video
        log('Error downloading video: $e');
      }
    }

    // Return VideoPlayerController for the video from the network
    return VideoPlayerController.networkUrl(Uri.parse(url));
  }
}

class ReelsCachingReels extends GetView<ReelsCachingReelsController> {
  final BuildContext context;
  final List<String>? videoList;
  final Widget? loader;
  final bool isCaching;
  final int startIndex;
  final Widget Function(
    BuildContext context,
    int index,
    Widget child,
    VideoPlayerController videoPlayerController,
    PageController pageController,
  )? builder;

  const ReelsCachingReels({
    super.key,
    required this.context,
    this.videoList,
    this.loader,
    this.isCaching = false,
    this.builder,
    this.startIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    Get.delete<ReelsCachingReelsController>();
    Get.lazyPut<ReelsCachingReelsController>(() => ReelsCachingReelsController(
          reelsVideoList: videoList ?? [],
          isCaching: isCaching,
          startIndex: startIndex,
        ));
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(
        () => PageView.builder(
          controller: controller.pageController,
          itemCount: controller.pageCount.value,
          scrollDirection: Axis.vertical,
          itemBuilder: (context, index) {
            return buildTile(index);
          },
        ),
      ),
    );
  }

  buildTile(index) {
    return VisibilityDetector(
      key: Key(index.toString()),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction < 0.5) {
          controller.videoPlayerControllerList[index].seekTo(Duration.zero);
          controller.videoPlayerControllerList[index].pause();
          // controller.visible.value = true;
          controller.refreshView();
          controller.animationController.stop();
        } else {
          controller.listenEvents(index);
          controller.videoPlayerControllerList[index].play();
          // controller.visible.value = true;
          Future.delayed(const Duration(milliseconds: 500), () {
            // controller.visible.value = false;
          });
          controller.refreshView();
          controller.animationController.repeat();
          controller.initNearByVideos(index);
          if (!controller.caching.contains(controller.videoList[index])) {
            controller.cacheVideo(index);
          }
          controller.visible.value = false;
        }
      },
      child: GestureDetector(
        onTap: () {
          if (controller.videoPlayerControllerList[index].value.isPlaying) {
            controller.videoPlayerControllerList[index].pause();
            controller.visible.value = true;
            controller.refreshView();
            controller.animationController.stop();
          } else {
            controller.videoPlayerControllerList[index].play();
            controller.visible.value = true;
            Future.delayed(const Duration(milliseconds: 500), () {
              controller.visible.value = false;
            });

            controller.refreshView();
            controller.animationController.repeat();
          }
        },
        child: Obx(() {
          if (controller.loading.value ||
              !controller
                  .videoPlayerControllerList[index].value.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.red,
              ),
            );
          }

          return builder == null
              ? VideoFullScreenPage(
                  videoPlayerController:
                      controller.videoPlayerControllerList[index])
              : builder!(
                  context,
                  index,
                  VideoFullScreenPage(
                    videoPlayerController:
                        controller.videoPlayerControllerList[index],
                  ),
                  controller.videoPlayerControllerList[index],
                  controller.pageController);
        }),
      ),
    );
  }
}

class VideoFullScreenPage extends StatelessWidget {
  final VideoPlayerController videoPlayerController;

  const VideoFullScreenPage({super.key, required this.videoPlayerController});

  @override
  Widget build(BuildContext context) {
    ReelsCachingReelsController controller =
        Get.find<ReelsCachingReelsController>();
    return Stack(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: MediaQuery.of(context).size.height *
                  videoPlayerController.value.aspectRatio,
              height: MediaQuery.of(context).size.height,
              child: VideoPlayer(videoPlayerController),
            ),
          ),
        ),
        Positioned(
          child: Center(
            child: Obx(
              () => Opacity(
                opacity: .5,
                child: AnimatedOpacity(
                  opacity: controller.visible.value ? 1 : 0,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    alignment: Alignment.center,
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                    ),
                    child: videoPlayerController.value.isPlaying
                        ? const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 40,
                          )
                        : const Icon(
                            Icons.pause,
                            color: Colors.white,
                            size: 40,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Controller class for managing the reels in the app
class ReelsCachingReelsController extends GetxController
    with GetTickerProviderStateMixin, WidgetsBindingObserver {
  // Page controller for managing pages of videos
  PageController pageController = PageController(viewportFraction: 0.99999);

  // List of video player controllers
  RxList<VideoPlayerController> videoPlayerControllerList =
      <VideoPlayerController>[].obs;

  // Service for managing cached video controllers
  CachedVideoControllerService videoControllerService =
      CachedVideoControllerService(DefaultCacheManager());

  // Observable for loading state
  final loading = true.obs;

  // Observable for visibility state
  final visible = false.obs;

  // Animation controller for animating
  late AnimationController animationController;

  // Animation object
  late Animation animation;

  // Current page index
  int page = 1;

  // Limit for loading videos
  int limit = 10;

  // List of video URLs
  final List<String> reelsVideoList;

  // isCaching
  bool isCaching;

  // Observable list of video URLs
  RxList<String> videoList = <String>[].obs;

  // Limit for loading nearby videos
  int loadLimit = 2;

  // Flag for initialization
  bool init = false;

  // Timer for periodic tasks
  Timer? timer;

  // Index of the last video
  int? lastIndex;

  // Already listened list
  List<int> alreadyListened = [];

  // Caching video at index
  List<String> caching = [];

  // pageCount
  RxInt pageCount = 0.obs;

  final int startIndex;

  // Constructor
  ReelsCachingReelsController(
      {required this.reelsVideoList,
      required this.isCaching,
      this.startIndex = 0});

  // Lifecycle method for handling app lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // Pause all video players when the app is paused
      for (var i = 0; i < videoPlayerControllerList.length; i++) {
        videoPlayerControllerList[i].pause();
      }
    }
  }

  // Lifecycle method called when the controller is initialized
  @override
  void onInit() {
    super.onInit();
    videoList.addAll(reelsVideoList);
    // Initialize animation controller
    animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5));
    animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeIn,
    );
    // Initialize service and start timer
    initService(startIndex: startIndex);
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (lastIndex != null) {
        initNearByVideos(lastIndex!);
      }
    });
  }

  // Lifecycle method called when the controller is closed
  @override
  void onClose() {
    animationController.dispose();
    // Pause and dispose all video players
    for (var i = 0; i < videoPlayerControllerList.length; i++) {
      videoPlayerControllerList[i].pause();
      videoPlayerControllerList[i].dispose();
    }
    timer?.cancel();
    super.onClose();
  }

  // Initialize video service and load videos
  initService({int startIndex = 0}) async {
    await addVideosController();
    int myindex = startIndex;

    try {
      if (!videoPlayerControllerList[myindex].value.isInitialized) {
        cacheVideo(myindex);
        await videoPlayerControllerList[myindex].initialize();
        increasePage(myindex + 1);
      }
    } catch (e) {
      log('Error initializing video at index $myindex: $e');
    }

    animationController.repeat();
    videoPlayerControllerList[myindex].play();
    refreshView();
    // listenEvents(myindex);
    await initNearByVideos(myindex);
    loading.value = false;

    Future.delayed(Duration.zero, () {
      pageController.jumpToPage(myindex);
    });
  }

  // Refresh loading state
  refreshView() {
    loading.value = true;
    loading.value = false;
  }

  // Add video controllers
  addVideosController() async {
    for (var i = 0; i < videoList.length; i++) {
      String videoFile = videoList[i];
      final controller = await videoControllerService.getControllerForVideo(
          videoFile, isCaching);
      videoPlayerControllerList.add(controller);
    }
  }

  // Initialize nearby videos
  initNearByVideos(int index) async {
    if (init) {
      lastIndex = index;
      return;
    }
    lastIndex = null;
    init = true;
    if (loading.value) return;
    disposeNearByOldVideoControllers(index);
    await tryInit(index);
    try {
      var currentPage = index;
      var maxPage = currentPage + loadLimit;
      List<String> videoFiles = videoList;

      for (var i = currentPage; i < maxPage; i++) {
        if (videoFiles.asMap().containsKey(i)) {
          var controller = videoPlayerControllerList[i];
          if (!controller.value.isInitialized) {
            cacheVideo(i);
            await controller.initialize();
            increasePage(i + 1);
            refreshView();
            // listenEvents(i);
          }
        }
      }
      for (var i = index - 1; i > index - loadLimit; i--) {
        if (videoList.asMap().containsKey(i)) {
          var controller = videoPlayerControllerList[i];
          if (!controller.value.isInitialized) {
            if (!caching.contains(videoList[index])) {
              cacheVideo(index);
            }

            await controller.initialize();
            increasePage(i + 1);
            refreshView();
            // listenEvents(i);
          }
        }
      }

      refreshView();
      loading.value = false;
    } catch (e) {
      loading.value = false;
    } finally {
      loading.value = false;
    }
    init = false;
  }

  // Try initializing video at index
  tryInit(int index) async {
    var oldVideoPlayerController = videoPlayerControllerList[index];
    if (oldVideoPlayerController.value.isInitialized) {
      oldVideoPlayerController.play();
      refresh();
      return;
    }
    VideoPlayerController videoPlayerControllerTmp =
        await videoControllerService.getControllerForVideo(
            videoList[index], isCaching);
    videoPlayerControllerList[index] = videoPlayerControllerTmp;
    await oldVideoPlayerController.dispose();
    refreshView();
    if (!caching.contains(videoList[index])) {
      cacheVideo(index);
    }
    await videoPlayerControllerTmp
        .initialize()
        .catchError((e) {})
        .then((value) {
      videoPlayerControllerTmp.play();
      refresh();
    });
  }

  // Dispose nearby old video controllers
  disposeNearByOldVideoControllers(int index) async {
    loading.value = false;
    for (var i = index - loadLimit; i > 0; i--) {
      if (videoPlayerControllerList.asMap().containsKey(i)) {
        var oldVideoPlayerController = videoPlayerControllerList[i];
        VideoPlayerController videoPlayerControllerTmp =
            await videoControllerService.getControllerForVideo(
                videoList[i], isCaching);
        videoPlayerControllerList[i] = videoPlayerControllerTmp;
        alreadyListened.remove(i);
        await oldVideoPlayerController.dispose();
        refreshView();
      }
    }

    for (var i = index + loadLimit; i < videoPlayerControllerList.length; i++) {
      if (videoPlayerControllerList.asMap().containsKey(i)) {
        var oldVideoPlayerController = videoPlayerControllerList[i];
        VideoPlayerController videoPlayerControllerTmp =
            await videoControllerService.getControllerForVideo(
                videoList[i], isCaching);
        videoPlayerControllerList[i] = videoPlayerControllerTmp;
        alreadyListened.remove(i);
        await oldVideoPlayerController.dispose();
        refreshView();
      }
    }
  }

  // Listen to video events
  listenEvents(i, {bool force = false}) {
    if (alreadyListened.contains(i) && !force) return;
    alreadyListened.add(i);
    var videoPlayerController = videoPlayerControllerList[i];

    videoPlayerController.addListener(() {
      if (videoPlayerController.value.position ==
              videoPlayerController.value.duration &&
          videoPlayerController.value.duration != Duration.zero) {
        videoPlayerController.seekTo(Duration.zero);
        videoPlayerController.play();
      }
    });
  }

  // Listen to page events
  // pageEventsListen(path) {
  //   pageController.addListener(() {
  //     visible.value = false;
  //     Future.delayed(const Duration(milliseconds: 500), () {
  //       loading.value = false;
  //     });
  //     refreshView();
  //   });
  // }

  cacheVideo(int index) async {
    if (!isCaching) return;
    String url = videoList[index];
    if (caching.contains(url)) return;
    caching.add(url);
    final cacheManager = DefaultCacheManager();
    FileInfo? fileInfo = await cacheManager.getFileFromCache(url);
    if (fileInfo != null) {
      log('Video already cached: $index');
      return;
    }

    // log('Downloading video: $index');
    try {
      await cacheManager.downloadFile(url);
      // log('Downloaded video: $index');
    } catch (e) {
      // log('Error downloading video: $e');
      caching.remove(url);
    }
  }

  increasePage(v) {
    if (pageCount.value == videoList.length) return;
    if (pageCount.value >= v) return;
    pageCount.value = v;
  }
}
