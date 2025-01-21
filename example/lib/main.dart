import 'package:flutter/material.dart';
import 'package:reels_caching/reels_caching.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(),
        body: ReelsCachingReels(
          context: context,
          key: UniqueKey(),
          loader: const Center(
            child: CircularProgressIndicator(),
          ),
          videoList: const [
            // ""
            // ""
            "https://s3.amazonaws.com/rinzy/uploads/reels/e9zpEjnVbNq75M40I1D1CedjqIcJxvQ7r3MTbJOX.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            "https://s3.amazonaws.com/rinzy/uploads/reels/e9zpEjnVbNq75M40I1D1CedjqIcJxvQ7r3MTbJOX.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
          ],
          isCaching: true,
        ),
      ),
    );
  }
}
