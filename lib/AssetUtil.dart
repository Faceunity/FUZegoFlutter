class AssetUtil {
  static String getImgPath(String name, {String format: 'png'}) {
    return 'assets/images/$name.$format';
  }
}