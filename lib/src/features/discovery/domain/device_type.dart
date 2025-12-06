/// Category of device based on form factor.
enum DeviceType {
  /// Mobile phone (iOS/Android).
  phone,

  /// Tablet device (iPad/Android tablet).
  tablet,

  /// Desktop computer (iMac, Windows PC).
  desktop,

  /// Laptop computer (MacBook, notebook).
  laptop,

  /// Unrecognized device type.
  unknown;

  /// Parses a string to DeviceType.
  ///
  /// Returns [DeviceType.unknown] if the string doesn't match any known type.
  static DeviceType fromString(String value) {
    return DeviceType.values.firstWhere(
      (type) => type.name == value.toLowerCase(),
      orElse: () => DeviceType.unknown,
    );
  }
}
