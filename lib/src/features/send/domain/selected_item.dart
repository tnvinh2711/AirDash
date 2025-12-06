import 'package:flux/src/features/send/domain/selected_item_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'selected_item.freezed.dart';
part 'selected_item.g.dart';

/// An item in the selection queue awaiting transfer.
@freezed
class SelectedItem with _$SelectedItem {
  /// Creates a new [SelectedItem] instance.
  const factory SelectedItem({
    /// Unique identifier for this selection (UUID).
    required String id,

    /// Type discriminator (file, folder, text, or media).
    required SelectedItemType type,

    /// File/folder path (null for text).
    String? path,

    /// Text content (null for file/folder/media).
    String? content,

    /// Human-readable name for display.
    required String displayName,

    /// Size in bytes (estimate for folders).
    required int sizeEstimate,
  }) = _SelectedItem;

  const SelectedItem._();

  /// Creates a [SelectedItem] from JSON.
  factory SelectedItem.fromJson(Map<String, dynamic> json) =>
      _$SelectedItemFromJson(json);

  /// Validates that the item has required fields based on type.
  bool get isValid {
    switch (type) {
      case SelectedItemType.file:
      case SelectedItemType.folder:
      case SelectedItemType.media:
        return path != null && path!.isNotEmpty;
      case SelectedItemType.text:
        return content != null && content!.isNotEmpty;
    }
  }
}
