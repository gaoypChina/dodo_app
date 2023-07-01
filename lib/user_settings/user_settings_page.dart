import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/ad_management.dart';
import 'package:csocsort_szamla/essentials/providers/user_provider.dart';
import 'package:csocsort_szamla/user_settings/change_password.dart';
import 'package:csocsort_szamla/user_settings/change_user_currency.dart';
import 'package:csocsort_szamla/user_settings/delete_all_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'about_us.dart';
import 'change_language.dart';
import 'change_username.dart';
import 'color_picker.dart';
import 'personalised_ads.dart';
import 'report_bug.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        56 - //appbar
        adHeight(context); //Height without status bar and appbar
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'settings'.tr(),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Column(
          children: [
            width < tabletViewWidth
                ? Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: _settings(),
                      ),
                    ),
                  )
                : Expanded(
                    child: Table(
                      columnWidths: {
                        0: FractionColumnWidth(0.5),
                        1: FractionColumnWidth(0.5)
                      },
                      children: [
                        TableRow(children: [
                          AspectRatio(
                            aspectRatio: width / 2 / height,
                            child: ListView(
                              controller: ScrollController(),
                              children: _settings().take(3).toList(),
                            ),
                          ),
                          AspectRatio(
                            aspectRatio: width / 2 / height,
                            child: ListView(
                              controller: ScrollController(),
                              children: _settings()
                                  .reversed
                                  .take(6)
                                  .toList()
                                  .reversed
                                  .toList(),
                            ),
                          )
                        ])
                      ],
                    ),
                  ),
            AdUnitForSite(site: 'settings'),
          ],
        ),
      ),
    );
  }

  List<Widget> _settings() {
    return [
      ColorPicker(),
      LanguagePicker(),
      ChangePassword(),
      ChangeUsername(),
      ChangeUserCurrency(),
      Visibility(visible: context.watch<UserProvider>().user!.showAds, child: PersonalisedAds()),
      AboutUs(),
      DeleteAllData(),
      ReportBug(),
    ];
  }
}
