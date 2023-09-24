import 'dart:math';

import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/app_theme.dart';
import 'package:csocsort_szamla/essentials/event_bus.dart';
import 'package:csocsort_szamla/essentials/http.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/navigator_service.dart';
import 'package:csocsort_szamla/essentials/providers/app_state_provider.dart';
import 'package:csocsort_szamla/essentials/providers/screen_width_provider.dart';
import 'package:csocsort_szamla/main.dart';
import 'package:csocsort_szamla/main/dialogs/iapp_not_supported_dialog.dart';
import 'package:csocsort_szamla/main/dialogs/personalised_ads_dialog.dart';
import 'package:csocsort_szamla/main/in_app_purchase_page.dart';
import 'package:csocsort_szamla/main/main_dialogs/like_app.dart';
import 'package:csocsort_szamla/main/main_dialogs/main_dialog.dart';
import 'package:csocsort_szamla/main/main_dialogs/payment_method.dart';
import 'package:csocsort_szamla/main/main_dialogs/pin_verification.dart';
import 'package:csocsort_szamla/main/main_dialogs/themes.dart';
import 'package:csocsort_szamla/main/main_dialogs/trial_ended_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainDialogBuilder extends StatefulWidget {
  late final List<MainDialog> dialogs;
  late final MainDialog? chosenDialog;
  final BuildContext context;

  MainDialogBuilder({required this.context, super.key}) {
    dialogs = [
      TrialEndedDialog(
        canShow: (context) => context.read<AppStateProvider>().user!.userStatus.trialStatus == TrialStatus.expired,
        type: DialogType.modal,
        showTime: DialogShowTime.both,
        onDismiss: (context, {payload}) async {
          Http.put(
            uri: '/user',
            body: {
              'trial_status': "seen",
            },
          );
          AppStateProvider provider = context.read<AppStateProvider>();
          provider.setUserStatus(provider.user!.userStatus.copyWith(
            trialStatus: TrialStatus.seen,
          ));
          EventBus.instance.fire(EventBus.hideMainDialog);
          ThemeName currentTheme = provider.themeName;
          if (currentTheme.type == ThemeType.dualColor ||
              currentTheme.type == ThemeType.gradient ||
              currentTheme.type == ThemeType.dynamic) {
            provider.setThemeName(
              currentTheme.brightness == Brightness.light ? ThemeName.greenLight : ThemeName.greenDark,
            );
          }
          if (payload == 'shop') {
            if (isIAPPlatformEnabled) {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const InAppPurchasePage(),
              ));
            } else {
              await showDialog(
                context: context,
                builder: (context) => IAPPNotSupportedDialog(),
              );
            }
          }
          showDialog(
            context: getIt.get<NavigationService>().navigatorKey.currentContext!,
            builder: (context) => PersonalisedAdsDialog(),
          );
        },
      ),
      PinVerificationMainDialog(
        showTime: DialogShowTime.both,
        type: DialogType.bottom,
        canShow: (context) {
          UserStatus status = context.read<AppStateProvider>().user!.userStatus;
          int verificationCount = status.pinVerificationCount;
          Duration difference = DateTime.now().difference(status.pinVerifiedAt);
          if (verificationCount <= 1 && difference.inDays >= 1) {
            
            return true;
          }
          if (verificationCount == 2 && difference.inDays >= 3) {
            return true;
          }
          if (verificationCount <= 5 && difference.inDays >= 7) {
            return true;
          }
          if (difference.inDays >= 30) {
            return true;
          }
          return false;
        },
        onDismiss: (context, {payload}) {
          AppStateProvider provider = context.read<AppStateProvider>();
          UserStatus status = provider.user!.userStatus;
          provider.setUserStatus(status.copyWith(
            pinVerifiedAt: DateTime.now(), // Only show once per session
          ));
        },
      ),
      LikeTheAppMainDialog(
        canShow: (context) {
          User? user = context.read<AppStateProvider>().user;
          return user != null &&
              user.userStatus.trialStatus != TrialStatus.trial &&
              !user.ratedApp &&
              Random().nextDouble() <= 0.15;
        },
        type: DialogType.modal,
        showTime: DialogShowTime.onBuild,
        onDismiss: (context, {payload}) {
          context.read<AppStateProvider>().user!.ratedApp = true;
          EventBus.instance.fire(EventBus.hideMainDialog);
        },
      ),
      PaymentMethodMainDialog(
        canShow: (context) {
          User? user = context.read<AppStateProvider>().user;
          return user != null && user.paymentMethods.isEmpty && Random().nextDouble() <= 0.15;
        },
        type: DialogType.bottom,
        showTime: DialogShowTime.onBuild,
      ),
      ThemesMainDialog(
        canShow: (context) {
          AppStateProvider provider = context.read<AppStateProvider>();
          User? user = provider.user;
          ThemeName currentTheme = provider.themeName;
          if (user == null) return false;
          late double chance;
          if (user.userStatus.trialStatus == TrialStatus.trial) {
            chance = currentTheme.isDodo() ? 0.2 : 0.05;
          } else {
            chance = currentTheme == ThemeName.greenLight || currentTheme == ThemeName.greenDark ? 0.1 : 0.05;
          }
          return Random().nextDouble() <= chance;
        },
        type: DialogType.bottom,
        showTime: DialogShowTime.onBuild,
      ),
    ];
    chosenDialog = chooseWidget(DialogShowTime.onInit, context);
  }

  MainDialog? chooseWidget(DialogShowTime showTime, BuildContext context) {
    return dialogs
        .where((dialog) =>
            (dialog.showTime == showTime || dialog.showTime == DialogShowTime.both) && dialog.canShow(context))
        .firstOrNull;
  }

  @override
  State<MainDialogBuilder> createState() => _MainDialogBuilderState();
}

class _MainDialogBuilderState extends State<MainDialogBuilder> {
  late MainDialog? _dialog;
  late bool visible;

  void onRefreshMainDialog() {
    if (!visible) {
      setState(() {
        _dialog =
            widget.chooseWidget(DialogShowTime.onBuild, getIt.get<NavigationService>().navigatorKey.currentContext!);
        visible = _dialog != null;
      });
    }
  }

  void onHideMainDialog() {
    setState(() {
      visible = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _dialog = widget.chosenDialog;
    visible = _dialog != null;

    EventBus.instance.register(EventBus.refreshMainDialog, onRefreshMainDialog);
    EventBus.instance.register(EventBus.hideMainDialog, onHideMainDialog);
  }

  @override
  void dispose() {
    EventBus.instance.unregister(EventBus.refreshMainDialog, onRefreshMainDialog);
    EventBus.instance.unregister(EventBus.hideMainDialog, onHideMainDialog);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: Stack(
        children: [
          Positioned.fill(
            child: Visibility(
              visible: _dialog?.type == DialogType.modal,
              child: GestureDetector(
                onTap: () =>
                    _dialog!.onDismiss != null ? _dialog!.onDismiss!(context) : setState(() => visible = false),
                child: Container(
                  color: Colors.black54,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: _dialog?.type == DialogType.modal ? Alignment.center : Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: _dialog?.type == DialogType.bottom ? (context.select<ScreenWidth, bool>((provider) => provider.isMobile) ? 95 : 15) : 0),
                child: Provider.value(
                  value: () => setState(() {
                    visible = false; 
                    _dialog?.onDismiss?.call(context);
                  }),
                  builder: (context, _) {
                    return _dialog!;
                  },
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
