import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/control_availability.dart';

/// Large press-and-hold button for LIFT / LOWER.
///
/// Calls [onPress] when the first finger goes down and [onRelease] exactly
/// once when that finger lifts, is cancelled, or slides off the button.
class HoldButton extends StatefulWidget {
  /// Creates the button.
  const HoldButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.availability,
    required this.held,
    required this.onPress,
    required this.onRelease,
  });

  /// Button text, e.g. "LIFT".
  final String label;

  /// Button icon.
  final IconData icon;

  /// Accent colour.
  final Color color;

  /// Enabled state and disabled reason.
  final Availability availability;

  /// Whether the crane is currently being driven by this button.
  final bool held;

  /// Finger down.
  final VoidCallback onPress;

  /// Finger up / cancelled / slid off.
  final VoidCallback onRelease;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> {
  /// Pointer that pressed the button, or null.
  int? _pointer;

  /// Starts a hold for [event] if enabled and no other finger holds it.
  void _down(PointerDownEvent event) {
    if (_pointer != null || !widget.availability.enabled) return;
    _pointer = event.pointer;
    HapticFeedback.mediumImpact();
    widget.onPress();
  }

  /// Ends the hold if [pointer] is the holding finger.
  void _up(int pointer) {
    if (_pointer != pointer) return;
    _pointer = null;
    widget.onRelease();
  }

  /// Ends the hold when the finger slides outside the button.
  void _move(PointerMoveEvent event) {
    if (_pointer != event.pointer) return;
    final size = context.size;
    if (size != null && !(Offset.zero & size).contains(event.localPosition)) _up(event.pointer);
  }

  /// Releases a hold that is still active when the widget goes away.
  @override
  void dispose() {
    if (_pointer != null) widget.onRelease();
    super.dispose();
  }

  /// Builds the button and its disabled reason.
  @override
  Widget build(BuildContext context) {
    final enabled = widget.availability.enabled;
    final scheme = Theme.of(context).colorScheme;
    final fg = widget.held ? Colors.white : (enabled ? widget.color : scheme.onSurface.withValues(alpha: 0.38));
    final bg = widget.held
        ? widget.color
        : (enabled ? widget.color.withValues(alpha: 0.12) : scheme.onSurface.withValues(alpha: 0.06));

    return Semantics(
      button: true,
      enabled: enabled,
      label: '${widget.label}, press and hold${enabled ? '' : ', disabled: ${widget.availability.reason}'}',
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerUp: (e) => _up(e.pointer),
        onPointerCancel: (e) => _up(e.pointer),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          height: 96,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: enabled ? widget.color : scheme.outlineVariant, width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          // Fixed height: shrink the content (large system fonts, disabled reason) instead of overflowing.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: fg, size: 32),
                Text(
                  widget.label,
                  style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (!enabled)
                  ConstrainedBox(
                    // Keep long reasons from making the whole button shrink too much.
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      widget.availability.reason ?? '',
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
