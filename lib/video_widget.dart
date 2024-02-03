import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class VideoWidget extends StatefulWidget {
  const VideoWidget({super.key});

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late VideoPlayerController videoPlayerController;

  @override
  void initState() {
    videoPlayerController = VideoPlayerController.asset('assets/video_1.mp4')
      ..initialize().then((value) {
        setState(() {});
      });
    super.initState();
  }

  @override
  void dispose() {
    videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (videoPlayerController.value.isPlaying) {
                videoPlayerController.pause();
              } else {
                videoPlayerController.play();
              }
              setState(() {});
            },
            child: AspectRatio(
              aspectRatio: videoPlayerController.value.aspectRatio,
              child: VideoPlayer(videoPlayerController),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          GestureDetector(
            onTap: () async {
              videoPlayerController.pause();
              onEchoToVideo(17).then((value) {
                if (value.isNotEmpty) {
                  videoPlayerController =
                      VideoPlayerController.file(File(value))
                        ..initialize().then((value) {
                          videoPlayerController.play();
                          setState(() {});
                        });
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 10,
              ),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              child: const Text(
                "Set Echo",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<String> onEchoToVideo(int echo) async {
    try {
      final cacheDirectory = await getApplicationCacheDirectory();
      final outputFileName = '${cacheDirectory.path}/echo.mp4';
      final file = File(outputFileName);
      if (file.existsSync()) {
        file.deleteSync();
      }
      final ByteData data = await rootBundle.load('assets/video_1.mp4');
      final List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      final Directory tempDir = await getApplicationCacheDirectory();
      final String tempPath = '${tempDir.path}/video.mp4';

      final tempFile = await File(tempPath).create();

      await tempFile.writeAsBytes(bytes, flush: true);

      final List<String> command = [
        '-i',
        tempFile.path,
        '-af',
        'aecho=0.8:0.9:1000:0.3',
        outputFileName
      ];

      final result = await FFmpegKit.executeWithArguments(command);
      final returnCode = await result.getReturnCode();
      debugPrint('code ${returnCode}');
      if (ReturnCode.isSuccess(returnCode)) {
        return outputFileName;
      }

      return '';
    } on PlatformException catch (err) {
      debugPrint('convert file ${err.message}');
      return '';
    }
  }
}
