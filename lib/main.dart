import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:flutter/services.dart';
import 'package:wallpaperplugin/wallpaperplugin.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List data;
  String _localfile;

  @override
  void initState() {
    super.initState();
    getimages();
  }

  Future<String> getimages() async {
    var getdata = await http.get(
        'https://api.unsplash.com/search/photos?per_page=30&client_id=LOspW8jcT27D-PLY4mFR22Hj9DIiKIkEbefVyeM3gZ8&query=nature');
    setState(() {
      var jsondata = json.decode(getdata.body);
      data = jsondata['results'];
    });
    return "Success";
  }

  static Future<bool> _checkAndGetPermission() async {
    final PermissionStatus permission = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);
    if (permission != PermissionStatus.granted) {
      final Map<PermissionGroup, PermissionStatus> permissions =
          await PermissionHandler()
              .requestPermissions(<PermissionGroup>[PermissionGroup.storage]);
      if (permissions[PermissionGroup.storage] != PermissionStatus.granted) {
        return null;
      }
    }
    return true;
  }

  _onTapImage(BuildContext context, values) {
    return AlertDialog(
      title: Text("Set as wallpaper ?"),
      actions: <Widget>[
        FlatButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("NO"),
        ),
        FlatButton(
          onPressed: () async {
            if (await _checkAndGetPermission() != null) {
              Dio dio = Dio();
              final Directory appdirectory =
                  await getExternalStorageDirectory();
              final Directory directory =
                  await Directory(appdirectory.path + '/wallpapers')
                      .create(recursive: true);
              final String dir = directory.path;
              final String localfile = '$dir/myimage.jpeg';
              try {
                await dio.download(values, localfile);
                setState(() {
                  _localfile = localfile;
                });
                Wallpaperplugin.setAutoWallpaper(localFile: _localfile);
              } on PlatformException catch (e) {
                print(e);
              }
              Navigator.pop(context);
            }
          },
          child: Text("YES"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Wallpaper app",
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      home: Scaffold(
          appBar: AppBar(title: Text("Wallpaper app")),
          body: Builder(
            builder: (context) => Swiper(
              itemBuilder: (BuildContext context, int index) {
                return Stack(
                  children: <Widget>[
                    InkWell(
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (context) => _onTapImage(
                                context, data[index]['urls']['small']));
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 50.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(35.0),
                            topRight: Radius.circular(35.0),
                            bottomLeft: Radius.circular(35.0),
                            bottomRight: Radius.circular(35.0),
                          ),
                          child: Image.network(
                            data[index]['urls']['small'],
                            fit: BoxFit.cover,
                            height: 500.0,
                          ),
                        ),
                      ),
                    )
                  ],
                );
              },
              itemCount: 10,
              autoplay: true,
              viewportFraction: 0.8,
              scale: 0.9,
            ),
          )),
    );
  }
}
