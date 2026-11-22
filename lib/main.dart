import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diutube Go+',
      home: DiutubeGoPlusApp(),
    ));

class DiutubeGoPlusApp extends StatefulWidget {
  const DiutubeGoPlusApp({super.key});
  @override
  State<DiutubeGoPlusApp> createState() => _DiutubeGoPlusAppState();
}

class _DiutubeGoPlusAppState extends State<DiutubeGoPlusApp> {
  final _yt = YoutubeExplode();
  final _searchCtrl = TextEditingController();
  VideoPlayerController? _player;
  List<Video> _results = [];
  String _currentTitle = 'Tìm video để phát không quảng cáo';
  bool _loading = false;

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() => _loading = true);
    try {
      final list = await _yt.search.search(query);
      setState(() {
        _results = list.take(15).toList();
      });
    } catch (e) {
      setState(() => _currentTitle = 'Lỗi tìm kiếm: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _playVideo(Video video) async {
    setState(() {
      _loading = true;
      _currentTitle = 'Đang bóc luồng: ${video.title}';
    });
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(video.id);
      final streamUrl = manifest.muxed.withHighestBitrate().url;

      await _player?.dispose();
      final controller = VideoPlayerController.networkUrl(streamUrl);
      await controller.initialize();
      await controller.play();

      setState(() {
        _player = controller;
        _currentTitle = video.title;
      });
    } catch (e) {
      setState(() => _currentTitle = 'Không phát được video này: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _yt.close();
    _player?.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: TextField(
          controller: _searchCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tìm trên Diutube Go+...',
            hintStyle: const TextStyle(color: Colors.grey),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search, color: Colors.redAccent),
              onPressed: _search,
            ),
          ),
          onSubmitted: (_) => _search(),
        ),
      ),
      body: Column(
        children: [
          if (_player != null && _player!.value.isInitialized)
            AspectRatio(
              aspectRatio: _player!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(_player!),
                  VideoProgressIndicator(_player!, allowScrubbing: true),
                  Center(
                    child: IconButton(
                      iconSize: 48,
                      color: Colors.white70,
                      icon: Icon(_player!.value.isPlaying
                          ? Icons.pause_circle
                          : Icons.play_circle),
                      onPressed: () => setState(() {
                        _player!.value.isPlaying
                            ? _player!.pause()
                            : _player!.play();
                      }),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              _currentTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          if (_loading) const LinearProgressIndicator(color: Colors.redAccent),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final v = _results[i];
                return ListTile(
                  leading: Image.network(
                    v.thumbnails.mediumResUrl,
                    width: 100,
                    fit: BoxFit.cover,
                  ),
                  title: Text(
                    v.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  subtitle: Text(
                    v.author,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  onTap: () => _playVideo(v),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}