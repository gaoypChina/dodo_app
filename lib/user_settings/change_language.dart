import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/rendering.dart';

import 'package:csocsort_szamla/app_theme.dart';
import 'package:flutter/widgets.dart';

class LanguagePicker extends StatefulWidget {
  @override
  _LanguagePickerState createState() => _LanguagePickerState();
}

class _LanguagePickerState extends State<LanguagePicker> {
  List<Widget> _getLocales() {
    return context.supportedLocales.map((locale) {
      return LanguageElement(
        localeName: locale.languageCode,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
                child: Text(
              'change_language'.tr(),
              style: Theme.of(context).textTheme.headline6,
            )),
            SizedBox(height: 10),
            Center(
              child: Wrap(
                spacing: 5,
                children: _getLocales(),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class LanguageElement extends StatefulWidget {
  final String localeName;

  const LanguageElement({this.localeName});

  @override
  _LanguageElementState createState() => _LanguageElementState();
}

class _LanguageElementState extends State<LanguageElement> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        context.locale = Locale(widget.localeName);
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: (widget.localeName == context.locale.languageCode)
              ? AppTheme.gradientFromTheme(Theme.of(context))
              : LinearGradient(colors: [Colors.white, Colors.white]),
          borderRadius: BorderRadius.circular(15)
        ),
        child: Center(
          child: Text(
            widget.localeName.toUpperCase(),
            style: Theme.of(context).textTheme.bodyText2.copyWith(
              color: (widget.localeName == context.locale.languageCode)
                  ? Theme.of(context).textTheme.button.color
                  : Colors.black,
            )
          )
        ),
      ),
    );
  }
}
