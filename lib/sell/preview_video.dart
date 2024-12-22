import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewDialog extends StatefulWidget {
  final VideoPlayerController videoController;
  
  const VideoPreviewDialog({super.key, required this.videoController});
  
  @override
  State<VideoPreviewDialog> createState() => _VideoPreviewDialogState();
}

class _VideoPreviewDialogState extends State<VideoPreviewDialog> {
  @override
  void initState() {
    super.initState();
    // Add listener to rebuild UI when video state changes
    widget.videoController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: EdgeInsets.zero,
            viewInsets: EdgeInsets.zero,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (widget.videoController.value.isPlaying) {
                      widget.videoController.pause();
                    } else {
                      widget.videoController.play();
                    }
                  });
                },
                child: Center(
                  child: InteractiveViewer(
                    child: AspectRatio(
                      aspectRatio: widget.videoController.value.aspectRatio,
                      child: VideoPlayer(widget.videoController),
                    ),
                  ),
                ),
              ),
              // Close button stays at top
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 30, color:Colors.white ,),
                  onPressed: () {
                    widget.videoController.dispose();
                    Navigator.of(context).pop();
                  },
                ),
              ),
              // Play/Pause button centered
              if (!widget.videoController.value.isPlaying)
              Center(
                child: IconButton(
                  iconSize: 70, // Made bigger for better visibility
                  icon: Icon(
                    widget.videoController.value.isPlaying
                        ? Icons.pause
                        : Icons.play_circle_fill_rounded,
                    color: Colors.black.withOpacity(0.7), // Added some transparency
                    
                  ),
                  onPressed: () {
                    setState(() {
                      if (widget.videoController.value.isPlaying) {
                        widget.videoController.pause();
                      } else {
                        widget.videoController.play();
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.videoController.removeListener(() {});
    super.dispose();
  }
}
