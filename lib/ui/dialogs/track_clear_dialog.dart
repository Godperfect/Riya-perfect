import 'package:flutter/material.dart';

import 'package:namida/class/track.dart';
import 'package:namida/controller/edit_delete_controller.dart';
import 'package:namida/controller/navigator_controller.dart';
import 'package:namida/core/icon_fonts/broken_icons.dart';
import 'package:namida/core/translations/strings.dart';
import 'package:namida/ui/widgets/custom_widgets.dart';

void showTrackClearDialog(List<Track> tracks) {
  final isSingle = tracks.length == 1;
  NamidaNavigator.inst.navigateDialog(
    CustomBlurryDialog(
      normalTitleStyle: true,
      icon: Broken.trash,
      title: isSingle ? Language.inst.CLEAR_TRACK_ITEM : Language.inst.CLEAR_TRACK_ITEM_MULTIPLE.replaceFirst('_NUMBER_', tracks.length.toString()),
      child: Column(
        children: [
          if (tracks.hasVideoCached)
            CustomListTile(
              title: isSingle ? Language.inst.VIDEO_CACHE_FILE : Language.inst.VIDEO_CACHE_FILES,
              icon: Broken.video,
              onTap: () async {
                await EditDeleteController.inst.deleteCachedVideos(tracks);
                NamidaNavigator.inst.closeDialog();
              },
            ),
          if (tracks.hasWaveformCached)
            CustomListTile(
              title: isSingle ? Language.inst.WAVEFORM_DATA : Language.inst.WAVEFORMS_DATA,
              icon: Broken.sound,
              onTap: () async {
                await EditDeleteController.inst.deleteWaveFormData(tracks);
                NamidaNavigator.inst.closeDialog();
              },
            ),
          if (tracks.hasLyricsCached)
            CustomListTile(
              title: Language.inst.LYRICS,
              icon: Broken.document,
              onTap: () async {
                await EditDeleteController.inst.deleteLyrics(tracks);
                NamidaNavigator.inst.closeDialog();
              },
            ),
          if (tracks.hasArtworkCached)
            CustomListTile(
              title: isSingle ? Language.inst.ARTWORK : Language.inst.ARTWORKS,
              icon: Broken.image,
              onTap: () async {
                await EditDeleteController.inst.deleteArtwork(tracks);
                NamidaNavigator.inst.closeDialog();
              },
            ),
        ],
      ),
    ),
  );
}