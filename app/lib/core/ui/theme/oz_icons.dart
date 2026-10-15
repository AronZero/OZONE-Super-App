import 'package:flutter/widgets.dart';

/// Every icon OZONE uses, from Material Symbols Rounded (Google, Apache-2.0),
/// bundled as one variable font in assets/fonts/MaterialSymbolsRounded.
///
/// Icons are outline by default (the theme sets fill 0). Pass `fill: 1` to
/// [Icon] only for an active or selected state (bar item, pinned, starred,
/// checked); [OzIcon] animates between the two. Release builds keep only the
/// glyphs listed here (icon tree shaking), so add new icons to this file.
abstract final class OzIcons {
  static const accountBalanceWallet = IconData(0xe850, fontFamily: _family);
  static const add = IconData(0xe145, fontFamily: _family);
  static const arrowBack = IconData(0xe5c4, fontFamily: _family);
  static const arrowUpward = IconData(0xe5d8, fontFamily: _family);
  static const barChart = IconData(0xe26b, fontFamily: _family);
  static const calendarToday = IconData(0xe935, fontFamily: _family);
  static const check = IconData(0xe668, fontFamily: _family);
  static const checkBox = IconData(0xe9de, fontFamily: _family);
  static const checkCircle = IconData(0xf0be, fontFamily: _family);
  static const chevronLeft = IconData(0xe5cb, fontFamily: _family);
  static const chevronRight = IconData(0xe5cc, fontFamily: _family);
  static const close = IconData(0xe5cd, fontFamily: _family);
  static const contrast = IconData(0xeb37, fontFamily: _family);
  static const dashboardCustomize = IconData(0xe99b, fontFamily: _family);
  static const delete = IconData(0xe92e, fontFamily: _family);
  static const description = IconData(0xe873, fontFamily: _family);
  static const diamond = IconData(0xead5, fontFamily: _family);
  static const download = IconData(0xf090, fontFamily: _family);
  static const dragIndicator = IconData(0xe945, fontFamily: _family);
  static const edit = IconData(0xf097, fontFamily: _family);
  static const editNote = IconData(0xe745, fontFamily: _family);
  static const error = IconData(0xf8b6, fontFamily: _family);
  static const fingerprint = IconData(0xe90d, fontFamily: _family);
  static const folder = IconData(0xe2c7, fontFamily: _family);
  static const formatColorReset = IconData(0xe23b, fontFamily: _family);
  static const formatListBulleted = IconData(0xe241, fontFamily: _family);
  static const gridView = IconData(0xe9b0, fontFamily: _family);
  static const history = IconData(0xe8b3, fontFamily: _family);
  static const home = IconData(0xe9b2, fontFamily: _family);
  static const info = IconData(0xe88e, fontFamily: _family);
  static const iosShare = IconData(0xe6b8, fontFamily: _family);
  static const key = IconData(0xe73c, fontFamily: _family);
  static const list = IconData(0xe896, fontFamily: _family);
  static const lock = IconData(0xe899, fontFamily: _family);
  static const lockOpen = IconData(0xe898, fontFamily: _family);
  static const menuBook = IconData(0xea19, fontFamily: _family);
  static const moreVert = IconData(0xe5d4, fontFamily: _family);
  static const notifications = IconData(0xe7f5, fontFamily: _family);
  static const pushPin = IconData(0xf10d, fontFamily: _family);
  static const radioButtonChecked = IconData(0xe837, fontFamily: _family);
  static const radioButtonUnchecked = IconData(0xe836, fontFamily: _family);
  static const receiptLong = IconData(0xef6e, fontFamily: _family);
  static const remove = IconData(0xe15b, fontFamily: _family);
  static const search = IconData(0xef7a, fontFamily: _family);
  static const settings = IconData(0xe8b8, fontFamily: _family);
  static const shield = IconData(0xe9e0, fontFamily: _family);
  static const spaceBar = IconData(0xe256, fontFamily: _family);
  static const star = IconData(0xf09a, fontFamily: _family);
  static const starHalf = IconData(0xe839, fontFamily: _family);
  static const tableChart = IconData(0xe265, fontFamily: _family);
  static const tableRows = IconData(0xf101, fontFamily: _family);
  static const tag = IconData(0xe9ef, fontFamily: _family);
  static const undo = IconData(0xe166, fontFamily: _family);
  static const viewAgenda = IconData(0xe8e9, fontFamily: _family);
  static const visibility = IconData(0xe8f4, fontFamily: _family);
  static const visibilityOff = IconData(0xe8f5, fontFamily: _family);
  static const warning = IconData(0xf083, fontFamily: _family);

  static const _family = 'MaterialSymbolsRounded';
}
