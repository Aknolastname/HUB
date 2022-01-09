import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class Contacts extends StatefulWidget {
  const Contacts({Key? key, required this.number}) : super(key: key);

  final String number;

  @override
  _ContactsState createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  late Contact me;
  Firestore firestore = Firestore.instance;
  bool isLoading = true;
  List<Contact> _contacts = [];
  List<Contact> _users = [];
  List<Contact> _notRegistered = [];

  @override
  void initState() {
    getContacts();
    super.initState();
  }

  getFirestoreData(List<Contact> contacts, List<String> list) async {
    DateFormat format = DateFormat.yMMMMd('en_US');
    DateTime now = DateTime.now();
    DateTime dt = now.subtract(const Duration(days: 2));
    String date = format.format(now);
    String yt = format.format(dt);

    checkDayBeforeYesterdaysRecords(yt);

    List<Contact> notRegistered = contacts;
    List<Contact> attendees = [];
    int i = 0;

    while (i < list.length) {
      List<String> list1 =
          list.sublist(i, (i + 10) <= list.length ? (i + 10) : list.length);
      firestore
          .collection(date)
          .where("number", whereIn: list1)
          .getDocuments()
          .then((data) {
        data.documents.forEach((doc) {
          contacts.forEach((contact) async {
            contact.phones!.forEach((element) {
              if ((element.value == doc.data['number'] ||
                      element.value == ["+91", doc.data['number']].join() ||
                      element.value == ["91", doc.data['number']].join()) &&
                  doc.data['attendance'] == "yes") {
                attendees.add(contact);
              }
            });
          });

          notRegistered.forEach((contact) async {
            contact.phones!.forEach((element) {
              if (element.value == doc.data['number'] ||
                  element.value == ["+91", doc.data['number']].join() ||
                  element.value == ["91", doc.data['number']].join()) {
                if (contact.phones!.isNotEmpty) {
                  contact.phones!.remove(element);
                } else {
                  notRegistered.remove(contact);
                }
              }
            });
          });

          setState(() {
            _users = attendees;
            // _contacts = contacts;
            _notRegistered = notRegistered;
            // ScaffoldMessenger.of(context)
            //     .showSnackBar(SnackBar(content: Text(_users.length.toString())));
            isLoading = false;
          });
          // setState(() {
          //   _users = attendees;
          //   // _contacts = contacts;
          //   _notRegistered = notRegistered;
          //   ScaffoldMessenger.of(context)
          //       .showSnackBar(SnackBar(content: Text(doc.data['number'])));
          //   isLoading = false;
          // });
          // ScaffoldMessenger.of(context)
          //     .showSnackBar(SnackBar(content: Text(doc.data['number'])));
        });
      });
      i += 10;
    }
  }

  void checkDayBeforeYesterdaysRecords(String path) async {
    await Firestore.instance.collection(path).getDocuments().then((data) => {
          data.documents.forEach((element) {
            element.reference.delete();
          })
        });
  }

  getContacts() async {
    me = (await ContactsService.getContacts(
        query: "Me", withThumbnails: true))[0];
    //Make sure we already have permissions for contacts when we get to this
    //page, so we can just retrieve it
    List<String> users = [];
    final List<Contact> contacts =
        (await ContactsService.getContacts(withThumbnails: true));
    // users = await getFirestoreData(contacts);
    contacts.forEach((contact) {
      contact.phones!.forEach((element) {
        if (element.value != null) {
          users.add(element.value!.trim());
        }
      });
    });
    await getFirestoreData(contacts, users);
    // setState(() {
    //   this.contacts = contacts;
    // });
  }

  void markattendance() async {
    DateFormat format = DateFormat.yMMMMd('en_US');
    String date = format.format(DateTime.now());
    await Firestore.instance.collection(date).document(widget.number).setData(
        {"attendance": "yes", "number": widget.number}).whenComplete(() {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Marked!")));
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            appBar: AppBar(
              title: Text(widget.number),
            ),
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                    child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          Contact contact = _users[index];
                          return attendance(contact, 33.00, () => {});
                        })),
                Expanded(
                    child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3),
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        itemCount: _notRegistered.length,
                        itemBuilder: (context, index) {
                          Contact contact = _notRegistered[index];
                          return attendance(contact, 30.00, () {
                            _textMe(contact.phones!.first.value!);
                          });
                        })),
                const Text("Invite"),
                ElevatedButton(
                    onPressed: () => markattendance(),
                    child: const Text("Mark attendance")),
              ],
            ));
  }
}

_textMe(String number) async {
  if (Platform.isAndroid) {
    String uri = 'sms:$number?body=Invite\nlink%20below:';
    await launch(uri);
  } else if (Platform.isIOS) {
    // iOS
    String uri = 'sms:$number&body=Invite\nlink%20below:';
    await launch(uri);
  }
}

Widget attendance(Contact contact, double size, Function() method) {
  return FlatButton(
      child: Column(mainAxisSize: MainAxisSize.max, children: [
        (contact.avatar != null && contact.avatar!.isNotEmpty)
            ? CircleAvatar(
                minRadius: size,
                backgroundImage: MemoryImage(contact.avatar!),
              )
            : CircleAvatar(
                minRadius: size,
                child: Text(contact.initials()),
              ),
        Text(contact.displayName!),
      ]),
      onPressed: method);
}
