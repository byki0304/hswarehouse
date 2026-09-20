import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:hswarehouse/app/theme/app_theme.dart';
import 'package:hswarehouse/entities/branch_app/branch_app.dart';

class BranchAppCard extends StatefulWidget {
  const BranchAppCard({
    super.key,
    required this.app,
    required this.onTap,
  });

  final BranchApp app;
  final VoidCallback onTap;

  @override
  State<BranchAppCard> createState() => _BranchAppCardState();
}

class _BranchAppCardState extends State<BranchAppCard> {
  bool _hover = false;

  Widget _buildIcon() {
    final url = widget.app.iconUrl;
    if (url.isEmpty) return _PlaceholderIcon(name: widget.app.name);

    if (url.startsWith('data:image/svg+xml')) {
      try {
        final svg = _decodeSvgDataUrl(url);
        return SvgPicture.string(svg, fit: BoxFit.cover);
      } catch (_) {
        return _PlaceholderIcon(name: widget.app.name);
      }
    }

    if (url.startsWith('data:image')) {
      try {
        final base64Part = url.split(',').last;
        final bytes = base64Decode(base64Part);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return _PlaceholderIcon(name: widget.app.name);
      }
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppTheme.surface,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) =>
          _PlaceholderIcon(name: widget.app.name),
    );
  }

  String _decodeSvgDataUrl(String url) {
    final comma = url.indexOf(',');
    if (comma < 0) throw const FormatException('Invalid SVG data URL');
    final meta = url.substring(0, comma).toLowerCase();
    final payload = url.substring(comma + 1);
    if (meta.contains(';base64')) {
      return utf8.decode(base64Decode(payload));
    }
    return Uri.decodeComponent(payload);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.02 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.surfaceElevated.withValues(alpha: 0.95),
                    AppTheme.surface.withValues(alpha: 0.88),
                  ],
                ),
                border: Border.all(
                  color: _hover
                      ? AppTheme.neon.withValues(alpha: 0.45)
                      : AppTheme.hairline,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _buildIcon(),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  height: 28,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          AppTheme.background
                                              .withValues(alpha: 0.45),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.app.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(
                        15,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.app.creator,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(
                        12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.neonAlt.withValues(alpha: 0.35),
            AppTheme.neon.withValues(alpha: 0.2),
            AppTheme.surface,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: AppTheme.display(36),
      ),
    );
  }
}
