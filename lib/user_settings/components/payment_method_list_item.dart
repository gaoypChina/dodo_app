import 'package:csocsort_szamla/essentials/models.dart';
import 'package:csocsort_szamla/essentials/validation_rules.dart';
import 'package:csocsort_szamla/user_settings/components/payment_method_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PaymentMethodListItem extends StatefulWidget {
  final PaymentMethod? paymentMethod;
  const PaymentMethodListItem({super.key, this.paymentMethod});

  @override
  State<PaymentMethodListItem> createState() => _PaymentMethodListItemState();
}

class _PaymentMethodListItemState extends State<PaymentMethodListItem> {
  late TextEditingController nameController;
  late TextEditingController valueController;
  bool _priority = false;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late PaymentMethodProvider provider;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.paymentMethod?.name);
    valueController = TextEditingController(text: widget.paymentMethod?.value);
    provider = context.read<PaymentMethodProvider>();
  }

  @override
  Widget build(BuildContext context) {
    bool priority = widget.paymentMethod?.priority ?? _priority;
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme:
            Theme.of(context).inputDecorationTheme.copyWith(
                  isDense: true,
                ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              if (widget.paymentMethod != null) {
                provider.setPriority(widget.paymentMethod!, !priority);
              } else {
                setState(() {
                  _priority = !_priority;
                });
              }
            },
            icon: AnimatedCrossFade(
              duration: Duration(milliseconds: 100),
              crossFadeState: priority
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Icon(Icons.star),
              secondChild: Icon(Icons.star_border),
            ),
          ),
          SizedBox(width: 10),
          Flexible(
            flex: 2,
            child: TextFormField(
              validator: widget.paymentMethod != null ? (value) => validateTextField([isEmpty(value)]) : null,
              decoration: InputDecoration(
                hintText: 'payment-method.name.hint'.tr(),
              ),
              controller: nameController,
              onChanged: (value) {
                if (widget.paymentMethod != null) {
                  provider.setName(widget.paymentMethod!, value);
                }
              },
            ),
          ),
          SizedBox(width: 20),
          Flexible(
            flex: 3,
            child: TextFormField(
              validator: widget.paymentMethod != null ? (value) => validateTextField([isEmpty(value)]) : null,
              decoration: InputDecoration(
                hintText: 'payment-method.value.hint'.tr(),
              ),
              controller: valueController,
              onChanged: (value) {
                if (widget.paymentMethod != null) {
                  provider.setValue(widget.paymentMethod!, value);
                }
              },
            ),
          ),
          SizedBox(width: 10),
          IconButton(
            icon: Icon(
                widget.paymentMethod == null ? Icons.add : Icons.delete),
            onPressed: () {
              if (widget.paymentMethod == null) {
                provider.addPaymentMethod(
                    nameController.text, valueController.text, priority);
                nameController.clear();
                valueController.clear();
                setState(() {
                  _priority = false;
                });
              } else {
                provider.removePaymentMethod(widget.paymentMethod!);
              }
            },
          )
        ],
      ),
    );
  }
}