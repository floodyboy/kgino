class Utils {
  static Duration parseDuration(String time) {
    int hours = 0;
    int minutes = 0;
    int seconds = 0;
    final parts = time.split(':');
    if (parts.length > 2) {
      hours = int.parse(parts[parts.length - 3]);
    }
    if (parts.length > 1) {
      minutes = int.parse(parts[parts.length - 2]);
    }
    seconds = int.parse(parts[parts.length - 1]);
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  static String formatDuration(Duration duration) {
    var seconds = duration.inSeconds;
    final days = seconds ~/ Duration.secondsPerDay;
    seconds -= days * Duration.secondsPerDay;
    final hours = seconds~/Duration.secondsPerHour;
    seconds -= hours * Duration.secondsPerHour;
    final minutes = seconds ~/ Duration.secondsPerMinute;
    seconds -= minutes * Duration.secondsPerMinute;

    final List<String> tokens = [];

    if (days != 0) {
      tokens.add('$days д');
    }

    if (tokens.isNotEmpty || hours != 0){
      tokens.add('$hours ч');
    }

    if (tokens.isNotEmpty || minutes != 0) {
      tokens.add('$minutes м');
    }

    if (hours == 0) {
      tokens.add('$seconds с');
    }

    return tokens.join(' ');
  }
}