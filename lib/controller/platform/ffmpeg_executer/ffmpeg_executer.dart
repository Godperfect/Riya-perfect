import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:ffmpeg_kit_flutter_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_min/ffprobe_kit.dart';
import 'package:path/path.dart' as p;

import 'package:namida/controller/platform/base.dart';

part 'ffmpeg_executer_android.dart';
part 'ffmpeg_executer_base.dart';
part 'ffmpeg_executer_windows.dart';
