/// Type discriminator for items in selection queue.
enum SelectedItemType {
  /// Single file from file system.
  file,

  /// Directory (will be compressed to ZIP).
  folder,

  /// Pasted text content.
  text,

  /// Media file (photo/video from gallery).
  media,
}
