import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/stayeasy_colors.dart';
import '../../../core/theme/stayeasy_spacing.dart';
import '../../../core/theme/stayeasy_typography.dart';
import '../../discovery/application/discovery_providers.dart';
import '../../discovery/domain/models/room.dart';
import '../application/virtual_tour_catalog.dart';
import '../domain/virtual_tour.dart';

typedef VirtualTourImageLoader = Future<void> Function(
  ImageProvider<Object> image,
  BuildContext context,
);

typedef VirtualTourViewerBuilder = Widget Function(
  BuildContext context,
  VirtualTourSpace space,
  ValueChanged<VirtualTourHotspot> onHotspotTap,
);

final virtualTourImageLoaderProvider = Provider<VirtualTourImageLoader>(
  (ref) => _loadImage,
);

final virtualTourViewerBuilderProvider = Provider<VirtualTourViewerBuilder>(
  (ref) => _buildPanorama,
);

Future<void> _loadImage(
  ImageProvider<Object> image,
  BuildContext context,
) async {
  final completer = Completer<void>();
  final stream = image.resolve(createLocalImageConfiguration(context));
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, synchronousCall) {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.complete();
    },
    onError: (Object error, StackTrace? stackTrace) {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.completeError(error, stackTrace);
    },
  );
  stream.addListener(listener);
  await completer.future;
}

ImageProvider<Object> _imageProvider(VirtualTourSpace space) =>
    space.imageKind == TourImageKind.asset
    ? AssetImage(space.imageSource)
    : NetworkImage(space.imageSource);

