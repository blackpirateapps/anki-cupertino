enum TimerMode { focus, shortBreak, longBreak }

extension TimerModeX on TimerMode {
  String get label {
    switch (this) {
      case TimerMode.focus:
        return 'Focus';
      case TimerMode.shortBreak:
        return 'Short';
      case TimerMode.longBreak:
        return 'Long';
    }
  }

  String get storageValue {
    switch (this) {
      case TimerMode.focus:
        return 'focus';
      case TimerMode.shortBreak:
        return 'shortBreak';
      case TimerMode.longBreak:
        return 'longBreak';
    }
  }

  static TimerMode fromStorageValue(String value) {
    switch (value) {
      case 'shortBreak':
        return TimerMode.shortBreak;
      case 'longBreak':
        return TimerMode.longBreak;
      case 'focus':
      default:
        return TimerMode.focus;
    }
  }
}

