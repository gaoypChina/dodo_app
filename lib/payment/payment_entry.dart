import 'package:collection/collection.dart' show IterableExtension;
import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/app_theme.dart';
import 'package:csocsort_szamla/essentials/currencies.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/providers/EventBusProvider.dart';
import 'package:csocsort_szamla/essentials/widgets/add_reaction_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/past_reaction_container.dart';
import 'package:csocsort_szamla/payment/payment_all_info.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:event_bus_plus/event_bus_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PaymentEntry extends StatefulWidget {
  final bool isTappable;
  final Payment payment;
  late final int selectedMemberId;
  PaymentEntry({
    required this.payment,
    selectedMemberId,
    this.isTappable = true,
  }) {
    this.selectedMemberId = selectedMemberId ?? currentUserId;
  }

  @override
  _PaymentEntryState createState() => _PaymentEntryState();
}

class _PaymentEntryState extends State<PaymentEntry> {
  late Icon icon;
  TextStyle? mainTextStyle;
  TextStyle? subTextStyle;
  BoxDecoration? boxDecoration;
  String? date;
  late String note;
  String? takerName;
  String? amount;

  void handleSendReaction(String reaction) {
    Reaction? oldReaction = widget.payment.reactions!
        .firstWhereOrNull((element) => element.userId == currentUserId);
    bool alreadyReacted = oldReaction != null;
    bool sameReaction =
        alreadyReacted ? oldReaction.reaction == reaction : false;
    if (sameReaction) {
      widget.payment.reactions!.remove(oldReaction);
      setState(() {});
    } else if (!alreadyReacted) {
      widget.payment.reactions!.add(Reaction(
        nickname: currentUsername!,
        reaction: reaction,
        userId: currentUserId!,
      ));
      setState(() {});
    } else {
      widget.payment.reactions!.add(
        Reaction(
          nickname: oldReaction.nickname,
          reaction: reaction,
          userId: currentUserId!,
        ),
      );
      widget.payment.reactions!.remove(oldReaction);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    int? selectedMemberId = widget.selectedMemberId;
    date = DateFormat('yyyy/MM/dd - HH:mm').format(widget.payment.updatedAt);
    note = (widget.payment.note == '')
        ? 'no_note'.tr()
        : widget.payment.note[0].toUpperCase() +
            widget.payment.note.substring(1);
    if (widget.payment.payerId == selectedMemberId) {
      takerName = widget.payment.takerNickname;
      amount = widget.payment.amountOriginalCurrency
          .toMoneyString(widget.payment.originalCurrency, withSymbol: true);
      icon = Icon(Icons.call_made,
          color: currentThemeName.contains('Gradient')
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onPrimaryContainer);
      boxDecoration = BoxDecoration(
        gradient: AppTheme.gradientFromTheme(currentThemeName,
            usePrimaryContainer: true),
        borderRadius: BorderRadius.circular(15),
      );
      mainTextStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(
          color: currentThemeName.contains('Gradient')
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onPrimaryContainer);
      subTextStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
          color: currentThemeName.contains('Gradient')
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onPrimaryContainer);
    } else {
      icon = Icon(Icons.call_received,
          color: Theme.of(context).colorScheme.onSurfaceVariant);

      mainTextStyle = Theme.of(context)
          .textTheme
          .bodyLarge!
          .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
      subTextStyle = Theme.of(context)
          .textTheme
          .bodySmall!
          .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
      takerName = widget.payment.payerNickname;
      amount = (-widget.payment.amountOriginalCurrency)
          .toMoneyString(widget.payment.originalCurrency, withSymbol: true);
      boxDecoration = BoxDecoration();
    }
    return Stack(
      children: [
        Container(
          height: 80,
          width: MediaQuery.of(context).size.width,
          decoration: boxDecoration,
          margin: EdgeInsets.only(
              top: widget.payment.reactions!.length == 0 ? 0 : 14,
              bottom: 4,
              left: 4,
              right: 4),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onLongPress: !widget.isTappable
                  ? null
                  : selectedMemberId != currentUserId
                      ? null
                      : () {
                          showDialog(
                              builder: (context) => AddReactionDialog(
                                    type: 'payments',
                                    reactions: widget.payment.reactions!,
                                    reactToId: widget.payment.id,
                                    onSend: this.handleSendReaction,
                                  ),
                              context: context);
                        },
              onTap: !widget.isTappable
                  ? null
                  : () async {
                      showModalBottomSheet<String>(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => SingleChildScrollView(
                                  child: PaymentAllInfo(widget.payment)))
                          .then((returnValue) {
                        if (returnValue == 'deleted') {
                          final bus = context.read<EventBus>();
                          bus.fire(RefreshPayments());
                          bus.fire(RefreshBalances());
                        }
                      });
                    },
              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      child: Row(
                        children: <Widget>[
                          icon,
                          SizedBox(
                            width: 20,
                          ),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  takerName!,
                                  style: mainTextStyle,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  note,
                                  style: subTextStyle,
                                  overflow: TextOverflow.ellipsis,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      amount!,
                      style: mainTextStyle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Visibility(
          visible: selectedMemberId == currentUserId,
          child: PastReactionContainer(
            reactedToId: widget.payment.id,
            reactions: widget.payment.reactions!,
            onSendReaction: this.handleSendReaction,
            isSecondaryColor: widget.payment.payerId == currentUserId,
            type: 'payments',
          ),
        )
      ],
    );
  }
}