Widget _buildPanorama(
  BuildContext context,
  VirtualTourSpace space,
  ValueChanged<VirtualTourHotspot> onHotspotTap,
) => PanoramaViewer(
  key: ValueKey('panorama-${space.id}'),
  sensorControl: SensorControl.none,
  latitude: space.initialLatitude,
  longitude: space.initialLongitude,
  zoom: space.initialZoom,
  hotspots: [
    for (final hotspot in space.hotspots)
      Hotspot(
        name: hotspot.label,
        longitude: hotspot.longitude,
        latitude: hotspot.latitude,
        width: 156,
        height: 44,
        widget: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onHotspotTap(hotspot),
            borderRadius: BorderRadius.circular(14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: StayEasyColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      hotspot.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StayEasyTypography.caption.copyWith(
                        color: StayEasyColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
  ],
  child: Image(image: _imageProvider(space)),
);

class VirtualTourPage extends ConsumerStatefulWidget {
  const VirtualTourPage({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<VirtualTourPage> createState() => _VirtualTourPageState();
}

class _VirtualTourPageState extends ConsumerState<VirtualTourPage> {
  int _selectedSpaceIndex = 0;
  String? _loadedSpaceId;
  String? _loadingSpaceId;
  Object? _imageError;
  bool _isFullscreen = false;

  void _loadSpace(VirtualTourSpace space) {
    if (_loadedSpaceId == space.id || _loadingSpaceId == space.id) return;
    _loadingSpaceId = space.id;
    _imageError = null;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await ref.read(virtualTourImageLoaderProvider)(
          _imageProvider(space),
          context,
        );
        if (mounted && _loadingSpaceId == space.id) {
          setState(() {
            _loadedSpaceId = space.id;
            _loadingSpaceId = null;
          });
        }
      } catch (error) {
        if (mounted && _loadingSpaceId == space.id) {
          setState(() {
            _imageError = error;
            _loadingSpaceId = null;
          });
        }
      }
    });
  }

  void _selectSpace(int index, List<VirtualTourSpace> spaces) {
    if (index == _selectedSpaceIndex) return;
    setState(() {
      _selectedSpaceIndex = index;
      _loadedSpaceId = null;
      _imageError = null;
    });
    _loadSpace(spaces[index]);
  }

  void _showHotspot(VirtualTourHotspot hotspot) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: StayEasyColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hotspot.label, style: StayEasyTypography.headingH3),
              if (hotspot.description case final description?) ...[
                const SizedBox(height: 8),
                Text(description, style: StayEasyTypography.bodyMedium),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomFutureProvider(widget.roomId));
    if (roomState.isLoading) return _statusPage('Loading room preview…');
    if (roomState.hasError || roomState.value == null) {
      return _unavailablePage(context);
    }
    final room = roomState.value!;
    final tour = VirtualTourCatalog.resolve(room);
    if (tour == null || tour.spaces.isEmpty) return _unavailablePage(context);
    if (_imageError != null) return _unavailablePage(context);
    _selectedSpaceIndex = _selectedSpaceIndex.clamp(0, tour.spaces.length - 1);
    final space = tour.spaces[_selectedSpaceIndex];
    if (_loadedSpaceId != space.id && _loadingSpaceId != space.id) {
      _loadSpace(space);
    }

    final media = MediaQuery.of(context);
    final wide = media.size.width >= 1024;
    final frameWidth = wide
        ? (media.size.width - 48).clamp(0, 1180.0).toDouble()
        : media.size.width;
    final frameHeight = wide
        ? (media.size.height - 48).clamp(0, 900.0).toDouble()
        : media.size.height;
    final frameLeft = wide ? (media.size.width - frameWidth) / 2 : 0.0;
    final frameTop = wide ? (media.size.height - frameHeight) / 2 : 0.0;
    final panelHeight = 254.0 + media.padding.bottom;

    return PopScope<Object?>(
      canPop: !_isFullscreen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isFullscreen) setState(() => _isFullscreen = false);
      },
      child: Scaffold(
        backgroundColor: StayEasyColors.primaryDark,
        body: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              left: _isFullscreen ? 0 : frameLeft,
              top: _isFullscreen ? 0 : frameTop,
              width: _isFullscreen ? media.size.width : frameWidth,
              height: _isFullscreen ? media.size.height : frameHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  wide && !_isFullscreen ? 24 : 0,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: StayEasyColors.primaryDark),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: _isFullscreen ? 0 : panelHeight,
                      child: _panoramaArea(space),
                    ),
                    if (!_isFullscreen)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: panelHeight,
                        child: _experiencePanel(tour.spaces),
                      )
                    else
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 12 + media.padding.bottom,
                        child: _spaceSwitcher(tour.spaces),
                      ),
                    _topControls(
                      room,
                      space,
                      isDemoTour: tour.roomId == VirtualTourCatalog.demoRoomId,
                    ),
                    if (!_isFullscreen) _dragHint(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panoramaArea(VirtualTourSpace space) {
    if (_imageError != null) {
      return const Center(
        child: Text(
          '360 preview unavailable',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    if (_loadedSpaceId != space.id) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return ColoredBox(
      color: Colors.black,
      child: ref
          .read(virtualTourViewerBuilderProvider)
          .call(context, space, _showHotspot),
    );
  }

  Widget _topControls(
    Room room,
    VirtualTourSpace space, {
    required bool isDemoTour,
  }) => Positioned(
    left: 16,
    right: 16,
    top: MediaQuery.paddingOf(context).top + 18,
    height: 44,
    child: Row(
      children: [
        _roundControl(
          icon: Icons.arrow_back_rounded,
          label: _isFullscreen ? 'Close full screen' : 'Back to room',
          onPressed: () {
            if (_isFullscreen) {
              setState(() => _isFullscreen = false);
            } else {
              context.pop();
            }
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 44,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  room.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StayEasyTypography.labelLarge,
                ),
                Text(
                  space.label,
                  maxLines: 1,
                  style: StayEasyTypography.caption.copyWith(
                    color: StayEasyColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _roundControl(
          icon: Icons.info_outline_rounded,
          label: 'Tour information',
          onPressed: () => _showInfo(isDemoTour),
        ),
      ],
    ),
  );

  Widget _roundControl({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    child: SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        icon: Icon(icon, color: StayEasyColors.textPrimary, size: 21),
        padding: EdgeInsets.zero,
      ),
    ),
  );

  Widget _dragHint() => Positioned(
    top: MediaQuery.paddingOf(context).top + 82,
    left: 0,
    right: 0,
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '↔ Drag to look around',
          style: StayEasyTypography.labelMedium.copyWith(
            color: StayEasyColors.textPrimary,
          ),
        ),
      ),
    ),
  );

  Widget _experiencePanel(List<VirtualTourSpace> spaces) => Container(
    color: StayEasyColors.primaryDark,
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore the room',
          style: StayEasyTypography.titleLarge.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 3),
        Text(
          'Tap hotspots for details or switch spaces below.',
          style: StayEasyTypography.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: .86),
          ),
        ),
        const SizedBox(height: 14),
        _spaceSwitcher(spaces),
        const SizedBox(height: 16),
        Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.threesixty_rounded,
                color: StayEasyColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('360° preview', style: StayEasyTypography.labelLarge),
                    Text(
                      'Swipe · pinch · tap hotspots',
                      style: StayEasyTypography.caption.copyWith(
                        color: StayEasyColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 44,
                height: 44,
                child: FilledButton(
                  key: const ValueKey('tour-fullscreen-open'),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: StayEasyColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => setState(() => _isFullscreen = true),
                  child: const Icon(Icons.fullscreen_rounded),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _spaceSwitcher(List<VirtualTourSpace> spaces) => Container(
    height: 52,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        for (var index = 0; index < spaces.length; index++) ...[
          if (index > 0) const SizedBox(width: 5),
          Expanded(
            child: Material(
              color: _selectedSpaceIndex == index
                  ? StayEasyColors.primary
                  : StayEasyColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                key: ValueKey('tour-space-${spaces[index].id}'),
                borderRadius: BorderRadius.circular(12),
                onTap: () => _selectSpace(index, spaces),
                child: Center(
                  child: Text(
                    spaces[index].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StayEasyTypography.labelMedium.copyWith(
                      color: _selectedSpaceIndex == index
                          ? Colors.white
                          : StayEasyColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );

  void _showInfo(bool isDemoTour) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: StayEasyColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final spaces = isDemoTour
            ? VirtualTourCatalog.demoTour.spaces
            : const <VirtualTourSpace>[];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('How to explore', style: StayEasyTypography.headingH3),
                  const SizedBox(height: 12),
                  for (final instruction in const [
                    'Drag to look around',
                    'Pinch or scroll to zoom',
                    'Tap hotspots for details',
                    'Switch spaces below',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Text(
                        '•  $instruction',
                        style: StayEasyTypography.bodyMedium,
                      ),
                    ),
                  if (isDemoTour) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Demo panorama imagery',
                      style: StayEasyTypography.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'These are CC0 demo photospheres resized for the StayEasy academic prototype; they do not represent the seeded Harbour Queen property.',
                      style: StayEasyTypography.bodySmall.copyWith(
                        color: StayEasyColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final space in spaces)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${space.label}: ${space.attribution} — ${space.license}',
                          style: StayEasyTypography.bodySmall,
                        ),
                      ),
                  ],
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statusPage(String message) => Scaffold(
    backgroundColor: StayEasyColors.primaryDark,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            message,
            style: StayEasyTypography.bodyMedium.copyWith(color: Colors.white),
          ),
        ],
      ),
    ),
  );

  Widget _unavailablePage(BuildContext context) => Scaffold(
    backgroundColor: StayEasyColors.background,
    appBar: AppBar(
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      backgroundColor: StayEasyColors.background,
      elevation: 0,
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(StayEasySpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.view_in_ar_outlined,
              size: 44,
              color: StayEasyColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '360 preview unavailable',
              style: StayEasyTypography.headingH3,
            ),
            const SizedBox(height: 8),
            Text(
              'Room photos are still available.',
              textAlign: TextAlign.center,
              style: StayEasyTypography.bodyMedium.copyWith(
                color: StayEasyColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go(AppRoutes.roomPath(widget.roomId)),
              child: const Text('Back to room'),
            ),
          ],
        ),
      ),
    ),
  );
}
