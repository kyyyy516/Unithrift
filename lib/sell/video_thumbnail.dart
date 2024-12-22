import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoThumbnail extends StatefulWidget {
  final File videoFile;
  final double width;
  final double height;

  const VideoThumbnail({
    required this.videoFile,
    this.width = 120,
    this.height = 120,
    Key? key,
  }) : super(key: key);

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        _controller.play();
        _controller.setLooping(true);
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: _controller.value.isInitialized
          ? Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),
                Icon(
                  Icons.videocam,
                  color: Colors.white.withOpacity(0.7),
                  size: 30,
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator(
            color: Color(0xFF808569),
          )),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
