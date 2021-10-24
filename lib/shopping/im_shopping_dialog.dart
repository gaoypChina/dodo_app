import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/essentials/http_handler.dart';
import 'package:csocsort_szamla/essentials/widgets/future_success_dialog.dart';
import 'package:csocsort_szamla/essentials/widgets/gradient_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ImShoppingDialog extends StatefulWidget {
  @override
  _ImShoppingDialogState createState() => _ImShoppingDialogState();
}

class _ImShoppingDialogState extends State<ImShoppingDialog> {
  TextEditingController _controller = TextEditingController();

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<bool> _postImShopping(String store) async {
    try {
      bool useGuest = guestNickname != null && guestGroupId == currentGroupId;
      Map<String, dynamic> body = {'store': store};
      await httpPost(
          context: context,
          body: body,
          uri: '/groups/' +
              currentGroupId.toString() +
              '/send_shopping_notification',
          useGuest: useGuest);
      Future.delayed(delayTime()).then((value) => _onPostImShopping());
      return true;
    } catch (_) {
      throw _;
    }
  }

  void _onPostImShopping() {
    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'where'.tr(),
                style: Theme.of(context).textTheme.headline6,
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                'im_shopping_explanation'.tr(),
                style: Theme.of(context).textTheme.subtitle2,
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextFormField(
                  validator: (value) {
                    value = value.trim();
                    if (value.isEmpty) {
                      return 'field_empty'.tr();
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'store'.tr(),
                    fillColor: Theme.of(context).colorScheme.onSurface,
                    filled: true,
                    prefixIcon: Icon(
                      Icons.shopping_basket,
                      color: Theme.of(context).textTheme.bodyText1.color,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  controller: _controller,
                  style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).textTheme.bodyText1.color),
                  cursorColor: Theme.of(context).colorScheme.secondary,
                  inputFormatters: [LengthLimitingTextInputFormatter(20)],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GradientButton(
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        String store = _controller.text;
                        showDialog(
                            builder: (context) => FutureSuccessDialog(
                                  future: _postImShopping(store),
                                  dataTrueText: 'store_scf',
                                  onDataTrue: () {
                                    _onPostImShopping();
                                  },
                                ),
                            context: context,
                            barrierDismissible: false);
                      }
                    },
                    child: Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
