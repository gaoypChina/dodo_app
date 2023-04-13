import 'package:collection/collection.dart' show IterableExtension;
import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/widgets/add_reaction_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/past_reaction_container.dart';
import 'package:csocsort_szamla/purchase/add_purchase_page.dart';
import 'package:csocsort_szamla/shopping/shopping_all_info.dart';
import 'package:flutter/material.dart';

import '../purchase/add_modify_purchase.dart';
import 'edit_request_dialog.dart';

class ShoppingListEntry extends StatefulWidget {
  final ShoppingRequest shoppingRequest;
  final Function(int) onDeleteRequest;
  final Function(ShoppingRequest) onEditRequest;

  const ShoppingListEntry({
    required this.shoppingRequest,
    required this.onDeleteRequest,
    required this.onEditRequest,
  });

  @override
  _ShoppingListEntryState createState() => _ShoppingListEntryState();
}

class _ShoppingListEntryState extends State<ShoppingListEntry> {
  late Icon icon;
  late TextStyle mainTextStyle;
  late TextStyle subTextStyle;
  late BoxDecoration boxDecoration;

  String? name;
  String? user;

  void handleSendReaction(String reaction) {
    Reaction? oldReaction = widget.shoppingRequest.reactions!
        .firstWhereOrNull((element) => element.userId == currentUserId);
    bool alreadyReacted = oldReaction != null;
    bool sameReaction =
        alreadyReacted ? oldReaction.reaction == reaction : false;
    if (sameReaction) {
      widget.shoppingRequest.reactions!.remove(oldReaction);
      setState(() {});
    } else if (!alreadyReacted) {
      widget.shoppingRequest.reactions!.add(Reaction(
        nickname: currentUsername!,
        reaction: reaction,
        userId: currentUserId!,
      ));
      setState(() {});
    } else {
      widget.shoppingRequest.reactions!.add(Reaction(
        nickname: oldReaction.nickname,
        reaction: reaction,
        userId: currentUserId!,
      ));
      widget.shoppingRequest.reactions!.remove(oldReaction);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    name = widget.shoppingRequest.name;
    user = widget.shoppingRequest.requesterUsername;
    mainTextStyle = Theme.of(context)
        .textTheme
        .bodyLarge!
        .copyWith(color: Theme.of(context).colorScheme.onSurface);
    subTextStyle = Theme.of(context)
        .textTheme
        .bodySmall!
        .copyWith(color: Theme.of(context).colorScheme.onSurface);
    boxDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(20),
    );
    if (widget.shoppingRequest.requesterId == currentUserId) {
      icon = Icon(
        Icons.shopping_cart_outlined,
        color: Theme.of(context).colorScheme.primary,
      );
    } else {
      icon = Icon(Icons.card_giftcard,
          color: Theme.of(context).colorScheme.secondary);
    }
    return Dismissible(
      key: UniqueKey(),
      secondaryBackground: Container(
        child: Align(
            alignment: Alignment.centerRight,
            child: Icon(
              widget.shoppingRequest.requesterId != currentUserId
                  ? Icons.done
                  : Icons.delete,
              size: 30,
              color: Theme.of(context).textTheme.bodyLarge!.color,
            )),
      ),
      dismissThresholds: {
        DismissDirection.startToEnd: 0.6,
        DismissDirection.endToStart: 0.6
      },
      background: Align(
          alignment: Alignment.centerLeft,
          child: Icon(
            widget.shoppingRequest.requesterId != currentUserId
                ? Icons.attach_money
                : Icons.edit,
            size: 30,
            color: Theme.of(context).textTheme.bodyLarge!.color,
          )),
      onDismissed: (direction) {
        // If requester is not the current user, the request has to be deleted either way
        if (widget.shoppingRequest.requesterId != currentUserId) {
          showDialog(
                  builder: (context) => FutureSuccessDialog(
                        future: _deleteFulfillShoppingRequest(
                            widget.shoppingRequest.id, context),
                      ),
                  barrierDismissible: false,
                  context: context)
              .then((value) {
            widget.onDeleteRequest(widget.shoppingRequest.id);
            // But if the direction is startToEnd, the AddPurchase site has to be called
            if (direction == DismissDirection.startToEnd && value == true) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPurchasePage(
                    type: PurchaseType.fromShopping,
                    shoppingData: widget.shoppingRequest,
                  ),
                ),
              );
            }
          });
        } else {
          // If the requester is the current user, then on one swipe the request is deleted, on the other it is edited
          if (direction == DismissDirection.endToStart) {
            showDialog(
                    builder: (context) => FutureSuccessDialog(
                          future: _deleteFulfillShoppingRequest(
                              widget.shoppingRequest.id, context),
                        ),
                    barrierDismissible: false,
                    context: context)
                .then((value) {
              if (value ?? false)
                widget.onDeleteRequest(widget.shoppingRequest.id);
            });
          } else if (direction == DismissDirection.startToEnd) {
            showDialog<ShoppingRequest>(
              builder: (context) => EditRequestDialog(
                textBefore: widget.shoppingRequest.name,
                requestId: widget.shoppingRequest.id,
              ),
              context: context,
            ).then((value) {
              print(value);
              if (value != null) {
                widget.onEditRequest(value);
              }
            });
          }
        }
      },
      child: Stack(
        children: [
          Container(
            height: 75,
            width: MediaQuery.of(context).size.width,
            decoration: boxDecoration,
            margin: EdgeInsets.only(
                top: widget.shoppingRequest.reactions!.length == 0 ? 5 : 10,
                bottom: 8,
                left: 5,
                right: 5),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onLongPress: () {
                  showDialog(
                      builder: (context) => AddReactionDialog(
                            type: 'requests',
                            reactions: widget.shoppingRequest.reactions!,
                            reactToId: widget.shoppingRequest.id,
                            onSend: this.handleSendReaction,
                          ),
                      context: context);
                },
                onTap: () async {
                  showModalBottomSheet<Map<String, dynamic>>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => SingleChildScrollView(
                        child: ShoppingAllInfo(widget.shoppingRequest)),
                  ).then((value) {
                    if (value != null) {
                      if (value['type'] == 'deleted') {
                        widget.onDeleteRequest(widget.shoppingRequest.id);
                      } else {
                        widget.onEditRequest(value['request']);
                      }
                    }
                  });
                },
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Flex(
                    direction: Axis.horizontal,
                    children: <Widget>[
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Flexible(
                              child: Row(
                                children: <Widget>[
                                  SizedBox(
                                    width: 10,
                                  ),
                                  icon,
                                  SizedBox(
                                    width: 20,
                                  ),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Flexible(
                                          child: Text(
                                            name!,
                                            style: mainTextStyle,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            widget.shoppingRequest
                                                .requesterNickname,
                                            style: subTextStyle,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          PastReactionContainer(
            reactions: widget.shoppingRequest.reactions!,
            reactedToId: widget.shoppingRequest.id,
            isSecondaryColor:
                widget.shoppingRequest.requesterId == currentUserId,
            type: 'requests',
            onSendReaction: this.handleSendReaction,
          ),
        ],
      ),
    );
  }

  Future<bool> _deleteFulfillShoppingRequest(int? id, var buildContext) async {
    try {
      await httpDelete(uri: '/requests/' + id.toString(), context: context);
      Future.delayed(delayTime())
          .then((value) => _onDeleteFulfillShoppingRequest());
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onDeleteFulfillShoppingRequest() {
    Navigator.pop(context, true);
  }
}
