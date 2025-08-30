// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/material.dart';

import 'package:help_page/help_page.dart';

const _manualHtml = '''
<p>Albunaut shows various statistics about the data in your ListenBrainz account.</p>
<p>Its main purpose is to show what albums you haven't listened to yet.</p>
<p>
  To display any information, the application needs to download your listens and related data from ListenBrainz.
  First, go to the settings and enter your ListenBrainz token.
  You can get it from your
  <a href="https://listenbrainz.org/profile/">ListenBrainz profile</a>.
  If you enter the token, the username will be fetched automatically.
  The application may work with just the username, without the token,
  but it's not guaranteed, and the sync process may be much slower.
  If you leave the API endpoint empty, the official ListenBrainz server will be used (https://api.listenbrainz.org). 
</p>
<p>
  The application does not sync anything automatically.
  To start the sync press the <widget name="sync"></widget> button.
  The initial sync may take a very long time depending on the number of listens you have in your ListenBrainz account.
</p>
<p>
  To set up a filter, open the filter settings by pressing the <widget name="filter_open"></widget> button.
  You can save the filter in the save menu, which you can open by pressing the <widget name="filter_menu"></widget> button.
  Unsaved filters do not persist after the application is closed.
  The search string is not a part of the filter.
</p>
<p>
  You can swipe left and right on the list of albums to ignore or un-ignore them,
  or on the list or artists to whitelist or blacklist them.
  You can also blacklist certain album/release types (such as remixes or compilations) on the settings page.
  Note that the list of the album types can change after you download new listens from ListenBrainz.
</p>
<p>
  Albunaut stores almost everything in an SQLite database.
  You can access it directly via Database page.
  This is a low-level access and it's mostly for developers.
  Always do a backup before doing anything.
  You can do the backup via the menu on Database page.
</p>
''';

void showHelpPage(BuildContext context) {
  Navigator.push<void>(
    context,
    MaterialPageRoute(builder: (context) => HelpPage(
      appTitle: 'Albunaut',
      githubAuthor: 'alkatrazstudio',
      githubProject: 'albunaut',
      manualHtml: _manualHtml,
      license: HelpPageLicense.agpl3,
      showGitHubReleasesLink: true,
      changelogFilename: 'CHANGELOG.md',
      manualHtmlWidgets: const {
        'sync': Icon(Icons.refresh),
        'filter_open': Icon(Icons.arrow_drop_down),
        'filter_menu': Icon(Icons.menu),
      },
      libraries: [
        HelpPagePackage.flutter('collection', HelpPageLicense.bsd3),
        HelpPagePackage.flutter('drift', HelpPageLicense.mit),
        HelpPagePackage.flutter('flutter_riverpod', HelpPageLicense.mit),
        HelpPagePackage.flutter('intl', HelpPageLicense.bsd3),
        HelpPagePackage.flutter('path', HelpPageLicense.bsd3),
        HelpPagePackage.flutter('path_provider', HelpPageLicense.bsd3),
        HelpPagePackage.flutter('sqlite3', HelpPageLicense.mit),
        HelpPagePackage.flutter('sqlite3_flutter_libs', HelpPageLicense.mit),
        HelpPagePackage.flutter('url_launcher', HelpPageLicense.bsd3),
        HelpPagePackage.flutter('file_picker', HelpPageLicense.mit),
        HelpPagePackage.flutter('shared_preferences', HelpPageLicense.bsd3),
        HelpPagePackage.foss(name: 'pad5', url: 'https://github.com/z80maniac/pad5', license: HelpPageLicense.gpl3),
        HelpPagePackage.foss(name: 'mega_form', url: 'https://github.com/z80maniac/mega_form', license: HelpPageLicense.gpl3),
        HelpPagePackage.foss(name: 'typed_prefs', url: 'https://github.com/z80maniac/typed_prefs', license: HelpPageLicense.gpl3),
      ],
      assets: const []
    ))
  );
}
